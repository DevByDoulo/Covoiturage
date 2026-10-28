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

import java.time.LocalDate;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

/**
 * Alertes de recherche sur la base locale « covoiturage_test » : création, liste, déclenchement à la publication
 * d'un trajet correspondant (et seulement lui), suppression.
 */
@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
@Import({ParcoursCompletTest.BaseDeTestPropre.class, ParcoursCompletTest.CodesDeTest.class})
class AlertesRechercheParcoursTest {

    static final double DAKAR_LAT = 14.6681, DAKAR_LNG = -17.4318;
    static final double THIES_LAT = 14.7910, THIES_LNG = -16.9260;
    static final double MBOUR_LAT = 14.4220, MBOUR_LNG = -16.9640;

    @Autowired
    MockMvc mvc;

    @Autowired
    JdbcTemplate jdbc;

    private String dernierRefresh;

    @Test
    void alerteDeclencheeParUnTrajetCorrespondant() throws Exception {
        String conducteur = conducteurValide("Modou", "Sarr", "modou.alerte@test.sn", "773335566");
        String passager = inscrire("Fatou", "Diop", "fatou.alerte@test.sn", "763335566", "FEMME");
        LocalDate jour = LocalDate.now().plusDays(3);

        // Création et liste ; une date passée est refusée
        long idAlerte = ((Number) JsonPath.read(appel(post("/api/moi/alertes").header("Authorization", passager), """
                {"depart":{"lieu":"Dakar","latitude":%s,"longitude":%s},
                 "arrivee":{"lieu":"Thiès","latitude":%s,"longitude":%s},"date":"%s"}"""
                .formatted(DAKAR_LAT, DAKAR_LNG, THIES_LAT, THIES_LNG, jour))
                .andExpect(status().isCreated()).andReturn().getResponse().getContentAsString(), "$.id")).longValue();
        appel(post("/api/moi/alertes").header("Authorization", passager), """
                {"depart":{"lieu":"Dakar","latitude":%s,"longitude":%s},
                 "arrivee":{"lieu":"Thiès","latitude":%s,"longitude":%s},"date":"%s"}"""
                .formatted(DAKAR_LAT, DAKAR_LNG, THIES_LAT, THIES_LNG, LocalDate.now().minusDays(1)))
                .andExpect(status().isBadRequest());
        mvc.perform(get("/api/moi/alertes").header("Authorization", passager))
                .andExpect(jsonPath("$.length()").value(1))
                .andExpect(jsonPath("$[0].arrivee.lieu").value("Thiès"));

        // Un trajet vers Mbour le même jour ne déclenche rien ; Dakar → Thiès ce jour-là, si
        publier(conducteur, "Mbour", MBOUR_LAT, MBOUR_LNG, jour);
        mvc.perform(get("/api/moi/notifications/non-lues").header("Authorization", passager))
                .andExpect(jsonPath("$.nombre").value(0));
        long idTrajet = publier(conducteur, "Thiès", THIES_LAT, THIES_LNG, jour);
        mvc.perform(get("/api/moi/notifications").header("Authorization", passager))
                .andExpect(jsonPath("$.content.length()").value(1))
                .andExpect(jsonPath("$.content[0].type").value("ALERTE_TRAJET"))
                .andExpect(jsonPath("$.content[0].lien").value("/trajets/" + idTrajet));

        // Suppression : seulement par son auteur, puis l'alerte ne se déclenche plus
        mvc.perform(delete("/api/moi/alertes/" + idAlerte).header("Authorization", conducteur))
                .andExpect(status().isNotFound());
        mvc.perform(delete("/api/moi/alertes/" + idAlerte).header("Authorization", passager))
                .andExpect(status().isNoContent());
        mvc.perform(get("/api/moi/alertes").header("Authorization", passager))
                .andExpect(jsonPath("$.length()").value(0));
        publier(conducteur, "Thiès", THIES_LAT, THIES_LNG, jour);
        mvc.perform(get("/api/moi/notifications/non-lues").header("Authorization", passager))
                .andExpect(jsonPath("$.nombre").value(1));
    }

    private long publier(String conducteur, String arrivee, double lat, double lng, LocalDate jour) throws Exception {
        long idVehicule = ((Number) JsonPath.read(mvc.perform(get("/api/moi/vehicules").header("Authorization", conducteur))
                .andReturn().getResponse().getContentAsString(), "$[0].id")).longValue();
        String trajet = appel(post("/api/trajets").header("Authorization", conducteur), """
                {"idVehicule":%d,"depart":{"lieu":"Dakar","latitude":%s,"longitude":%s},
                 "arrivee":{"lieu":"%s","latitude":%s,"longitude":%s},"dateHeureDepart":"%sT10:00:00",
                 "flexibiliteMinutes":20,"nombrePlaces":3,"modeReservation":"MANUELLE","tailleBagage":"MOYEN",
                 "femmesUniquement":false}""".formatted(idVehicule, DAKAR_LAT, DAKAR_LNG, arrivee, lat, lng, jour))
                .andExpect(status().isCreated()).andReturn().getResponse().getContentAsString();
        return ((Number) JsonPath.read(trajet, "$.id")).longValue();
    }

    // ------------------------------------------------------------------ utilitaires

    private String conducteurValide(String prenom, String nom, String email, String tel) throws Exception {
        String jeton = "Bearer " + inscrire(prenom, nom, email, tel, "HOMME").substring(7);
        appel(post("/api/moi/vehicules").header("Authorization", jeton), """
                {"immatriculation":"DK-%s","marque":"Peugeot","modele":"308","annee":2019,"puissanceFiscale":6,
                 "nombrePlaces":5,"typeEnergie":"DIESEL","consommationReelle":5.5}""".formatted(tel.substring(5)))
                .andExpect(status().isCreated());
        jdbc.update("update vehicule set statut_validation = 'VALIDE' where id_proprietaire = "
                + "(select id_utilisateur from utilisateur where email = ?)", email);
        jdbc.update("update utilisateur set conducteur_valide = true where email = ?", email);
        return "Bearer " + jeton(appel(post("/api/auth/refresh"), "{\"refreshToken\":\"" + dernierRefresh + "\"}"));
    }

    /** Renvoie « Bearer <jeton> ». */
    private String inscrire(String prenom, String nom, String email, String tel, String sexe) throws Exception {
        String ancien = ParcoursCompletTest.CodesDeTest.DERNIER_CODE.get(email);
        appel(post("/api/auth/inscription"), """
                {"prenom":"%s","nom":"%s","email":"%s","telephone":"%s","motDePasse":"MotDePasse2026","sexe":"%s"}"""
                .formatted(prenom, nom, email, tel, sexe))
                .andExpect(status().isCreated());
        String code = ParcoursCompletTest.CodesDeTest.attendreNouveauCode(email, ancien);
        return "Bearer " + jeton(appel(post("/api/auth/otp/verifier"), "{\"identifiant\":\"" + tel + "\",\"code\":\"" + code + "\"}"));
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
