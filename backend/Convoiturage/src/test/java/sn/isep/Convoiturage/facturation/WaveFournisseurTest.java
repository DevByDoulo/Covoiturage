package sn.isep.Convoiturage.facturation;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.http.HttpMethod;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.test.web.client.MockRestServiceServer;
import org.springframework.web.client.RestClient;
import sn.isep.Convoiturage.facturation.FournisseurPaiement.ErreurFournisseur;
import sn.isep.Convoiturage.facturation.FournisseurPaiement.SessionPaiement;
import sn.isep.Convoiturage.reservation.MoyenPaiement;
import sn.isep.Convoiturage.reservation.Paiement;

import java.math.BigDecimal;
import java.time.Clock;
import java.time.Instant;
import java.time.ZoneOffset;
import java.util.HexFormat;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.springframework.test.web.client.match.MockRestRequestMatchers.*;
import static org.springframework.test.web.client.response.MockRestResponseCreators.withStatus;
import static org.springframework.test.web.client.response.MockRestResponseCreators.withSuccess;

/** API Checkout Wave simulée : création de session, remboursement et vérification des signatures de webhook. */
class WaveFournisseurTest {

    private static final String SECRET = "secret-webhook-test";
    private static final Instant MAINTENANT = Instant.parse("2026-11-02T08:00:00Z");
    private static final PaiementProperties PROPS = new PaiementProperties("https://yobalema.sn/",
            new PaiementProperties.Wave("wave_sn_test_cle", SECRET), null);

    private MockRestServiceServer serveur;
    private WaveFournisseur wave;

    @BeforeEach
    void preparer() {
        RestClient.Builder builder = RestClient.builder().baseUrl(WaveFournisseur.URL_API);
        serveur = MockRestServiceServer.bindTo(builder).build();
        wave = new WaveFournisseur(PROPS, builder.build(), Clock.fixed(MAINTENANT, ZoneOffset.UTC));
    }

    private static Paiement paiement() {
        Paiement p = new Paiement();
        p.setMontant(new BigDecimal("3300.00"));
        p.setMoyenPaiement(MoyenPaiement.WAVE);
        p.setReferenceTransaction("YBL-TEST0001");
        return p;
    }

    @Test
    void ouvreUneSessionDePaiement() {
        serveur.expect(requestTo("https://api.wave.com/v1/checkout/sessions"))
                .andExpect(method(HttpMethod.POST))
                .andExpect(jsonPath("$.amount").value("3300"))      // XOF : entier, sans décimales
                .andExpect(jsonPath("$.currency").value("XOF"))
                .andExpect(jsonPath("$.client_reference").value("YBL-TEST0001"))
                .andExpect(jsonPath("$.success_url").value("https://yobalema.sn/reservations?paiement=succes&ref=YBL-TEST0001"))
                .andExpect(jsonPath("$.error_url").value("https://yobalema.sn/reservations?paiement=echec&ref=YBL-TEST0001"))
                .andRespond(withSuccess("""
                        {"id":"cos-18qq","wave_launch_url":"https://pay.wave.com/c/cos-18qq","checkout_status":"open",
                         "payment_status":"processing","client_reference":"YBL-TEST0001","amount":"3300","currency":"XOF"}""",
                        MediaType.APPLICATION_JSON));

        SessionPaiement s = wave.ouvrirSession(paiement());

        serveur.verify();
        assertThat(s.referenceExterne()).isEqualTo("cos-18qq");
        assertThat(s.urlPaiement()).isEqualTo("https://pay.wave.com/c/cos-18qq");
    }

    @Test
    void signaleUneErreurDeWave() {
        serveur.expect(requestTo("https://api.wave.com/v1/checkout/sessions")).andRespond(withStatus(HttpStatus.UNAUTHORIZED));
        assertThatThrownBy(() -> wave.ouvrirSession(paiement())).isInstanceOf(ErreurFournisseur.class);
    }

    @Test
    void rembourseUneSession() {
        Paiement p = paiement();
        p.setReferenceExterne("cos-18qq");
        serveur.expect(requestTo("https://api.wave.com/v1/checkout/sessions/cos-18qq/refund"))
                .andExpect(method(HttpMethod.POST))
                .andRespond(withSuccess());

        wave.rembourser(p);
        serveur.verify();
    }

    @Test
    void verifieLaSignatureDesWebhooks() {
        String corps = "{\"id\":\"AE_1\",\"type\":\"checkout.session.completed\",\"data\":{}}";
        long t = MAINTENANT.getEpochSecond();

        assertThat(wave.signatureValide("t=" + t + ",v1=" + signer(t + corps), corps)).isTrue();
        // Plusieurs v1 pendant un changement de secret : une seule doit correspondre.
        assertThat(wave.signatureValide("t=" + t + ",v1=00ff,v1=" + signer(t + corps), corps)).isTrue();
        // Corps modifié, mauvais secret, en-tête absent ou mal formé.
        assertThat(wave.signatureValide("t=" + t + ",v1=" + signer(t + corps), corps + " ")).isFalse();
        assertThat(wave.signatureValide("t=" + t + ",v1=" + HexFormat.of().formatHex(WaveFournisseur.hmac("autre", t + corps)), corps)).isFalse();
        assertThat(wave.signatureValide(null, corps)).isFalse();
        assertThat(wave.signatureValide("v1=abc", corps)).isFalse();
        // Rejeu : signature de plus de 5 minutes.
        long ancien = t - 6 * 60;
        assertThat(wave.signatureValide("t=" + ancien + ",v1=" + signer(ancien + corps), corps)).isFalse();
    }

    @Test
    void indisponibleSansClesOuSansHttps() {
        assertThat(wave.disponible()).isTrue();
        assertThat(new WaveFournisseur(new PaiementProperties("https://yobalema.sn", null, null),
                RestClient.create(), Clock.systemUTC()).disponible()).isFalse();
        assertThat(new WaveFournisseur(new PaiementProperties("http://localhost:4200", PROPS.wave(), null),
                RestClient.create(), Clock.systemUTC()).disponible()).isFalse();
    }

    private static String signer(String donnees) {
        return HexFormat.of().formatHex(WaveFournisseur.hmac(SECRET, donnees));
    }
}
