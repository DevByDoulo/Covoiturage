package sn.isep.Convoiturage.facturation;

import org.springframework.boot.context.properties.ConfigurationProperties;

/**
 * Configuration des paiements en ligne (préfixe {@code app.paiement}). Un fournisseur sans clé est désactivé :
 * les passagers ne peuvent alors payer qu'en espèces.
 *
 * @param urlRetour adresse HTTPS de l'application web où le fournisseur renvoie le passager après paiement
 *                  (Wave exige HTTPS : en local, passer par un tunnel, voir le README du backend)
 */
@ConfigurationProperties("app.paiement")
public record PaiementProperties(String urlRetour, Wave wave, OrangeMoney orangeMoney) {

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

    public Wave wave() {
        return wave != null ? wave : new Wave(null, null);
    }

    public OrangeMoney orangeMoney() {
        return orangeMoney != null ? orangeMoney : new OrangeMoney(null, null, null);
    }
}
