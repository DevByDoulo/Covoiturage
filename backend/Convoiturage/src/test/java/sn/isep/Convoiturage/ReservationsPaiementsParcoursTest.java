package sn.isep.Convoiturage;

import com.jayway.jsonpath.JsonPath;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.webmvc.test.autoconfigure.AutoConfigureMockMvc;
import org.springframework.context.annotation.Import;
import org.springframework.http.HttpMethod;
import org.springframework.http.MediaType;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.context.bean.override.convention.TestBean;
import org.springframework.test.web.client.MockRestServiceServer;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.ResultActions;
import org.springframework.test.web.servlet.request.MockHttpServletRequestBuilder;
import org.springframework.web.client.RestClient;
import sn.isep.Convoiturage.facturation.PaiementProperties;
import sn.isep.Convoiturage.facturation.WaveFournisseur;

import javax.crypto.Mac;
import javax.crypto.spec.SecretKeySpec;
import java.nio.charset.StandardCharsets;
import java.time.Clock;
import java.time.Instant;
import java.time.LocalDate;
import java.util.HexFormat;

import static org.springframework.test.web.client.match.MockRestRequestMatchers.method;
import static org.springframework.test.web.client.match.MockRestRequestMatchers.requestTo;
import static org.springframework.test.web.client.response.MockRestResponseCreators.withSuccess;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

/**
 * Module 04 — réservations et facturation sur la base locale « covoiturage_test » : demande, acceptation,
 * paiement en espèces à l'embarquement (PIN), paiement Wave (serveur Wave simulé, webhook signé),
 * annulation avec remboursement intégral, historique et reçus.
 */
@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
@Import({ParcoursCompletTest.BaseDeTestPropre.class, ParcoursCompletTest.CodesDeTest.class})
class ReservationsPaiementsParcoursTest {

    static final double DAKAR_LAT = 14.6681, DAKAR_LNG = -17.4318;
    static final double THIES_LAT = 14.7910, THIES_LNG = -16.9260;
    static final String SECRET_WEBHOOK = "secret-webhook-de-test";

    /** Serveur Wave simulé, branché sur le vrai WaveFournisseur (clés de test, retour en HTTPS). */
    static MockRestServiceServer serveurWave;

    @TestBean(name = "waveFournisseur")
    WaveFournisseur wave;

    static WaveFournisseur wave() {
        RestClient.Builder builder = RestClient.builder().baseUrl("https://api.wave.com");
        serveurWave = MockRestServiceServer.bindTo(builder).ignoreExpectOrder(true).build();
        PaiementProperties props = new PaiementProperties("https://yobalema.test",
                new PaiementProperties.Wave("wave_sn_test_cle", SECRET_WEBHOOK), null);
        return new WaveFournisseur(props, builder.build(), Clock.systemUTC());
    }

    @Autowired
    MockMvc mvc;

    @Autowired
    JdbcTemplate jdbc;

    private String dernierRefresh;

    @Test
    void reservationPaiementEmbarquementRemboursement() throws Exception {
        // --- Moyens proposés : Wave configuré, Orange Money pas encore branché
        String fatou = inscrire("Fatou", "Sarr", "fatou.resa@test.sn", "771113344", "FEMME");
        mvc.perform(get("/api/paiements/moyens").header("Authorization", "Bearer " + fatou))
                .andExpect(jsonPath("$[?(@.moyen == 'ESPECES')].disponible").value(true))
                .andExpect(jsonPath("$[?(@.moyen == 'WAVE')].disponible").value(true))
                .andExpect(jsonPath("$[?(@.moyen == 'ORANGE_MONEY')].disponible").value(false));

        // --- Conducteur validé, trajet en mode manuel (3 places)
        String conducteur = conducteurValide("Ousmane", "Fall", "ousmane.resa@test.sn", "781113344");
        long idVehicule = ((Number) JsonPath.read(mvc.perform(get("/api/moi/vehicules").header("Authorization", "Bearer " + conducteur))
                .andReturn().getResponse().getContentAsString(), "$[0].id")).longValue();
        String date = LocalDate.now().plusDays(3).toString();
        String trajet = appel(post("/api/trajets").header("Authorization", "Bearer " + conducteur), """
                {"idVehicule":%d,"depart":{"lieu":"Dakar","latitude":%s,"longitude":%s},
                 "arrivee":{"lieu":"Thiès","latitude":%s,"longitude":%s},"dateHeureDepart":"%sT10:00:00",
                 "flexibiliteMinutes":20,"nombrePlaces":3,"modeReservation":"MANUELLE","tailleBagage":"MOYEN",
                 "femmesUniquement":false}""".formatted(idVehicule, DAKAR_LAT, DAKAR_LNG, THIES_LAT, THIES_LNG, date))
                .andExpect(status().isCreated()).andReturn().getResponse().getContentAsString();
        long idTrajet = ((Number) JsonPath.read(trajet, "$.id")).longValue();
        double prix = ((Number) JsonPath.read(trajet, "$.prixParPlace")).doubleValue();

        // ============ 1. Espèces : demande -> acceptation -> PIN à l'embarquement -> encaissé
        String resa = appel(post("/api/trajets/" + idTrajet + "/reservations").header("Authorization", "Bearer " + fatou),
                "{\"nombrePlaces\":2,\"moyenPaiement\":\"ESPECES\"}")
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.statut").value("EN_ATTENTE"))
                .andExpect(jsonPath("$.statutPaiement").value("EN_ATTENTE"))
                .andExpect(jsonPath("$.montantTotal").value(prix * 2))
                .andReturn().getResponse().getContentAsString();
        long idResaFatou = ((Number) JsonPath.read(resa, "$.id")).longValue();
        // Orange Money pas encore disponible ; paiement en ligne impossible avant acceptation
        appel(post("/api/trajets/" + idTrajet + "/reservations").header("Authorization", "Bearer " + fatou),
                "{\"nombrePlaces\":1,\"moyenPaiement\":\"ORANGE_MONEY\"}").andExpect(status().isBadRequest());
        appel(post("/api/reservations/" + idResaFatou + "/paiement").header("Authorization", "Bearer " + fatou), "{}")
                .andExpect(status().isConflict());

        appel(post("/api/reservations/" + idResaFatou + "/accepter").header("Authorization", "Bearer " + conducteur), "")
                .andExpect(status().isOk()).andExpect(jsonPath("$.statut").value("ACCEPTEE"));
        String code = mvc.perform(get("/api/reservations/" + idResaFatou + "/embarquement").header("Authorization", "Bearer " + fatou))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.montantAPayer").value(prix * 2))
                .andReturn().getResponse().getContentAsString();
        String pin = JsonPath.read(code, "$.codePin");

        appel(post("/api/trajets/" + idTrajet + "/embarquement").header("Authorization", "Bearer " + conducteur),
                "{\"code\":\"" + (pin.equals("000000") ? "111111" : "000000") + "\"}").andExpect(status().isNotFound());
        appel(post("/api/trajets/" + idTrajet + "/embarquement").header("Authorization", "Bearer " + conducteur),
                "{\"code\":\"" + pin + "\"}")
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.montantAEncaisser").value(prix * 2))
                .andExpect(jsonPath("$.moyenPaiement").value("ESPECES"));

        // Historique et reçu, côté passagère et côté conducteur ; pas de commission
        String historique = mvc.perform(get("/api/moi/paiements").header("Authorization", "Bearer " + fatou))
                .andExpect(jsonPath("$.length()").value(1))
                .andExpect(jsonPath("$[0].role").value("PASSAGER"))
                .andExpect(jsonPath("$[0].statut").value("REUSSI"))
                .andReturn().getResponse().getContentAsString();
        String refFatou = JsonPath.read(historique, "$[0].referenceTransaction");
        mvc.perform(get("/api/paiements/" + refFatou + "/recu").header("Authorization", "Bearer " + conducteur))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.montant").value(prix * 2))
                .andExpect(jsonPath("$.commission").value(0))
                .andExpect(jsonPath("$.montantConducteur").value(prix * 2));
        mvc.perform(get("/api/moi/paiements").header("Authorization", "Bearer " + conducteur))
                .andExpect(jsonPath("$[0].role").value("CONDUCTEUR"));

        // ============ 2. Wave : acceptation -> session -> webhook signé -> annulation -> remboursement
        String moussa = inscrire("Moussa", "Diallo", "moussa.resa@test.sn", "761113344", "HOMME");
        // Un tiers ne voit pas le reçu de Fatou
        mvc.perform(get("/api/paiements/" + refFatou + "/recu").header("Authorization", "Bearer " + moussa))
                .andExpect(status().isNotFound());
        long idResaMoussa = ((Number) JsonPath.read(
                appel(post("/api/trajets/" + idTrajet + "/reservations").header("Authorization", "Bearer " + moussa),
                        "{\"nombrePlaces\":1,\"moyenPaiement\":\"WAVE\"}")
                        .andExpect(status().isCreated()).andReturn().getResponse().getContentAsString(), "$.id")).longValue();
        appel(post("/api/reservations/" + idResaMoussa + "/accepter").header("Authorization", "Bearer " + conducteur), "")
                .andExpect(status().isOk());

        serveurWave.expect(requestTo("https://api.wave.com/v1/checkout/sessions")).andExpect(method(HttpMethod.POST))
                .andRespond(withSuccess("""
                        {"id":"cos-test-1","wave_launch_url":"https://pay.wave.com/c/cos-test-1","checkout_status":"open",
                         "payment_status":"processing"}""", MediaType.APPLICATION_JSON));
        // Le serveur simulé exige de déclarer toutes ses réponses avant le premier appel.
        serveurWave.expect(requestTo("https://api.wave.com/v1/checkout/sessions/cos-test-1/refund"))
                .andExpect(method(HttpMethod.POST)).andRespond(withSuccess());
        String session = appel(post("/api/reservations/" + idResaMoussa + "/paiement").header("Authorization", "Bearer " + moussa), "{}")
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.moyen").value("WAVE"))
                .andExpect(jsonPath("$.urlPaiement").value("https://pay.wave.com/c/cos-test-1"))
                .andReturn().getResponse().getContentAsString();
        String refMoussa = JsonPath.read(session, "$.referenceTransaction");

        String evenement = """
                {"id":"AE_test_1","type":"checkout.session.completed","data":{"id":"cos-test-1","client_reference":"%s",
                 "payment_status":"succeeded","checkout_status":"complete","amount":"%d","currency":"XOF"}}"""
                .formatted(refMoussa, (long) prix);
        // Signature invalide : refusée
        webhook(evenement, "t=" + Instant.now().getEpochSecond() + ",v1=00").andExpect(status().isUnauthorized());
        // Signature valide (et renvoi du même événement : sans effet)
        webhook(evenement, signer(evenement)).andExpect(status().isOk());
        webhook(evenement, signer(evenement)).andExpect(status().isOk());

        mvc.perform(get("/api/reservations/" + idResaMoussa + "/embarquement").header("Authorization", "Bearer " + moussa))
                .andExpect(jsonPath("$.montantAPayer").value(0));
        mvc.perform(get("/api/moi/reservations").header("Authorization", "Bearer " + moussa))
                .andExpect(jsonPath("$[0].statutPaiement").value("REUSSI"));
        appel(post("/api/reservations/" + idResaMoussa + "/paiement").header("Authorization", "Bearer " + moussa), "{}")
                .andExpect(status().isConflict());

        // Annulation avant le départ : remboursement intégral par Wave (réponse déclarée plus haut)
        appel(post("/api/reservations/" + idResaMoussa + "/annuler").header("Authorization", "Bearer " + moussa),
                "{\"motif\":\"Changement de programme\"}")
                .andExpect(status().isOk()).andExpect(jsonPath("$.statut").value("ANNULEE"));
        serveurWave.verify();
        mvc.perform(get("/api/moi/paiements").header("Authorization", "Bearer " + moussa))
                .andExpect(jsonPath("$[0].statut").value("REMBOURSE"))
                .andExpect(jsonPath("$[0].dateRemboursement").isString());
        mvc.perform(get("/api/paiements/" + refMoussa + "/recu").header("Authorization", "Bearer " + moussa))
                .andExpect(status().isOk()).andExpect(jsonPath("$.statut").value("REMBOURSE"));

        // La place de Moussa est remise en vente : 3 - 2 (Fatou) = 1 place
        mvc.perform(get("/api/trajets/" + idTrajet)).andExpect(jsonPath("$.nombrePlacesDisponibles").value(1));
    }

    // ------------------------------------------------------------------ utilitaires

    private String conducteurValide(String prenom, String nom, String email, String tel) throws Exception {
        String jeton = inscrire(prenom, nom, email, tel, "HOMME");
        appel(post("/api/moi/vehicules").header("Authorization", "Bearer " + jeton), """
                {"immatriculation":"DK-%s","marque":"Peugeot","modele":"308","annee":2019,"puissanceFiscale":6,
                 "nombrePlaces":5,"typeEnergie":"DIESEL","consommationReelle":5.5}""".formatted(tel.substring(5)))
                .andExpect(status().isCreated());
        // Validation des documents par l'administrateur (module 07, pas encore disponible) : simulée en base.
        jdbc.update("update vehicule set statut_validation = 'VALIDE' where id_proprietaire = "
                + "(select id_utilisateur from utilisateur where email = ?)", email);
        jdbc.update("update utilisateur set conducteur_valide = true where email = ?", email);
        return jeton(appel(post("/api/auth/refresh"), "{\"refreshToken\":\"" + dernierRefresh + "\"}"));
    }

    private ResultActions webhook(String corps, String signature) throws Exception {
        return mvc.perform(post("/api/paiements/webhooks/wave").header("Wave-Signature", signature)
                .contentType(MediaType.APPLICATION_JSON).content(corps));
    }

    private static String signer(String corps) throws Exception {
        long t = Instant.now().getEpochSecond();
        Mac mac = Mac.getInstance("HmacSHA256");
        mac.init(new SecretKeySpec(SECRET_WEBHOOK.getBytes(StandardCharsets.UTF_8), "HmacSHA256"));
        return "t=" + t + ",v1=" + HexFormat.of().formatHex(mac.doFinal((t + corps).getBytes(StandardCharsets.UTF_8)));
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
