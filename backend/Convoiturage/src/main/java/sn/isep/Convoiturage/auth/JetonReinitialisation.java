package sn.isep.Convoiturage.auth;

import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;
import sn.isep.Convoiturage.utilisateur.Utilisateur;

import javax.crypto.Mac;
import javax.crypto.SecretKey;
import java.nio.charset.StandardCharsets;
import java.security.GeneralSecurityException;
import java.security.MessageDigest;
import java.time.Duration;
import java.time.Instant;
import java.util.Base64;
import java.util.Optional;

/**
 * Jeton remis après la vérification du code de « mot de passe oublié » : il autorise, pendant 10 minutes,
 * le choix du nouveau mot de passe sans redemander le code.
 * <p>
 * Format opaque {@code id.expiration.signature} (HMAC-SHA256 avec la clé des JWT) : ce n'est pas un JWT, il ne
 * peut donc pas servir de jeton d'accès. La signature inclut le hash du mot de passe actuel : le jeton devient
 * invalide dès que le mot de passe change, ce qui le rend à usage unique sans rien stocker en base.
 */
@Component
@RequiredArgsConstructor
class JetonReinitialisation {

    static final Duration VALIDITE = Duration.ofMinutes(10);
    private static final Base64.Encoder B64 = Base64.getUrlEncoder().withoutPadding();

    private final SecretKey cle;

    String emettre(Utilisateur u) {
        long expiration = Instant.now().plus(VALIDITE).getEpochSecond();
        return u.getId() + "." + expiration + "." + signer(u.getId(), expiration, u.getMotDePasse());
    }

    /** Identifiant du compte visé, si le jeton est bien formé et pas expiré (la signature est vérifiée par {@link #signatureValide}). */
    static Optional<Long> lireIdentifiant(String jeton) {
        String[] parties = jeton.split("\\.");
        if (parties.length != 3) return Optional.empty();
        try {
            long id = Long.parseLong(parties[0]);
            long expiration = Long.parseLong(parties[1]);
            return expiration < Instant.now().getEpochSecond() ? Optional.empty() : Optional.of(id);
        } catch (NumberFormatException e) {
            return Optional.empty();
        }
    }

    boolean signatureValide(String jeton, Utilisateur u) {
        String[] parties = jeton.split("\\.");
        String attendue = signer(u.getId(), Long.parseLong(parties[1]), u.getMotDePasse());
        return MessageDigest.isEqual(attendue.getBytes(StandardCharsets.US_ASCII), parties[2].getBytes(StandardCharsets.US_ASCII));
    }

    private String signer(Long id, long expiration, String motDePasseActuel) {
        try {
            Mac mac = Mac.getInstance("HmacSHA256");
            mac.init(cle);
            String donnees = "reinitialisation|" + id + "|" + expiration + "|" + (motDePasseActuel == null ? "" : motDePasseActuel);
            return B64.encodeToString(mac.doFinal(donnees.getBytes(StandardCharsets.UTF_8)));
        } catch (GeneralSecurityException e) {
            throw new IllegalStateException(e);
        }
    }
}
