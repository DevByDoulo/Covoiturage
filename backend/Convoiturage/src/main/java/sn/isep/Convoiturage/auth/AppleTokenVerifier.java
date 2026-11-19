package sn.isep.Convoiturage.auth;

import org.springframework.http.HttpStatus;
import org.springframework.security.oauth2.jose.jws.SignatureAlgorithm;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.security.oauth2.jwt.JwtDecoder;
import org.springframework.security.oauth2.jwt.JwtException;
import org.springframework.security.oauth2.jwt.JwtValidators;
import org.springframework.security.oauth2.jwt.NimbusJwtDecoder;
import org.springframework.stereotype.Component;
import sn.isep.Convoiturage.common.ApiException;
import sn.isep.Convoiturage.common.AppProperties;

import java.util.List;

/**
 * Vérifie un identityToken « Se connecter avec Apple » : signature RS256 avec les clés publiques d'Apple
 * (https://appleid.apple.com/auth/keys, mises en cache par Nimbus), émetteur, expiration et audience
 * (un de nos identifiants Apple : Services ID du site, et plus tard bundle ID de l'appli iOS).
 * Apple ne met pas le nom dans le jeton : le site le transmet à part, au premier accès seulement.
 */
@Component
public class AppleTokenVerifier {

    static final String EMETTEUR = "https://appleid.apple.com";
    private static final String CLES = "https://appleid.apple.com/auth/keys";

    private final AppProperties props;
    private volatile JwtDecoder decodeur;

    public AppleTokenVerifier(AppProperties props) {
        this.props = props;
    }

    /** email : adresse réelle ou relais privé Apple (…@privaterelay.appleid.com) ; null si non partagée. */
    public record CompteApple(String sub, String email, boolean emailVerifie) {}

    public CompteApple verifier(String idToken) {
        List<String> clients = identifiantsClients();
        if (clients.isEmpty()) {
            throw new ApiException(HttpStatus.SERVICE_UNAVAILABLE, "La connexion Apple n'est pas configurée sur ce serveur");
        }
        Jwt jwt;
        try {
            jwt = decodeur().decode(idToken);
        } catch (JwtException e) {
            throw ApiException.unauthorized("Jeton Apple invalide");
        }
        if (jwt.getSubject() == null || jwt.getAudience() == null || jwt.getAudience().stream().noneMatch(clients::contains)) {
            throw ApiException.unauthorized("Jeton Apple invalide");
        }
        Object verifie = jwt.getClaims().get("email_verified");
        // Apple envoie selon les cas un booléen ou la chaîne « true ».
        boolean emailVerifie = Boolean.TRUE.equals(verifie) || "true".equals(verifie);
        return new CompteApple(jwt.getSubject(), jwt.getClaimAsString("email"), emailVerifie);
    }

    List<String> identifiantsClients() {
        AppProperties.Apple apple = props.apple();
        if (apple == null || apple.clientIds() == null) return List.of();
        return apple.clientIds().stream().filter(id -> id != null && !id.isBlank()).map(String::trim).toList();
    }

    private JwtDecoder decodeur() {
        if (decodeur == null) {
            NimbusJwtDecoder d = NimbusJwtDecoder.withJwkSetUri(CLES).jwsAlgorithm(SignatureAlgorithm.RS256).build();
            d.setJwtValidator(JwtValidators.createDefaultWithIssuer(EMETTEUR));
            decodeur = d;
        }
        return decodeur;
    }
}
