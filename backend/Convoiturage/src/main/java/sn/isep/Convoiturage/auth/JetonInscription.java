package sn.isep.Convoiturage.auth;

import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;

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
 * Jeton remis quand un numéro inconnu a prouvé qu'il le possède (code reçu par SMS) : il autorise, pendant 15 minutes,
 * la création du compte avec ce numéro, sans redemander le code. Rien n'est stocké en base.
 * <p>
 * Format opaque {@code numero.expiration.signature} (HMAC-SHA256 avec la clé des JWT) : ce n'est pas un JWT, il ne
 * peut donc pas servir de jeton d'accès, et la signature lie le jeton au numéro vérifié.
 */
@Component
@RequiredArgsConstructor
class JetonInscription {

    static final Duration VALIDITE = Duration.ofMinutes(15);
    private static final Base64.Encoder B64 = Base64.getUrlEncoder().withoutPadding();

    private final SecretKey cle;

    String emettre(String telephone) {
        long expiration = Instant.now().plus(VALIDITE).getEpochSecond();
        return B64.encodeToString(telephone.getBytes(StandardCharsets.UTF_8)) + "." + expiration + "."
                + signer(telephone, expiration);
    }

    /** Numéro vérifié contenu dans le jeton, si celui-ci est authentique et pas expiré. */
    Optional<String> lireTelephone(String jeton) {
        if (jeton == null) return Optional.empty();
        String[] parties = jeton.split("\\.");
        if (parties.length != 3) return Optional.empty();
        try {
            String telephone = new String(Base64.getUrlDecoder().decode(parties[0]), StandardCharsets.UTF_8);
            long expiration = Long.parseLong(parties[1]);
            if (expiration < Instant.now().getEpochSecond()) return Optional.empty();
            boolean valide = MessageDigest.isEqual(signer(telephone, expiration).getBytes(StandardCharsets.US_ASCII),
                    parties[2].getBytes(StandardCharsets.US_ASCII));
            return valide ? Optional.of(telephone) : Optional.empty();
        } catch (IllegalArgumentException e) {
            return Optional.empty();
        }
    }

    private String signer(String telephone, long expiration) {
        try {
            Mac mac = Mac.getInstance("HmacSHA256");
            mac.init(cle);
            String donnees = "inscription-telephone|" + telephone + "|" + expiration;
            return B64.encodeToString(mac.doFinal(donnees.getBytes(StandardCharsets.UTF_8)));
        } catch (GeneralSecurityException e) {
            throw new IllegalStateException(e);
        }
    }
}
