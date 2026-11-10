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
 * Module 10 — signalements sur la base locale « covoiturage_test » : règles de création (trajet partagé, doublon,
 * limite quotidienne), file de modération de l'administrateur et sanctions.
 */
@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
@Import({ParcoursCompletTest.BaseDeTestPropre.class, ParcoursCompletTest.CodesDeTest.class})
class SignalementsParcoursTest {

    @Autowired
    MockMvc mvc;

    @Autowired
    JdbcTemplate jdbc;

    private String dernierRefresh;

    @Test
    void signalerPuisModerer() throws Exception {
        String conducteur = conducteurValide("Seydou", "Ba", "seydou.sig@test.sn", "771118899");
        String awa = inscrire("Awa", "Fall", "awa.sig@test.sn", "781118899", "FEMME");
        String modou = inscrire("Modou", "Diop", "modou.sig@test.sn", "761118899", "HOMME");
        String admin = "Bearer " + jeton(appel(post("/api/auth/connexion"), """
                {"identifiant":"admin@test.local","motDePasse":"Admin-Test-2026!"}"""));
        long idConducteur = idDe("seydou.sig@test.sn");
        long idAwa = idDe("awa.sig@test.sn");
        long idModou = idDe("modou.sig@test.sn");
        long idAdmin = idDe("admin@test.local");

        // --- Un trajet, réservé par Awa seulement
        long idVehicule = ((Number) JsonPath.read(mvc.perform(get("/api/moi/vehicules").header("Authorization", "Bearer " + conducteur))
                .andReturn().getResponse().getContentAsString(), "$[0].id")).longValue();
        String depart = LocalDateTime.now().plusDays(1).truncatedTo(ChronoUnit.MINUTES).toString();
        long idTrajet = ((Number) JsonPath.read(appel(post("/api/trajets").header("Authorization", "Bearer " + conducteur), """
                {"idVehicule":%d,"depart":{"lieu":"Dakar","latitude":14.6681,"longitude":-17.4318},
                 "arrivee":{"lieu":"Thiès","latitude":14.7910,"longitude":-16.9260},"dateHeureDepart":"%s",
                 "flexibiliteMinutes":15,"nombrePlaces":3,"modeReservation":"AUTOMATIQUE","tailleBagage":"PETIT",
                 "femmesUniquement":false}""".formatted(idVehicule, depart))
                .andExpect(status().isCreated()).andReturn().getResponse().getContentAsString(), "$.id")).longValue();
        appel(post("/api/trajets/" + idTrajet + "/reservations").header("Authorization", "Bearer " + awa),
                "{\"nombrePlaces\":1,\"moyenPaiement\":\"ESPECES\"}").andExpect(status().isCreated());

        // --- Règles de création
        signaler(awa, idAwa, "COMPORTEMENT", null, null).andExpect(status().isBadRequest());          // soi-même
        signaler(awa, idAdmin, "COMPORTEMENT", null, null).andExpect(status().isForbidden());         // un administrateur
        signaler(modou, idConducteur, "COMPORTEMENT", null, null).andExpect(status().isForbidden());  // aucun trajet partagé
        signaler(awa, idModou, "COMPORTEMENT", null, null).andExpect(status().isForbidden());         // aucun trajet partagé
        signaler(awa, idConducteur, "INCONNU", null, null).andExpect(status().isBadRequest());        // motif invalide
        signaler(conducteur, idAwa, "AUTRE", null, null).andExpect(status().isBadRequest())           // description obligatoire
                .andExpect(jsonPath("$.champ").value("description"));
        mvc.perform(post("/api/signalements").contentType(MediaType.APPLICATION_JSON)
                .content("{\"idUtilisateur\":" + idConducteur + ",\"motif\":\"COMPORTEMENT\"}")).andExpect(status().isUnauthorized());

        long s1 = id(signaler(awa, idConducteur, "CONDUITE_DANGEREUSE", idTrajet, "  Il a grillé un feu rouge.  ")
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.statut").value("EN_ATTENTE"))
                .andExpect(jsonPath("$.description").value("Il a grillé un feu rouge."))
                .andExpect(jsonPath("$.signale.prenom").value("Seydou"))
                .andExpect(jsonPath("$.trajet").value("Dakar → Thiès")));
        signaler(awa, idConducteur, "COMPORTEMENT", null, null).andExpect(status().isConflict());     // déjà un signalement ouvert
        long s2 = id(signaler(conducteur, idAwa, "AUTRE", null, "Elle a quitté le véhicule sans prévenir.")
                .andExpect(status().isCreated()));

        mvc.perform(get("/api/signalements/mes").header("Authorization", "Bearer " + awa))
                .andExpect(jsonPath("$.length()").value(1))
                .andExpect(jsonPath("$[0].id").value(s1));

        // --- La modération est réservée aux administrateurs
        mvc.perform(get("/api/admin/signalements").header("Authorization", "Bearer " + awa)).andExpect(status().isForbidden());
        mvc.perform(get("/api/admin/signalements").param("statut", "EN_ATTENTE").header("Authorization", admin))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.page.totalElements").value(2))
                .andExpect(jsonPath("$.content[0].id").value(s1));
        mvc.perform(get("/api/admin/signalements").param("utilisateur", String.valueOf(idAwa)).header("Authorization", admin))
                .andExpect(jsonPath("$.page.totalElements").value(1))
                .andExpect(jsonPath("$.content[0].id").value(s2));

        // --- Traitement du signalement 1 : prise en charge, puis avertissement
        decider(admin, s1, "PRENDRE_EN_CHARGE", null).andExpect(status().isOk()).andExpect(jsonPath("$.statut").value("EN_COURS"))
                .andExpect(jsonPath("$.signaleur.prenom").value("Awa"))
                .andExpect(jsonPath("$.totalContreSignale").value(1));
        decider(admin, s1, "PRENDRE_EN_CHARGE", null).andExpect(status().isConflict());
        decider(admin, s1, "AVERTIR", "  ").andExpect(status().isBadRequest());
        decider(awa, s1, "AVERTIR", "Test").andExpect(status().isForbidden());
        decider(admin, s1, "AVERTIR", "Respectez le code de la route.").andExpect(status().isOk())
                .andExpect(jsonPath("$.statut").value("TRAITE"))
                .andExpect(jsonPath("$.decisionAdmin").value("Respectez le code de la route."))
                .andExpect(jsonPath("$.admin").exists());
        decider(admin, s1, "CLASSER_SANS_SUITE", "Trop tard").andExpect(status().isConflict());
        mvc.perform(get("/api/moi/notifications").header("Authorization", "Bearer " + conducteur))
                .andExpect(jsonPath("$.content[0].type").value("SIGNALEMENT_TRAITE"))
                .andExpect(jsonPath("$.content[0].titre").value("Avertissement de l'équipe YOBALEMAsn"));
        mvc.perform(get("/api/moi/notifications").header("Authorization", "Bearer " + awa))
                .andExpect(jsonPath("$.content[0].type").value("SIGNALEMENT_TRAITE"))
                .andExpect(jsonPath("$.content[0].titre").value("Votre signalement a été examiné"));
        mvc.perform(get("/api/signalements/mes").header("Authorization", "Bearer " + awa))
                .andExpect(jsonPath("$[0].statut").value("TRAITE"))
                .andExpect(jsonPath("$[0].decisionAdmin").doesNotExist());   // le signaleur ne voit pas la décision

        // --- Limite quotidienne : 5 signalements par jour et par signaleur
        for (int i = 0; i < 4; i++) {
            jdbc.update("insert into signalement (id_signaleur, id_signale, motif, statut, date_signalement) "
                    + "values (?, ?, 'COMPORTEMENT', 'REJETE', now())", idAwa, idConducteur);
        }
        signaler(awa, idConducteur, "COMPORTEMENT", null, null).andExpect(status().isTooManyRequests());
        jdbc.update("delete from signalement where id_signaleur = ? and id_signalement <> ?", idAwa, s1);

        // --- Une fois traité, on peut signaler de nouveau ; classement sans suite
        long s3 = id(signaler(awa, idConducteur, "COMPORTEMENT", null, null).andExpect(status().isCreated()));
        decider(admin, s3, "CLASSER_SANS_SUITE", "Faits non établis.").andExpect(status().isOk())
                .andExpect(jsonPath("$.statut").value("REJETE"));
        mvc.perform(get("/api/admin/utilisateurs/" + idConducteur).header("Authorization", admin))
                .andExpect(jsonPath("$.historique[0].type").value("SIGNALEMENT_CLASSE"))
                .andExpect(jsonPath("$.historique[1].type").value("AVERTISSEMENT"));

        // --- Sanction : blocage du compte signalé
        decider(admin, s2, "BLOQUER", "Départ du véhicule sans prévenir.").andExpect(status().isOk())
                .andExpect(jsonPath("$.statut").value("TRAITE"));
        org.junit.jupiter.api.Assertions.assertEquals("BLOQUE",
                jdbc.queryForObject("select statut from utilisateur where id_utilisateur = ?", String.class, idAwa));
        mvc.perform(get("/api/admin/utilisateurs/" + idAwa).header("Authorization", admin))
                .andExpect(jsonPath("$.historique[0].type").value("COMPTE_BLOQUE"));
    }

    // ------------------------------------------------------------------ utilitaires

    private ResultActions signaler(String jeton, long idSignale, String motif, Long idTrajet, String description) throws Exception {
        String corps = "{\"idUtilisateur\":" + idSignale + ",\"motif\":\"" + motif + "\""
                + (idTrajet == null ? "" : ",\"idTrajet\":" + idTrajet)
                + (description == null ? "" : ",\"description\":\"" + description + "\"") + "}";
        return appel(post("/api/signalements").header("Authorization", "Bearer " + jeton), corps);
    }

    private ResultActions decider(String jeton, long id, String decision, String message) throws Exception {
        String autorisation = jeton.startsWith("Bearer ") ? jeton : "Bearer " + jeton;
        String corps = "{\"decision\":\"" + decision + "\"" + (message == null ? "" : ",\"message\":\"" + message + "\"") + "}";
        return appel(patch("/api/admin/signalements/" + id).header("Authorization", autorisation), corps);
    }

    private long id(ResultActions r) throws Exception {
        return ((Number) JsonPath.read(r.andReturn().getResponse().getContentAsString(), "$.id")).longValue();
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
