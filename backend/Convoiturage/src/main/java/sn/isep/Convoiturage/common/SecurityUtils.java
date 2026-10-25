package sn.isep.Convoiturage.common;

import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.oauth2.server.resource.authentication.JwtAuthenticationToken;

import java.util.Optional;

/** Accès à l'utilisateur authentifié (le « sub » du JWT est l'id_utilisateur). */
public final class SecurityUtils {

    private SecurityUtils() {}

    public static Long utilisateurCourantId() {
        return utilisateurCourantIdOptionnel()
                .orElseThrow(() -> ApiException.unauthorized("Authentification requise"));
    }

    public static Optional<Long> utilisateurCourantIdOptionnel() {
        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
        if (auth instanceof JwtAuthenticationToken jwt) {
            return Optional.of(Long.valueOf(jwt.getToken().getSubject()));
        }
        return Optional.empty();
    }

    public static boolean estAdmin() {
        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
        return auth != null && auth.getAuthorities().stream().anyMatch(a -> "ROLE_ADMIN".equals(a.getAuthority()));
    }
}
