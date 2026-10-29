package sn.isep.Convoiturage.facturation;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import com.fasterxml.jackson.annotation.JsonInclude;
import com.fasterxml.jackson.annotation.JsonProperty;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.MediaType;
import org.springframework.http.client.SimpleClientHttpRequestFactory;
import org.springframework.stereotype.Component;
import org.springframework.web.client.RestClient;
import org.springframework.web.client.RestClientException;
import sn.isep.Convoiturage.facturation.FournisseurPaiement.ErreurFournisseur;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.time.Duration;
import java.util.HexFormat;
import java.util.List;
import java.util.Map;

/**
 * Appels à l'API HTTP/JSON de PayDunya (https://developers.paydunya.com/doc/FR/http_json) :
 * <ul>
 *   <li>« paiement avec redirection » : POST checkout-invoice/create, le passager ouvre l'adresse renvoyée ;</li>
 *   <li>état d'une facture : GET checkout-invoice/confirm/{token} (PENDING, COMPLETED, CANCELLED, FAILED) ;</li>
 *   <li>IPN : PayDunya poste {@code data[...]} (formulaire) avec {@code data[hash]} = SHA-512 de la clé principale ;</li>
 *   <li>remboursement par déboursement vers le portefeuille du passager (API PUSH, production uniquement).</li>
 * </ul>
 * En mode test, les adresses « sandbox-api » sont utilisées : aucun argent réel ne circule.
 */
@Component
public class PayDunyaClient {

    static final String URL_API = "https://app.paydunya.com";

    private final PaiementProperties props;
    private final RestClient client;

    @Autowired
    public PayDunyaClient(PaiementProperties props, RestClient.Builder builder) {
        this(props, construireClient(props, builder));
    }

    /** Client HTTP fourni de l'extérieur : utilisé par les tests (serveur PayDunya simulé). */
    public PayDunyaClient(PaiementProperties props, RestClient client) {
        this.props = props;
        this.client = client;
    }

    private static RestClient construireClient(PaiementProperties props, RestClient.Builder builder) {
        SimpleClientHttpRequestFactory http = new SimpleClientHttpRequestFactory();
        http.setConnectTimeout(Duration.ofSeconds(5));
        http.setReadTimeout(Duration.ofSeconds(20));
        return authentifier(builder, props).requestFactory(http).build();
    }

    /** Adresse de l'API et clés de l'application, envoyées à chaque appel (aussi utilisé par les tests). */
    public static RestClient.Builder authentifier(RestClient.Builder builder, PaiementProperties props) {
        PaiementProperties.PayDunya p = props.paydunya();
        return builder.baseUrl(URL_API)
                .defaultHeader("PAYDUNYA-MASTER-KEY", nonNul(p.masterKey()))
                .defaultHeader("PAYDUNYA-PRIVATE-KEY", nonNul(p.privateKey()))
                .defaultHeader("PAYDUNYA-TOKEN", nonNul(p.token()));
    }

    // ------------------------------------------------------------------ Modèle des échanges

    @JsonInclude(JsonInclude.Include.NON_NULL)
    record Facture(Invoice invoice, Store store, Map<String, String> custom_data, Actions actions) {}

    @JsonInclude(JsonInclude.Include.NON_NULL)
    record Invoice(@JsonProperty("total_amount") long totalAmount, String description, List<String> channels) {}

    record Store(String name, @JsonProperty("website_url") String websiteUrl) {}

    @JsonInclude(JsonInclude.Include.NON_NULL)
    record Actions(@JsonProperty("cancel_url") String cancelUrl, @JsonProperty("return_url") String returnUrl,
                   @JsonProperty("callback_url") String callbackUrl) {}

    @JsonIgnoreProperties(ignoreUnknown = true)
    record Reponse(@JsonProperty("response_code") String responseCode, @JsonProperty("response_text") String responseText,
                   String token, String status, String hash, InvoiceLue invoice,
                   @JsonProperty("custom_data") Map<String, Object> customData,
                   @JsonProperty("disburse_token") String disburseToken) {
        boolean succes() {
            return "00".equals(responseCode);
        }
    }

    @JsonIgnoreProperties(ignoreUnknown = true)
    record InvoiceLue(String token, @JsonProperty("total_amount") Object totalAmount) {}

    record Deboursement(@JsonProperty("account_alias") String compte, long amount,
                        @JsonProperty("withdraw_mode") String mode, @JsonProperty("callback_url") String callbackUrl) {}

    record Soumission(@JsonProperty("disburse_invoice") String facture, @JsonProperty("disburse_id") String reference) {}

    /** Facture créée : jeton PayDunya et adresse de la page de paiement. */
    record FactureCreee(String token, String url) {}

    // ------------------------------------------------------------------ Appels

    FactureCreee creerFacture(Facture facture) {
        Reponse r = appeler(() -> client.post().uri(prefixe() + "/checkout-invoice/create")
                .contentType(MediaType.APPLICATION_JSON).body(facture).retrieve().body(Reponse.class));
        if (r == null || !r.succes() || r.token() == null || r.responseText() == null || !r.responseText().startsWith("https://")) {
            throw new ErreurFournisseur("PayDunya a refusé la facture : " + (r == null ? "réponse vide" : r.responseText()));
        }
        return new FactureCreee(r.token(), r.responseText());
    }

    /** État d'une facture, revérifié auprès de PayDunya (on ne se fie jamais au seul contenu de l'IPN). */
    Reponse confirmer(String token) {
        Reponse r = appeler(() -> client.get().uri(prefixe() + "/checkout-invoice/confirm/{token}", token)
                .retrieve().body(Reponse.class));
        if (r == null || !r.succes()) {
            throw new ErreurFournisseur("Facture PayDunya introuvable : " + (r == null ? "réponse vide" : r.responseText()));
        }
        return r;
    }

    /**
     * Rembourse en envoyant le montant sur le portefeuille du passager (Wave ou Orange Money Sénégal).
     * Le déboursement n'existe qu'en production (aucune adresse de test documentée).
     */
    void debourser(String numeroLocal, long montant, String mode, String callbackUrl, String reference) {
        if (!props.paydunya().production()) {
            throw new ErreurFournisseur("Remboursement PayDunya impossible en mode test : à faire à la main depuis le tableau de bord");
        }
        Reponse facture = appeler(() -> client.post().uri("/api/v2/disburse/get-invoice")
                .contentType(MediaType.APPLICATION_JSON)
                .body(new Deboursement(numeroLocal, montant, mode, callbackUrl)).retrieve().body(Reponse.class));
        if (facture == null || !facture.succes() || facture.disburseToken() == null) {
            throw new ErreurFournisseur("PayDunya a refusé le remboursement : " + (facture == null ? "réponse vide" : facture.responseText()));
        }
        Reponse envoi = appeler(() -> client.post().uri("/api/v2/disburse/submit-invoice")
                .contentType(MediaType.APPLICATION_JSON)
                .body(new Soumission(facture.disburseToken(), reference)).retrieve().body(Reponse.class));
        if (envoi == null || "failed".equalsIgnoreCase(envoi.status())) {
            throw new ErreurFournisseur("Le remboursement PayDunya a échoué : " + (envoi == null ? "réponse vide" : envoi.responseText()));
        }
    }

    /** L'IPN vient bien de PayDunya : {@code data[hash]} est le SHA-512 (hexadécimal) de notre clé principale. */
    boolean hashValide(String hash) {
        String cle = props.paydunya().masterKey();
        if (hash == null || cle == null || cle.isBlank()) return false;
        try {
            byte[] attendu = MessageDigest.getInstance("SHA-512").digest(cle.getBytes(StandardCharsets.UTF_8));
            return MessageDigest.isEqual(attendu, HexFormat.of().parseHex(hash.trim().toLowerCase()));
        } catch (NoSuchAlgorithmException e) {
            throw new IllegalStateException(e);
        } catch (IllegalArgumentException e) {
            return false;
        }
    }

    private String prefixe() {
        return props.paydunya().production() ? "/api/v1" : "/sandbox-api/v1";
    }

    private static <T> T appeler(java.util.function.Supplier<T> appel) {
        try {
            return appel.get();
        } catch (RestClientException e) {
            throw new ErreurFournisseur("PayDunya ne répond pas", e);
        }
    }

    private static String nonNul(String valeur) {
        return valeur == null ? "" : valeur;
    }
}
