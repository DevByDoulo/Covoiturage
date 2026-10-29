package sn.isep.Convoiturage.facturation;

import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.boot.context.properties.bind.ConstructorBinding;

/**
 * Configuration des paiements en ligne (préfixe {@code app.paiement}). Un fournisseur sans clé est désactivé :
 * les passagers ne peuvent alors payer qu'en espèces.
 *
 * @param urlRetour adresse de l'application web où le fournisseur renvoie le passager après paiement
 *                  (Wave exige HTTPS : en local, passer par un tunnel, voir le README du backend)
 * @param urlApi    adresse publique de l'API, pour les notifications des fournisseurs (IPN PayDunya) ; facultative :
 *                  sans elle, le paiement est vérifié au retour du passager
 */
@ConfigurationProperties("app.paiement")
public record PaiementProperties(String urlRetour, String urlApi, Wave wave, OrangeMoney orangeMoney, PayDunya paydunya) {

    /** Constructeur lu par Spring (il y en a deux). */
    @ConstructorBinding
    public PaiementProperties {
    }

    /** Sans PayDunya ni adresse publique de l'API (tests du module Wave). */
    public PaiementProperties(String urlRetour, Wave wave, OrangeMoney orangeMoney) {
        this(urlRetour, null, wave, orangeMoney, null);
    }

    /** Wave Business : clé API (« wave_sn_prod_… ») et secret de signature des webhooks. */
    public record Wave(String apiKey, String secretWebhook) {
        boolean configure() {
            return apiKey != null && !apiKey.isBlank() && secretWebhook != null && !secretWebhook.isBlank();
        }
    }

    /** Orange Money (Sonatel) : identifiants de l'application créée sur le portail développeur Sonatel. */
    public record OrangeMoney(String clientId, String clientSecret, String codeMarchand) {
        boolean configure() {
            return clientId != null && !clientId.isBlank() && clientSecret != null && !clientSecret.isBlank();
        }
    }

    /**
     * PayDunya (agrégateur : Wave et Orange Money Sénégal) : clé principale, clé privée et jeton de l'application
     * créée dans le tableau de bord PayDunya. {@code mode} : {@code test} (sandbox, aucun argent réel) ou
     * {@code production}. La clé privée de test commence par « test_private_ ».
     */
    public record PayDunya(String masterKey, String privateKey, String token, String mode) {
        boolean configure() {
            return masterKey != null && !masterKey.isBlank() && privateKey != null && !privateKey.isBlank()
                    && token != null && !token.isBlank();
        }

        boolean production() {
            return "production".equalsIgnoreCase(mode);
        }
    }

    public Wave wave() {
        return wave != null ? wave : new Wave(null, null);
    }

    public OrangeMoney orangeMoney() {
        return orangeMoney != null ? orangeMoney : new OrangeMoney(null, null, null);
    }

    public PayDunya paydunya() {
        return paydunya != null ? paydunya : new PayDunya(null, null, null, "test");
    }
}
