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
import org.springframework.test.context.TestPropertySource;
import org.springframework.test.context.bean.override.convention.TestBean;
import org.springframework.test.web.client.MockRestServiceServer;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.ResultActions;
import org.springframework.test.web.servlet.request.MockHttpServletRequestBuilder;
import org.springframework.web.client.RestClient;
import sn.isep.Convoiturage.facturation.PaiementProperties;
import sn.isep.Convoiturage.facturation.PayDunyaClient;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.time.LocalDate;
import java.util.HexFormat;

import static org.springframework.test.web.client.match.MockRestRequestMatchers.jsonPath;
import static org.springframework.test.web.client.match.MockRestRequestMatchers.method;
import static org.springframework.test.web.client.match.MockRestRequestMatchers.requestTo;
import static org.springframework.test.web.client.response.MockRestResponseCreators.withSuccess;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

/**
 * Paiement via PayDunya (mode test, serveur PayDunya simulé) : Orange Money proposé, facture limitée au canal
 * choisi, vérification au retour du passager, IPN authentifié par le hash de la clé principale, annulation
 * (remboursement en attente : le déboursement n'existe pas en mode test).
 */
@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
@Import({ParcoursCompletTest.BaseDeTestPropre.class, ParcoursCompletTest.CodesDeTest.class})
@TestPropertySource(properties = {
        "app.paiement.url-retour=http://localhost:4200",
        "app.paiement.paydunya.master-key=" + PayDunyaParcoursTest.CLE_PRINCIPALE,
        "app.paiement.paydunya.private-key=test_private_cle",
        "app.paiement.paydunya.token=jeton-de-test",
        "app.paiement.paydunya.mode=test"})
class PayDunyaParcoursTest {

    static final String CLE_PRINCIPALE = "cle-principale-de-test";
    static final double DAKAR_LAT = 14.6681, DAKAR_LNG = -17.4318;
    static final double THIES_LAT = 14.7910, THIES_LNG = -16.9260;

    /** Serveur PayDunya simulé, branché sur le vrai client (mêmes clés que la configuration ci-dessus). */
    static MockRestServiceServer serveurPayDunya;

    @TestBean(name = "payDunyaClient")
    PayDunyaClient payDunya;

    static PayDunyaClient payDunya() {
        PaiementProperties props = new PaiementProperties("http://localhost:4200", null, null, null,
                new PaiementProperties.PayDunya(CLE_PRINCIPALE, "test_private_cle", "jeton-de-test", "test"));
        RestClient.Builder builder = PayDunyaClient.authentifier(RestClient.builder(), props);
        serveurPayDunya = MockRestServiceServer.bindTo(builder).build();
        return new PayDunyaClient(props, builder.build());
    }

    @Autowired
    MockMvc mvc;

    @Autowired
    JdbcTemplate jdbc;

    private String dernierRefresh;

    @Test
    void paiementOrangeMoneyParPayDunya() throws Exception {
        String conducteur = conducteurValide("Babacar", "Diouf", "babacar.paydunya@test.sn", "775556677");
        String passagere = inscrire("Aminata", "Ba", "aminata.paydunya@test.sn", "765556677", "FEMME");
        String autre = inscrire("Cheikh", "Mbaye", "cheikh.paydunya@test.sn", "785556677", "HOMME");

        // Wave et Orange Money proposés grâce à PayDunya
        mvc.perform(get("/api/paiements/moyens").header("Authorization", passagere))
                .andExpect(org.springframework.test.web.servlet.result.MockMvcResultMatchers
                        .jsonPath("$[?(@.moyen == 'ORANGE_MONEY')].disponible").value(true))
                .andExpect(org.springframework.test.web.servlet.result.MockMvcResultMatchers
                        .jsonPath("$[?(@.moyen == 'WAVE')].disponible").value(true));

        long idVehicule = ((Number) JsonPath.read(mvc.perform(get("/api/moi/vehicules").header("Authorization", conducteur))
                .andReturn().getResponse().getContentAsString(), "$[0].id")).longValue();
        long idTrajet = ((Number) JsonPath.read(appel(post("/api/trajets").header("Authorization", conducteur), """
                {"idVehicule":%d,"depart":{"lieu":"Dakar","latitude":%s,"longitude":%s},
                 "arrivee":{"lieu":"Thiès","latitude":%s,"longitude":%s},"dateHeureDepart":"%sT10:00:00",
                 "flexibiliteMinutes":20,"nombrePlaces":3,"modeReservation":"AUTOMATIQUE","tailleBagage":"MOYEN",
                 "femmesUniquement":false}""".formatted(idVehicule, DAKAR_LAT, DAKAR_LNG, THIES_LAT, THIES_LNG,
                        LocalDate.now().plusDays(2)))
                .andExpect(status().isCreated()).andReturn().getResponse().getContentAsString(), "$.id")).longValue();
        long idResa = ((Number) JsonPath.read(appel(post("/api/trajets/" + idTrajet + "/reservations").header("Authorization", passagere),
                "{\"nombrePlaces\":1,\"moyenPaiement\":\"ORANGE_MONEY\"}").andExpect(status().isCreated())
                .andReturn().getResponse().getContentAsString(), "$.id")).longValue();

        // --- Ouverture du paiement : facture PayDunya limitée à Orange Money
        serveurPayDunya.expect(requestTo("https://app.paydunya.com/sandbox-api/v1/checkout-invoice/create"))
                .andExpect(method(HttpMethod.POST))
                .andExpect(jsonPath("$.invoice.channels[0]").value("orange-money-senegal"))
                .andRespond(withSuccess("""
                        {"response_code":"00","response_text":"https://app.paydunya.com/sandbox-checkout/invoice/test_PDY1",
                         "token":"test_PDY1"}""", MediaType.APPLICATION_JSON));
        // Toutes les réponses du serveur simulé sont déclarées avant le premier appel (contrainte de MockRestServiceServer).
        String[] ref = new String[1];
        serveurPayDunya.expect(requestTo("https://app.paydunya.com/sandbox-api/v1/checkout-invoice/confirm/test_PDY1"))
                .andRespond(requete -> withSuccess(confirmation("pending", ref[0]), MediaType.APPLICATION_JSON).createResponse(requete));
        serveurPayDunya.expect(requestTo("https://app.paydunya.com/sandbox-api/v1/checkout-invoice/confirm/test_PDY1"))
                .andRespond(requete -> withSuccess(confirmation("completed", ref[0]), MediaType.APPLICATION_JSON).createResponse(requete));
        String session = appel(post("/api/reservations/" + idResa + "/paiement").header("Authorization", passagere), "{}")
                .andExpect(status().isOk())
                .andExpect(org.springframework.test.web.servlet.result.MockMvcResultMatchers
                        .jsonPath("$.urlPaiement").value("https://app.paydunya.com/sandbox-checkout/invoice/test_PDY1"))
                .andReturn().getResponse().getContentAsString();
        String reference = JsonPath.read(session, "$.referenceTransaction");
        ref[0] = reference;

        // --- Retour du passager pendant que l'opérateur traite encore : en attente ; personne d'autre ne vérifie
        appel(post("/api/paiements/" + reference + "/verifier").header("Authorization", passagere), "")
                .andExpect(status().isOk())
                .andExpect(org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath("$.statut").value("EN_ATTENTE"));
        appel(post("/api/paiements/" + reference + "/verifier").header("Authorization", autre), "")
                .andExpect(status().isNotFound());

        // --- IPN : hash faux refusé ; hash correct -> état redemandé à PayDunya -> payé
        mvc.perform(post("/api/paiements/webhooks/paydunya").contentType(MediaType.APPLICATION_FORM_URLENCODED)
                        .param("data[hash]", "0".repeat(128)).param("data[invoice][token]", "test_PDY1")
                        .param("data[status]", "completed"))
                .andExpect(status().isUnauthorized());
        mvc.perform(post("/api/paiements/webhooks/paydunya").contentType(MediaType.APPLICATION_FORM_URLENCODED)
                        .param("data[hash]", sha512(CLE_PRINCIPALE)).param("data[invoice][token]", "test_PDY1")
                        .param("data[status]", "completed"))
                .andExpect(status().isOk());
        mvc.perform(get("/api/moi/paiements").header("Authorization", passagere))
                .andExpect(org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath("$[0].statut").value("REUSSI"))
                .andExpect(org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath("$[0].moyen").value("ORANGE_MONEY"));
        org.assertj.core.api.Assertions.assertThat(jdbc.queryForObject(
                "select fournisseur from paiement where reference_transaction = ?", String.class, reference)).isEqualTo("PAYDUNYA");

        // --- Annulation avant le départ : remboursement demandé (pas de déboursement en mode test)
        appel(post("/api/reservations/" + idResa + "/annuler").header("Authorization", passagere), "{}")
                .andExpect(status().isOk());
        mvc.perform(get("/api/moi/paiements").header("Authorization", passagere))
                .andExpect(org.springframework.test.web.servlet.result.MockMvcResultMatchers
                        .jsonPath("$[0].statut").value("REMBOURSEMENT_DEMANDE"));
        serveurPayDunya.verify();
    }

    private static String confirmation(String statut, String reference) {
        return """
                {"response_code":"00","response_text":"Transaction Found","status":"%s",
                 "invoice":{"token":"test_PDY1","total_amount":4700},"custom_data":{"reference":"%s"}}"""
                .formatted(statut, reference);
    }

    private static String sha512(String valeur) throws Exception {
        return HexFormat.of().formatHex(MessageDigest.getInstance("SHA-512").digest(valeur.getBytes(StandardCharsets.UTF_8)));
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
