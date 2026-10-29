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
 * 09 — Messagerie sur la base locale « covoiturage_test » : un passager écrit au conducteur avant de réserver,
 * notification (une seule tant qu'elle n'est pas lue), lecture, réponse, accès refusé aux autres, conversation
 * fermée 7 jours après le départ.
 */
@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
@Import({ParcoursCompletTest.BaseDeTestPropre.class, ParcoursCompletTest.CodesDeTest.class})
class MessagerieParcoursTest {

    static final double DAKAR_LAT = 14.6681, DAKAR_LNG = -17.4318;
    static final double THIES_LAT = 14.7910, THIES_LNG = -16.9260;

    @Autowired
    MockMvc mvc;

    @Autowired
    JdbcTemplate jdbc;

    private String dernierRefresh;

    @Test
    void conversationEntrePassagerEtConducteur() throws Exception {
        String conducteur = conducteurValide("Lamine", "Gaye", "lamine.messages@test.sn", "774446677");
        String passagere = inscrire("Ndeye", "Sow", "ndeye.messages@test.sn", "764446677", "FEMME");
        String autre = inscrire("Pape", "Fall", "pape.messages@test.sn", "784446677", "HOMME");
        long idVehicule = ((Number) JsonPath.read(mvc.perform(get("/api/moi/vehicules").header("Authorization", conducteur))
                .andReturn().getResponse().getContentAsString(), "$[0].id")).longValue();
        long idTrajet = ((Number) JsonPath.read(appel(post("/api/trajets").header("Authorization", conducteur), """
                {"idVehicule":%d,"depart":{"lieu":"Dakar","latitude":%s,"longitude":%s},
                 "arrivee":{"lieu":"Thiès","latitude":%s,"longitude":%s},"dateHeureDepart":"%sT10:00:00",
                 "flexibiliteMinutes":20,"nombrePlaces":3,"modeReservation":"MANUELLE","tailleBagage":"MOYEN",
                 "femmesUniquement":false}""".formatted(idVehicule, DAKAR_LAT, DAKAR_LNG, THIES_LAT, THIES_LNG,
                        LocalDate.now().plusDays(2)))
                .andExpect(status().isCreated()).andReturn().getResponse().getContentAsString(), "$.id")).longValue();

        // La passagère écrit avant de réserver ; rouvrir donne la même conversation
        long idConv = ouvrir(passagere, idTrajet);
        assertThat(ouvrir(passagere, idTrajet)).isEqualTo(idConv);
        envoyer(passagere, idConv, "Bonjour, il reste de la place pour une valise ?").andExpect(status().isCreated())
                .andExpect(jsonPath("$.deMoi").value(true));
        envoyer(passagere, idConv, "   ").andExpect(status().isBadRequest());
        envoyer(passagere, idConv, "Je pars de Liberté 6.").andExpect(status().isCreated());

        // Le conducteur : 2 non lus, une seule notification, la conversation dans sa liste
        mvc.perform(get("/api/moi/conversations/non-lus").header("Authorization", conducteur))
                .andExpect(jsonPath("$.nombre").value(2));
        mvc.perform(get("/api/moi/conversations").header("Authorization", conducteur))
                .andExpect(jsonPath("$.length()").value(1))
                .andExpect(jsonPath("$[0].interlocuteur.prenom").value("Ndeye"))
                .andExpect(jsonPath("$[0].jeSuisConducteur").value(true))
                .andExpect(jsonPath("$[0].dernierMessage").value("Je pars de Liberté 6."))
                .andExpect(jsonPath("$[0].nonLus").value(2));
        mvc.perform(get("/api/moi/notifications").header("Authorization", conducteur))
                .andExpect(jsonPath("$.content.length()").value(1))
                .andExpect(jsonPath("$.content[0].type").value("MESSAGE_RECU"))
                .andExpect(jsonPath("$.content[0].titre").value("Nouveau message de Ndeye"))
                .andExpect(jsonPath("$.content[0].lien").value("/messages/" + idConv));

        // Lecture puis réponse : les messages de la passagère sont lus, elle a 1 non lu
        mvc.perform(get("/api/moi/conversations/" + idConv).header("Authorization", conducteur))
                .andExpect(jsonPath("$.messages.length()").value(2))
                .andExpect(jsonPath("$.messages[0].contenu").value("Bonjour, il reste de la place pour une valise ?"))
                .andExpect(jsonPath("$.messages[0].deMoi").value(false))
                .andExpect(jsonPath("$.interlocuteur.prenom").value("Ndeye"))
                .andExpect(jsonPath("$.fermeture").isEmpty());
        mvc.perform(get("/api/moi/conversations/non-lus").header("Authorization", conducteur))
                .andExpect(jsonPath("$.nombre").value(0));
        envoyer(conducteur, idConv, "Oui, sans problème.").andExpect(status().isCreated());
        mvc.perform(get("/api/moi/conversations/non-lus").header("Authorization", passagere))
                .andExpect(jsonPath("$.nombre").value(1));
        mvc.perform(get("/api/moi/conversations/" + idConv).header("Authorization", passagere))
                .andExpect(jsonPath("$.messages.length()").value(3))
                .andExpect(jsonPath("$.messages[0].lu").value(true))
                .andExpect(jsonPath("$.messages[2].deMoi").value(false));

        // Personne d'autre ne voit ni n'écrit ; le conducteur n'écrit qu'aux passagers qui ont réservé
        mvc.perform(get("/api/moi/conversations/" + idConv).header("Authorization", autre)).andExpect(status().isNotFound());
        envoyer(autre, idConv, "Coucou").andExpect(status().isNotFound());
        appel(post("/api/trajets/" + idTrajet + "/conversation").header("Authorization", conducteur), "{}")
                .andExpect(status().isBadRequest());
        Long idAutre = jdbc.queryForObject("select id_utilisateur from utilisateur where email = 'pape.messages@test.sn'", Long.class);
        appel(post("/api/trajets/" + idTrajet + "/conversation").header("Authorization", conducteur), "{\"idPassager\":" + idAutre + "}")
                .andExpect(status().isNotFound());

        // 7 jours après le départ : la conversation reste lisible mais fermée
        jdbc.update("update trajet set date_heure_depart = ? where id_trajet = ?", LocalDateTime.now().minusDays(8), idTrajet);
        envoyer(passagere, idConv, "Merci !").andExpect(status().isConflict());
        mvc.perform(get("/api/moi/conversations/" + idConv).header("Authorization", passagere))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.fermeture").isString());
    }

    private long ouvrir(String jeton, long idTrajet) throws Exception {
        String r = appel(post("/api/trajets/" + idTrajet + "/conversation").header("Authorization", jeton), "{}")
                .andExpect(status().isOk()).andReturn().getResponse().getContentAsString();
        return ((Number) JsonPath.read(r, "$.id")).longValue();
    }

    private ResultActions envoyer(String jeton, long idConv, String contenu) throws Exception {
        return appel(post("/api/moi/conversations/" + idConv + "/messages").header("Authorization", jeton),
                "{\"contenu\":\"" + contenu + "\"}");
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
