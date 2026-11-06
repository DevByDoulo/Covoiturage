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
import java.time.LocalDateTime;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

/**
 * 08 — Suivi du conducteur en temps réel : partage refusé trop tôt, puis possible une heure avant le départ ;
 * le passager accepté voit la position et est prévenu une seule fois ; les autres non ; arrêt du partage et fin du
 * trajet effacent la position.
 */
@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
@Import({ParcoursCompletTest.BaseDeTestPropre.class, ParcoursCompletTest.CodesDeTest.class})
class SuiviPositionParcoursTest {

    static final double DAKAR_LAT = 14.6681, DAKAR_LNG = -17.4318;
    static final double THIES_LAT = 14.7910, THIES_LNG = -16.9260;
    static final String POSITION = """
            {"latitude":14.6702,"longitude":-17.4380,"precisionM":12,"cap":90,"vitesse":8.5}""";

    @Autowired
    MockMvc mvc;

    @Autowired
    JdbcTemplate jdbc;

    private String dernierRefresh;

    @Test
    void lePassagerSuitSonConducteur() throws Exception {
        String conducteur = conducteurValide("Ibou", "Sarr", "ibou.suivi@test.sn", "778889911");
        String passagere = inscrire("Coumba", "Diallo", "coumba.suivi@test.sn", "768889911", "FEMME");
        String autre = inscrire("Modou", "Kane", "modou.suivi@test.sn", "788889911", "HOMME");
        long idVehicule = ((Number) JsonPath.read(mvc.perform(get("/api/moi/vehicules").header("Authorization", conducteur))
                .andReturn().getResponse().getContentAsString(), "$[0].id")).longValue();
        long idTrajet = ((Number) JsonPath.read(appel(post("/api/trajets").header("Authorization", conducteur), """
                {"idVehicule":%d,"depart":{"lieu":"Dakar","latitude":%s,"longitude":%s},
                 "arrivee":{"lieu":"Thiès","latitude":%s,"longitude":%s},"dateHeureDepart":"%sT10:00:00",
                 "flexibiliteMinutes":20,"nombrePlaces":3,"modeReservation":"MANUELLE","tailleBagage":"MOYEN",
                 "femmesUniquement":false}""".formatted(idVehicule, DAKAR_LAT, DAKAR_LNG, THIES_LAT, THIES_LNG,
                        LocalDate.now().plusDays(2)))
                .andExpect(status().isCreated()).andReturn().getResponse().getContentAsString(), "$.id")).longValue();
        long idReservation = ((Number) JsonPath.read(appel(post("/api/trajets/" + idTrajet + "/reservations")
                        .header("Authorization", passagere), "{\"nombrePlaces\":1,\"moyenPaiement\":\"ESPECES\"}")
                .andExpect(status().isCreated()).andReturn().getResponse().getContentAsString(), "$.id")).longValue();
        appel(post("/api/reservations/" + idReservation + "/accepter").header("Authorization", conducteur), "{}")
                .andExpect(status().isOk());
        String position = "/api/trajets/" + idTrajet + "/position";

        // Départ dans deux jours : trop tôt pour partager ; rien à voir
        appel(post(position).header("Authorization", conducteur), POSITION).andExpect(status().isConflict());
        mvc.perform(get(position).header("Authorization", passagere)).andExpect(status().isNoContent());

        // Départ dans 30 minutes : le partage commence, la passagère est prévenue une fois
        jdbc.update("update trajet set date_heure_depart = ? where id_trajet = ?", LocalDateTime.now().plusMinutes(30), idTrajet);
        appel(post(position).header("Authorization", passagere), POSITION).andExpect(status().isForbidden());
        appel(post(position).header("Authorization", conducteur), POSITION).andExpect(status().isOk())
                .andExpect(jsonPath("$.latitude").value(14.6702));
        appel(post(position).header("Authorization", conducteur), """
                {"latitude":14.6710,"longitude":-17.4360}""").andExpect(status().isOk());
        appel(post(position).header("Authorization", conducteur), "{\"latitude\":120,\"longitude\":0}")
                .andExpect(status().isBadRequest());

        mvc.perform(get(position).header("Authorization", passagere))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.latitude").value(14.6710))
                .andExpect(jsonPath("$.longitude").value(-17.4360))
                .andExpect(jsonPath("$.precisionM").isEmpty())
                .andExpect(jsonPath("$.ageSecondes").isNumber());
        String notifs = mvc.perform(get("/api/moi/notifications").header("Authorization", passagere))
                .andReturn().getResponse().getContentAsString();
        assertThat(JsonPath.<java.util.List<Object>>read(notifs, "$.content[?(@.type == 'POSITION_PARTAGEE')]")).hasSize(1);
        assertThat(JsonPath.<java.util.List<String>>read(notifs, "$.content[?(@.type == 'POSITION_PARTAGEE')].lien"))
                .containsExactly("/trajets/" + idTrajet + "/suivi");

        // Personne d'autre ne suit le conducteur
        mvc.perform(get(position).header("Authorization", autre)).andExpect(status().isForbidden());

        // Arrêt du partage : plus de position
        mvc.perform(delete(position).header("Authorization", conducteur)).andExpect(status().isNoContent());
        mvc.perform(get(position).header("Authorization", passagere)).andExpect(status().isNoContent());

        // Reprise pendant le trajet, puis fin du trajet : la position est effacée
        appel(post("/api/trajets/" + idTrajet + "/demarrer").header("Authorization", conducteur), "{}").andExpect(status().isOk());
        appel(post(position).header("Authorization", conducteur), POSITION).andExpect(status().isOk());
        assertThat(jdbc.queryForObject("select count(*) from position_conducteur where id_trajet = ?", Integer.class, idTrajet))
                .isEqualTo(1);
        appel(post("/api/trajets/" + idTrajet + "/terminer").header("Authorization", conducteur), "{}").andExpect(status().isOk());
        assertThat(jdbc.queryForObject("select count(*) from position_conducteur where id_trajet = ?", Integer.class, idTrajet))
                .isZero();
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
