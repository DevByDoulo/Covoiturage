package sn.isep.Convoiturage.facturation;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import com.fasterxml.jackson.annotation.JsonProperty;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.MediaType;
import org.springframework.http.client.SimpleClientHttpRequestFactory;
import org.springframework.stereotype.Component;
import org.springframework.web.client.RestClient;
import org.springframework.web.client.RestClientException;
import sn.isep.Convoiturage.reservation.MoyenPaiement;
import sn.isep.Convoiturage.reservation.Paiement;

import javax.crypto.Mac;
import javax.crypto.spec.SecretKeySpec;
import java.math.RoundingMode;
import java.nio.charset.StandardCharsets;
import java.security.GeneralSecurityException;
import java.security.MessageDigest;
import java.time.Clock;
import java.time.Duration;
import java.util.ArrayList;
import java.util.HexFormat;
import java.util.List;

/**
 * Wave Business — API Checkout (https://docs.wave.com/checkout) et webhooks (https://docs.wave.com/webhook).
 * <ul>
 *   <li>POST /v1/checkout/sessions : le passager ouvre {@code wave_launch_url} pour payer ;</li>
 *   <li>Wave appelle notre webhook ({@code checkout.session.completed} / {@code .payment_failed}),
 *       signé par l'en-tête {@code Wave-Signature: t=…,v1=…} (HMAC-SHA256 de « t + corps brut ») ;</li>
 *   <li>POST /v1/checkout/sessions/{id}/refund : remboursement intégral (idempotent).</li>
 * </ul>
 */
@Slf4j
@Component
public class WaveFournisseur implements FournisseurPaiement {

    static final String URL_API = "https://api.wave.com";
    /** Wave rejette les signatures de plus de 5 minutes (rejeu). */
    static final Duration TOLERANCE_SIGNATURE = Duration.ofMinutes(5);

    private final PaiementProperties props;
    private final RestClient client;
    private final Clock horloge;

    @Autowired
    public WaveFournisseur(PaiementProperties props, RestClient.Builder builder) {
        this(props, construireClient(props, builder), Clock.systemUTC());
    }

    /** Client HTTP fourni de l'extérieur : utilisé par les tests (serveur Wave simulé). */
    public WaveFournisseur(PaiementProperties props, RestClient client, Clock horloge) {
        this.props = props;
        this.client = client;
        this.horloge = horloge;
    }

    private static RestClient construireClient(PaiementProperties props, RestClient.Builder builder) {
        SimpleClientHttpRequestFactory http = new SimpleClientHttpRequestFactory();
        http.setConnectTimeout(Duration.ofSeconds(5));
        http.setReadTimeout(Duration.ofSeconds(15));
        return builder.baseUrl(URL_API)
                .defaultHeader("Authorization", "Bearer " + props.wave().apiKey())
                .requestFactory(http)
                .build();
    }

    record CreationSession(String amount, String currency,
                           @JsonProperty("success_url") String successUrl,
                           @JsonProperty("error_url") String errorUrl,
                           @JsonProperty("client_reference") String clientReference) {}

    @JsonIgnoreProperties(ignoreUnknown = true)
    record Session(String id, @JsonProperty("wave_launch_url") String waveLaunchUrl,
                   @JsonProperty("checkout_status") String checkoutStatus,
                   @JsonProperty("payment_status") String paymentStatus,
                   @JsonProperty("client_reference") String clientReference,
                   @JsonProperty("transaction_id") String transactionId) {}

    /** Événement reçu sur le webhook ; {@code data} est la session de paiement. */
    @JsonIgnoreProperties(ignoreUnknown = true)
    record Evenement(String id, String type, Session data) {}

    @Override
    public MoyenPaiement moyen() {
        return MoyenPaiement.WAVE;
    }

    @Override
    public boolean disponible() {
        // Wave exige des adresses de retour en HTTPS.
        return props.wave().configure() && props.urlRetour() != null && props.urlRetour().startsWith("https://");
    }

    @Override
    public SessionPaiement ouvrirSession(Paiement p) {
        if (!disponible()) throw new ErreurFournisseur("Wave n'est pas configuré sur ce serveur");
        String retour = props.urlRetour().replaceAll("/+$", "") + "/reservations?paiement=";
        CreationSession corps = new CreationSession(
                p.getMontant().setScale(0, RoundingMode.HALF_UP).toPlainString(), "XOF",
                retour + "succes&ref=" + p.getReferenceTransaction(),
                retour + "echec&ref=" + p.getReferenceTransaction(),
                p.getReferenceTransaction());
        try {
            Session s = client.post().uri("/v1/checkout/sessions")
                    .contentType(MediaType.APPLICATION_JSON)
                    .body(corps)
                    .retrieve()
                    .body(Session.class);
            if (s == null || s.id() == null || s.waveLaunchUrl() == null) {
                throw new ErreurFournisseur("Réponse Wave incomplète");
            }
            return new SessionPaiement(s.id(), s.waveLaunchUrl());
        } catch (RestClientException e) {
            throw new ErreurFournisseur("Wave n'a pas pu créer la session de paiement", e);
        }
    }

    @Override
    public void rembourser(Paiement p) {
        if (p.getReferenceExterne() == null) throw new ErreurFournisseur("Session Wave inconnue pour " + p.getReferenceTransaction());
        try {
            client.post().uri("/v1/checkout/sessions/{id}/refund", p.getReferenceExterne()).retrieve().toBodilessEntity();
        } catch (RestClientException e) {
            throw new ErreurFournisseur("Wave a refusé ou n'a pas traité le remboursement", e);
        }
    }

    /**
     * Vérifie l'en-tête {@code Wave-Signature} d'un webhook : HMAC-SHA256 (clé = secret du webhook) de
     * « horodatage + corps brut », comparé à chacune des valeurs v1 (plusieurs pendant un changement de secret).
     */
    boolean signatureValide(String entete, String corpsBrut) {
        if (entete == null || corpsBrut == null || !props.wave().configure()) return false;
        String horodatage = null;
        List<String> signatures = new ArrayList<>();
        for (String partie : entete.split(",")) {
            String[] cleValeur = partie.trim().split("=", 2);
            if (cleValeur.length != 2) continue;
            if (cleValeur[0].equals("t")) horodatage = cleValeur[1];
            else if (cleValeur[0].equals("v1")) signatures.add(cleValeur[1]);
        }
        if (horodatage == null || signatures.isEmpty()) return false;
        try {
            long ecart = Math.abs(horloge.instant().getEpochSecond() - Long.parseLong(horodatage));
            if (ecart > TOLERANCE_SIGNATURE.toSeconds()) return false;
        } catch (NumberFormatException e) {
            return false;
        }
        byte[] attendue = hmac(props.wave().secretWebhook(), horodatage + corpsBrut);
        for (String s : signatures) {
            try {
                if (MessageDigest.isEqual(attendue, HexFormat.of().parseHex(s))) return true;
            } catch (IllegalArgumentException ignoree) {
                // valeur v1 mal formée : on essaie la suivante
            }
        }
        return false;
    }

    static byte[] hmac(String secret, String donnees) {
        try {
            Mac mac = Mac.getInstance("HmacSHA256");
            mac.init(new SecretKeySpec(secret.getBytes(StandardCharsets.UTF_8), "HmacSHA256"));
            return mac.doFinal(donnees.getBytes(StandardCharsets.UTF_8));
        } catch (GeneralSecurityException e) {
            throw new IllegalStateException(e);
        }
    }
}
