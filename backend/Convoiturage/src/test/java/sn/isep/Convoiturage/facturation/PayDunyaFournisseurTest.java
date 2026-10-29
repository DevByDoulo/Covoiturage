package sn.isep.Convoiturage.facturation;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.http.HttpMethod;
import org.springframework.http.MediaType;
import org.springframework.test.web.client.MockRestServiceServer;
import org.springframework.web.client.RestClient;
import sn.isep.Convoiturage.facturation.FournisseurPaiement.ErreurFournisseur;
import sn.isep.Convoiturage.facturation.FournisseurPaiement.SessionPaiement;
import sn.isep.Convoiturage.reservation.MoyenPaiement;
import sn.isep.Convoiturage.reservation.Paiement;
import sn.isep.Convoiturage.reservation.Reservation;
import sn.isep.Convoiturage.reservation.StatutPaiement;
import sn.isep.Convoiturage.trajet.Trajet;
import sn.isep.Convoiturage.utilisateur.Utilisateur;

import java.math.BigDecimal;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.util.HexFormat;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.springframework.test.web.client.match.MockRestRequestMatchers.*;
import static org.springframework.test.web.client.response.MockRestResponseCreators.withSuccess;

/** API PayDunya simulée : facture (mode test), état, contrôle de l'IPN et remboursement. */
class PayDunyaFournisseurTest {

    private static final String CLE_PRINCIPALE = "cle-principale-de-test";
    private static final PaiementProperties PROPS_TEST = proprietes("test");

    private MockRestServiceServer serveur;

    private static PaiementProperties proprietes(String mode) {
        return new PaiementProperties("http://localhost:4200/", "https://api.yobalema.test", null, null,
                new PaiementProperties.PayDunya(CLE_PRINCIPALE, "test_private_cle", "jeton", mode));
    }

    private PayDunyaFournisseur fournisseur(MoyenPaiement moyen, PaiementProperties props) {
        RestClient.Builder builder = PayDunyaClient.authentifier(RestClient.builder(), props);
        serveur = MockRestServiceServer.bindTo(builder).build();
        return new PayDunyaFournisseur(moyen, new PayDunyaClient(props, builder.build()), props);
    }

    private static Paiement paiement(MoyenPaiement moyen) {
        Utilisateur passager = new Utilisateur();
        passager.setTelephone("+221771234567");
        Trajet t = new Trajet();
        t.setLieuDepart("Dakar");
        t.setLieuArrivee("Thiès");
        Reservation r = new Reservation();
        r.setTrajet(t);
        r.setPassager(passager);
        r.setNombrePlaces(2);
        Paiement p = new Paiement();
        p.setReservation(r);
        p.setMontant(new BigDecimal("4700.00"));
        p.setMoyenPaiement(moyen);
        p.setReferenceTransaction("YBL-TEST0002");
        return p;
    }

    @BeforeEach
    void preparer() {
        serveur = null;
    }

    @Test
    void creeUneFactureLimiteeAuCanalChoisi() {
        PayDunyaFournisseur om = fournisseur(MoyenPaiement.ORANGE_MONEY, PROPS_TEST);
        serveur.expect(requestTo("https://app.paydunya.com/sandbox-api/v1/checkout-invoice/create"))
                .andExpect(method(HttpMethod.POST))
                .andExpect(header("PAYDUNYA-MASTER-KEY", CLE_PRINCIPALE))
                .andExpect(header("PAYDUNYA-PRIVATE-KEY", "test_private_cle"))
                .andExpect(header("PAYDUNYA-TOKEN", "jeton"))
                .andExpect(jsonPath("$.invoice.total_amount").value(4700))
                .andExpect(jsonPath("$.invoice.channels[0]").value("orange-money-senegal"))
                .andExpect(jsonPath("$.invoice.description").value("Covoiturage Dakar → Thiès (2 places)"))
                .andExpect(jsonPath("$.store.name").value("YOBALEMAsn"))
                .andExpect(jsonPath("$.custom_data.reference").value("YBL-TEST0002"))
                .andExpect(jsonPath("$.actions.return_url").value("http://localhost:4200/reservations?paiement=succes&ref=YBL-TEST0002"))
                .andExpect(jsonPath("$.actions.cancel_url").value("http://localhost:4200/reservations?paiement=echec&ref=YBL-TEST0002"))
                .andExpect(jsonPath("$.actions.callback_url").value("https://api.yobalema.test/api/paiements/webhooks/paydunya"))
                .andRespond(withSuccess("""
                        {"response_code":"00","response_text":"https://app.paydunya.com/sandbox-checkout/invoice/test_ABC",
                         "description":"Checkout Invoice Created","token":"test_ABC"}""", MediaType.APPLICATION_JSON));

        SessionPaiement s = om.ouvrirSession(paiement(MoyenPaiement.ORANGE_MONEY));

        assertThat(s.referenceExterne()).isEqualTo("test_ABC");
        assertThat(s.urlPaiement()).isEqualTo("https://app.paydunya.com/sandbox-checkout/invoice/test_ABC");
        assertThat(om.nom()).isEqualTo("PAYDUNYA");
        assertThat(om.disponible()).isTrue();
        serveur.verify();
    }

    @Test
    void factureRefuseeParPayDunya() {
        PayDunyaFournisseur wave = fournisseur(MoyenPaiement.WAVE, PROPS_TEST);
        serveur.expect(requestTo("https://app.paydunya.com/sandbox-api/v1/checkout-invoice/create"))
                .andExpect(jsonPath("$.invoice.channels[0]").value("wave-senegal"))
                .andRespond(withSuccess("{\"response_code\":\"1001\",\"response_text\":\"Invalid Masterkey\"}",
                        MediaType.APPLICATION_JSON));
        assertThatThrownBy(() -> wave.ouvrirSession(paiement(MoyenPaiement.WAVE)))
                .isInstanceOf(ErreurFournisseur.class).hasMessageContaining("Invalid Masterkey");
    }

    @Test
    void lEtatVientDePayDunya() {
        PayDunyaFournisseur wave = fournisseur(MoyenPaiement.WAVE, PROPS_TEST);
        Paiement p = paiement(MoyenPaiement.WAVE);
        p.setReferenceExterne("test_ABC");
        for (String statut : new String[] {"pending", "completed", "cancelled", "failed"}) {
            serveur.expect(requestTo("https://app.paydunya.com/sandbox-api/v1/checkout-invoice/confirm/test_ABC"))
                    .andExpect(method(HttpMethod.GET))
                    .andRespond(withSuccess("""
                            {"response_code":"00","response_text":"Transaction Found","status":"%s",
                             "invoice":{"token":"test_ABC","total_amount":4700},"custom_data":{"reference":"YBL-TEST0002"}}"""
                            .formatted(statut), MediaType.APPLICATION_JSON));
        }
        assertThat(wave.verifier(p)).isEqualTo(StatutPaiement.EN_ATTENTE);
        assertThat(wave.verifier(p)).isEqualTo(StatutPaiement.REUSSI);
        assertThat(wave.verifier(p)).isEqualTo(StatutPaiement.ECHOUE);
        assertThat(wave.verifier(p)).isEqualTo(StatutPaiement.ECHOUE);
        serveur.verify();
    }

    @Test
    void factureDUnAutrePaiementIgnoree() {
        PayDunyaFournisseur wave = fournisseur(MoyenPaiement.WAVE, PROPS_TEST);
        Paiement p = paiement(MoyenPaiement.WAVE);
        p.setReferenceExterne("test_ABC");
        serveur.expect(requestTo("https://app.paydunya.com/sandbox-api/v1/checkout-invoice/confirm/test_ABC"))
                .andRespond(withSuccess("""
                        {"response_code":"00","status":"completed","custom_data":{"reference":"YBL-AUTRE"}}""",
                        MediaType.APPLICATION_JSON));
        assertThat(wave.verifier(p)).isNull();
    }

    @Test
    void hashDeLIpn() throws Exception {
        PayDunyaClient client = new PayDunyaClient(PROPS_TEST, RestClient.create());
        String attendu = HexFormat.of().formatHex(
                MessageDigest.getInstance("SHA-512").digest(CLE_PRINCIPALE.getBytes(StandardCharsets.UTF_8)));
        assertThat(client.hashValide(attendu)).isTrue();
        assertThat(client.hashValide(attendu.toUpperCase())).isTrue();
        assertThat(client.hashValide("00" + attendu.substring(2))).isFalse();
        assertThat(client.hashValide("pas-hexadecimal")).isFalse();
        assertThat(client.hashValide(null)).isFalse();
    }

    @Test
    void remboursementImpossibleEnModeTest() {
        PayDunyaFournisseur wave = fournisseur(MoyenPaiement.WAVE, PROPS_TEST);
        assertThatThrownBy(() -> wave.rembourser(paiement(MoyenPaiement.WAVE)))
                .isInstanceOf(ErreurFournisseur.class).hasMessageContaining("mode test");
    }

    @Test
    void remboursementParDeboursementEnProduction() {
        PayDunyaFournisseur om = fournisseur(MoyenPaiement.ORANGE_MONEY, proprietes("production"));
        serveur.expect(requestTo("https://app.paydunya.com/api/v2/disburse/get-invoice"))
                .andExpect(method(HttpMethod.POST))
                .andExpect(jsonPath("$.account_alias").value("771234567"))
                .andExpect(jsonPath("$.amount").value(4700))
                .andExpect(jsonPath("$.withdraw_mode").value("orange-money-senegal"))
                .andExpect(jsonPath("$.callback_url").value("https://api.yobalema.test/api/paiements/webhooks/paydunya"))
                .andRespond(withSuccess("{\"response_code\":\"00\",\"disburse_token\":\"DT123\"}", MediaType.APPLICATION_JSON));
        serveur.expect(requestTo("https://app.paydunya.com/api/v2/disburse/submit-invoice"))
                .andExpect(jsonPath("$.disburse_invoice").value("DT123"))
                .andExpect(jsonPath("$.disburse_id").value("YBL-TEST0002"))
                .andRespond(withSuccess("{\"response_code\":\"00\",\"status\":\"success\"}", MediaType.APPLICATION_JSON));

        om.rembourser(paiement(MoyenPaiement.ORANGE_MONEY));
        serveur.verify();
    }

    @Test
    void nonDisponibleSansCles() {
        PaiementProperties sansCles = new PaiementProperties("http://localhost:4200", null, null);
        assertThat(new PayDunyaFournisseur(MoyenPaiement.WAVE, new PayDunyaClient(sansCles, RestClient.create()), sansCles)
                .disponible()).isFalse();
    }
}
