package sn.isep.Convoiturage;

import com.jayway.jsonpath.JsonPath;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.webmvc.test.autoconfigure.AutoConfigureMockMvc;
import org.springframework.context.annotation.Import;
import org.springframework.http.MediaType;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.ResultActions;
import org.springframework.test.web.servlet.request.MockHttpServletRequestBuilder;

import java.time.LocalDateTime;
import java.time.temporal.ChronoUnit;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

/**
 * Module 05 — évaluations et avis sur la base locale « covoiturage_test » : un vrai voyage (publication, démarrage,
 * embarquement par PIN, fin), puis les notes dans les deux sens, la moyenne et la réputation publique.
 */
@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
@Import({ParcoursCompletTest.BaseDeTestPropre.class, ParcoursCompletTest.CodesDeTest.class})
class AvisParcoursTest {

    static final double DAKAR_LAT = 14.6681, DAKAR_LNG = -17.4318;
    static final double THIES_LAT = 14.7910, THIES_LNG = -16.9260;

    @Autowired
    MockMvc mvc;

    @Autowired
    JdbcTemplate jdbc;

    private String dernierRefresh;

    @Test
    void notesApresUnVoyageTermine() throws Exception {
        String conducteur = conducteurValide("Ibrahima", "Sy", "ibrahima.avis@test.sn", "771117788");
        String awa = inscrire("Awa", "Ndoye", "awa.avis@test.sn", "781117788", "FEMME");
        String modou = inscrire("Modou", "Kane", "modou.avis@test.sn", "761117788", "HOMME");
        long idConducteur = idDe("ibrahima.avis@test.sn");

        // --- Trajet en réservation automatique, départ dans 45 min (démarrable dès maintenant)
        long idVehicule = ((Number) JsonPath.read(mvc.perform(get("/api/moi/vehicules").header("Authorization", "Bearer " + conducteur))
                .andReturn().getResponse().getContentAsString(), "$[0].id")).longValue();
        String depart = LocalDateTime.now().plusMinutes(45).truncatedTo(ChronoUnit.MINUTES).toString();
        long idTrajet = ((Number) JsonPath.read(appel(post("/api/trajets").header("Authorization", "Bearer " + conducteur), """
                {"idVehicule":%d,"depart":{"lieu":"Dakar","latitude":%s,"longitude":%s},
                 "arrivee":{"lieu":"Thiès","latitude":%s,"longitude":%s},"dateHeureDepart":"%s",
                 "flexibiliteMinutes":15,"nombrePlaces":3,"modeReservation":"AUTOMATIQUE","tailleBagage":"PETIT",
                 "femmesUniquement":false}""".formatted(idVehicule, DAKAR_LAT, DAKAR_LNG, THIES_LAT, THIES_LNG, depart))
                .andExpect(status().isCreated()).andReturn().getResponse().getContentAsString(), "$.id")).longValue();

        long resaAwa = reserver(awa, idTrajet);
        long resaModou = reserver(modou, idTrajet);

        // Avant la fin du voyage : impossible de noter
        noter(awa, resaAwa, 4, null).andExpect(status().isConflict());

        // --- Voyage : démarrage, Awa embarque (PIN), Modou ne vient pas, fin du trajet
        appel(post("/api/trajets/" + idTrajet + "/demarrer").header("Authorization", "Bearer " + conducteur), "")
                .andExpect(status().isOk());
        String pin = JsonPath.read(mvc.perform(get("/api/reservations/" + resaAwa + "/embarquement")
                .header("Authorization", "Bearer " + awa)).andReturn().getResponse().getContentAsString(), "$.codePin");
        appel(post("/api/trajets/" + idTrajet + "/embarquement").header("Authorization", "Bearer " + conducteur),
                "{\"code\":\"" + pin + "\"}").andExpect(status().isOk());
        appel(post("/api/trajets/" + idTrajet + "/terminer").header("Authorization", "Bearer " + conducteur), "")
                .andExpect(status().isOk());

        // --- Avis à donner : Awa note son conducteur, le conducteur note Awa ; Modou (absent) rien
        mvc.perform(get("/api/moi/avis-a-donner").header("Authorization", "Bearer " + awa))
                .andExpect(jsonPath("$.length()").value(1))
                .andExpect(jsonPath("$[0].idReservation").value(resaAwa))
                .andExpect(jsonPath("$[0].role").value("CONDUCTEUR"))
                .andExpect(jsonPath("$[0].aNoter.prenom").value("Ibrahima"));
        mvc.perform(get("/api/moi/avis-a-donner").header("Authorization", "Bearer " + conducteur))
                .andExpect(jsonPath("$.length()").value(1))
                .andExpect(jsonPath("$[0].role").value("PASSAGER"))
                .andExpect(jsonPath("$[0].aNoter.prenom").value("Awa"));
        mvc.perform(get("/api/moi/avis-a-donner").header("Authorization", "Bearer " + modou))
                .andExpect(jsonPath("$.length()").value(0));
        noter(modou, resaModou, 1, "Jamais parti").andExpect(status().isConflict());   // réservation annulée
        noter(modou, resaAwa, 1, null).andExpect(status().isNotFound());               // pas son voyage

        // --- Awa note le conducteur ; note invalide refusée ; pas deux fois
        noter(awa, resaAwa, 6, null).andExpect(status().isBadRequest());
        noter(awa, resaAwa, 4, "  Ponctuel et prudent, voiture propre.  ")
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.note").value(4))
                .andExpect(jsonPath("$.commentaire").value("Ponctuel et prudent, voiture propre."))
                .andExpect(jsonPath("$.roleEvalue").value("CONDUCTEUR"));
        noter(awa, resaAwa, 5, null).andExpect(status().isConflict());
        mvc.perform(get("/api/moi/avis-a-donner").header("Authorization", "Bearer " + awa))
                .andExpect(jsonPath("$.length()").value(0));

        // --- Délai de 14 jours dépassé : le conducteur ne peut plus noter ; puis, dans le délai, il note Awa
        jdbc.update("update trajet set date_heure_depart = date_heure_depart - interval '15 days' where id_trajet = ?", idTrajet);
        noter(conducteur, resaAwa, 5, null).andExpect(status().isConflict());
        mvc.perform(get("/api/moi/avis-a-donner").header("Authorization", "Bearer " + conducteur))
                .andExpect(jsonPath("$.length()").value(0));
        jdbc.update("update trajet set date_heure_depart = date_heure_depart + interval '15 days' where id_trajet = ?", idTrajet);
        noter(conducteur, resaAwa, 5, null).andExpect(status().isCreated())
                .andExpect(jsonPath("$.roleEvalue").value("PASSAGER"));

        // --- Réputation publique (sans connexion) et moyenne reportée sur le profil
        mvc.perform(get("/api/utilisateurs/" + idConducteur + "/avis"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.noteMoyenne").value(4.0))
                .andExpect(jsonPath("$.nombreAvis").value(1))
                .andExpect(jsonPath("$.repartition[3]").value(1))
                .andExpect(jsonPath("$.avis[0].auteur.prenom").value("Awa"))
                .andExpect(jsonPath("$.avis[0].commentaire").value("Ponctuel et prudent, voiture propre."));
        mvc.perform(get("/api/utilisateurs/" + idDe("awa.avis@test.sn") + "/avis"))
                .andExpect(jsonPath("$.noteMoyenne").value(5.0))
                .andExpect(jsonPath("$.avis[0].roleEvalue").value("PASSAGER"));
        mvc.perform(get("/api/utilisateurs/" + idConducteur)).andExpect(jsonPath("$.noteMoyenne").value(4.0));
    }

    // ------------------------------------------------------------------ utilitaires

    private long reserver(String jeton, long idTrajet) throws Exception {
        return ((Number) JsonPath.read(appel(post("/api/trajets/" + idTrajet + "/reservations").header("Authorization", "Bearer " + jeton),
                "{\"nombrePlaces\":1,\"moyenPaiement\":\"ESPECES\"}")
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.statut").value("ACCEPTEE"))
                .andReturn().getResponse().getContentAsString(), "$.id")).longValue();
    }

    private ResultActions noter(String jeton, long idReservation, int note, String commentaire) throws Exception {
        String corps = commentaire == null ? "{\"note\":" + note + "}"
                : "{\"note\":" + note + ",\"commentaire\":\"" + commentaire + "\"}";
        return appel(post("/api/reservations/" + idReservation + "/evaluation").header("Authorization", "Bearer " + jeton), corps);
    }

    private long idDe(String email) {
        return jdbc.queryForObject("select id_utilisateur from utilisateur where email = ?", Long.class, email);
    }

    private String conducteurValide(String prenom, String nom, String email, String tel) throws Exception {
        String jeton = inscrire(prenom, nom, email, tel, "HOMME");
        appel(post("/api/moi/vehicules").header("Authorization", "Bearer " + jeton), """
                {"immatriculation":"DK-%s","marque":"Toyota","modele":"Yaris","annee":2020,"puissanceFiscale":5,
                 "nombrePlaces":5,"typeEnergie":"ESSENCE","consommationReelle":6.0}""".formatted(tel.substring(5)))
                .andExpect(status().isCreated());
        // Validation des documents par l'administrateur : simulée en base.
        jdbc.update("update vehicule set statut_validation = 'VALIDE' where id_proprietaire = "
                + "(select id_utilisateur from utilisateur where email = ?)", email);
        jdbc.update("update utilisateur set conducteur_valide = true where email = ?", email);
        return jeton(appel(post("/api/auth/refresh"), "{\"refreshToken\":\"" + dernierRefresh + "\"}"));
    }

    private String inscrire(String prenom, String nom, String email, String tel, String sexe) throws Exception {
        String ancien = ParcoursCompletTest.CodesDeTest.DERNIER_CODE.get(email);
        appel(post("/api/auth/inscription"), """
                {"prenom":"%s","nom":"%s","email":"%s","telephone":"%s","motDePasse":"MotDePasse2026","sexe":"%s"}"""
                .formatted(prenom, nom, email, tel, sexe))
                .andExpect(status().isCreated());
        String code = ParcoursCompletTest.CodesDeTest.attendreNouveauCode(email, ancien);
        return jeton(appel(post("/api/auth/otp/verifier"), "{\"identifiant\":\"" + tel + "\",\"code\":\"" + code + "\"}"));
    }

    private ResultActions appel(MockHttpServletRequestBuilder req, String json) throws Exception {
        return mvc.perform(req.contentType(MediaType.APPLICATION_JSON).content(json));
    }

    private String jeton(ResultActions r) throws Exception {
        String body = r.andExpect(status().isOk()).andReturn().getResponse().getContentAsString();
        dernierRefresh = JsonPath.read(body, "$.refreshToken");
        return JsonPath.read(body, "$.accessToken");
    }
}
