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
import sn.isep.Convoiturage.notification.RappelsTrajet;

import java.time.LocalDate;
import java.time.LocalDateTime;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

/**
 * Module 06 — notifications sur la base locale « covoiturage_test » : demande de réservation (conducteur prévenu,
 * aussi par email), acceptation, modification et annulation du trajet (passager prévenu), rappel avant le départ
 * (une seule fois), lecture et compteur des non lues.
 */
@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
@Import({ParcoursCompletTest.BaseDeTestPropre.class, ParcoursCompletTest.CodesDeTest.class})
class NotificationsParcoursTest {

    static final double DAKAR_LAT = 14.6681, DAKAR_LNG = -17.4318;
    static final double THIES_LAT = 14.7910, THIES_LNG = -16.9260;

    @Autowired
    MockMvc mvc;

    @Autowired
    JdbcTemplate jdbc;

    @Autowired
    RappelsTrajet rappels;

    private String dernierRefresh;

    @Test
    void notificationsDuParcoursDeReservation() throws Exception {
        String conducteur = conducteurValide("Ibou", "Ndoye", "ibou.notif@test.sn", "772224455");
        String passagere = inscrire("Coumba", "Faye", "coumba.notif@test.sn", "762224455", "FEMME");
        long idVehicule = ((Number) JsonPath.read(mvc.perform(get("/api/moi/vehicules").header("Authorization", conducteur))
                .andReturn().getResponse().getContentAsString(), "$[0].id")).longValue();
        String trajet = appel(post("/api/trajets").header("Authorization", conducteur), """
                {"idVehicule":%d,"depart":{"lieu":"Dakar","latitude":%s,"longitude":%s},
                 "arrivee":{"lieu":"Thiès","latitude":%s,"longitude":%s},"dateHeureDepart":"%sT10:00:00",
                 "flexibiliteMinutes":20,"nombrePlaces":3,"modeReservation":"MANUELLE","tailleBagage":"MOYEN",
                 "femmesUniquement":false}""".formatted(idVehicule, DAKAR_LAT, DAKAR_LNG, THIES_LAT, THIES_LNG,
                        LocalDate.now().plusDays(2)))
                .andExpect(status().isCreated()).andReturn().getResponse().getContentAsString();
        long idTrajet = ((Number) JsonPath.read(trajet, "$.id")).longValue();

        // Demande : le conducteur est prévenu dans l'application (lien vers le trajet) et par email
        long idResa = ((Number) JsonPath.read(appel(post("/api/trajets/" + idTrajet + "/reservations").header("Authorization", passagere),
                "{\"nombrePlaces\":1,\"moyenPaiement\":\"ESPECES\"}").andExpect(status().isCreated())
                .andReturn().getResponse().getContentAsString(), "$.id")).longValue();
        mvc.perform(get("/api/moi/notifications/non-lues").header("Authorization", conducteur))
                .andExpect(jsonPath("$.nombre").value(1));
        mvc.perform(get("/api/moi/notifications").header("Authorization", conducteur))
                .andExpect(jsonPath("$.content[0].type").value("RESERVATION_DEMANDEE"))
                .andExpect(jsonPath("$.content[0].lien").value("/trajets/" + idTrajet))
                .andExpect(jsonPath("$.content[0].lu").value(false));
        ParcoursCompletTest.CodesDeTest.attendreEmail("ibou.notif@test.sn", "YOBALEMAsn - Nouvelle demande de réservation");

        // Acceptation, puis changement d'horaire : la passagère est prévenue à chaque fois
        appel(post("/api/reservations/" + idResa + "/accepter").header("Authorization", conducteur), "").andExpect(status().isOk());
        appel(put("/api/trajets/" + idTrajet).header("Authorization", conducteur), "{\"flexibiliteMinutes\":30}")
                .andExpect(status().isOk());
        mvc.perform(get("/api/moi/notifications").header("Authorization", passagere))
                .andExpect(jsonPath("$.content.length()").value(2))
                .andExpect(jsonPath("$.content[0].type").value("TRAJET_MODIFIE"))
                .andExpect(jsonPath("$.content[1].type").value("RESERVATION_CONFIRMEE"));

        // Rappel une heure avant le départ : conducteur et passagère, une seule fois
        jdbc.update("update trajet set date_heure_depart = ? where id_trajet = ?", LocalDateTime.now().plusMinutes(40), idTrajet);
        assertThat(rappels.envoyer(LocalDateTime.now())).isEqualTo(2);
        assertThat(rappels.envoyer(LocalDateTime.now())).isZero();
        mvc.perform(get("/api/moi/notifications").header("Authorization", passagere))
                .andExpect(jsonPath("$.content[0].type").value("RAPPEL_TRAJET"));

        // Annulation du trajet : la passagère est prévenue (importante : aussi par email)
        jdbc.update("update trajet set date_heure_depart = ? where id_trajet = ?", LocalDateTime.now().plusDays(1), idTrajet);
        appel(post("/api/trajets/" + idTrajet + "/annuler").header("Authorization", conducteur), "{\"motif\":\"Panne\"}")
                .andExpect(status().isOk());
        String liste = mvc.perform(get("/api/moi/notifications").header("Authorization", passagere))
                .andExpect(jsonPath("$.content[0].type").value("TRAJET_ANNULE"))
                .andReturn().getResponse().getContentAsString();
        ParcoursCompletTest.CodesDeTest.attendreEmail("coumba.notif@test.sn", "YOBALEMAsn - Trajet annulé");

        // Lecture : une notification, puis toutes ; personne d'autre ne peut toucher aux siennes
        long idNotif = ((Number) JsonPath.read(liste, "$.content[0].id")).longValue();
        mvc.perform(post("/api/moi/notifications/" + idNotif + "/lue").header("Authorization", conducteur))
                .andExpect(status().isNotFound());
        mvc.perform(post("/api/moi/notifications/" + idNotif + "/lue").header("Authorization", passagere))
                .andExpect(status().isNoContent());
        mvc.perform(get("/api/moi/notifications/non-lues").header("Authorization", passagere))
                .andExpect(jsonPath("$.nombre").value(3));
        mvc.perform(post("/api/moi/notifications/lues").header("Authorization", passagere)).andExpect(status().isNoContent());
        mvc.perform(get("/api/moi/notifications/non-lues").header("Authorization", passagere))
                .andExpect(jsonPath("$.nombre").value(0));
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
