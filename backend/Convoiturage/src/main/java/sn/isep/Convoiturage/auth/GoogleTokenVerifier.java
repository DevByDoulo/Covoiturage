package sn.isep.Convoiturage.auth;

import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Component;
import org.springframework.web.client.RestClient;
import org.springframework.web.client.RestClientException;
import sn.isep.Convoiturage.common.ApiException;
import sn.isep.Convoiturage.common.AppProperties;

import java.util.Set;

/**
 * Vérifie un idToken « Se connecter avec Google » auprès de Google (endpoint tokeninfo) :
 * signature, expiration, audience (notre client ID) et émetteur.
 */
@Component
public class GoogleTokenVerifier {

    private static final Set<String> EMETTEURS = Set.of("accounts.google.com", "https://accounts.google.com");

    private final RestClient client;
    private final AppProperties props;

    public GoogleTokenVerifier(RestClient.Builder builder, AppProperties props) {
        this.client = builder.baseUrl("https://oauth2.googleapis.com").build();
        this.props = props;
    }

    public record CompteGoogle(String sub, String email, boolean emailVerifie, String prenom, String nom) {}

    record TokenInfo(String sub, String email, String email_verified, String aud, String iss,
                     String given_name, String family_name) {}

    public CompteGoogle verifier(String idToken) {
        String clientId = props.google().clientId();
        if (clientId == null || clientId.isBlank()) {
            throw new ApiException(HttpStatus.SERVICE_UNAVAILABLE, "La connexion Google n'est pas configurée sur ce serveur");
        }
        TokenInfo info;
        try {
            info = client.get().uri(u -> u.path("/tokeninfo").queryParam("id_token", idToken).build())
                    .retrieve().body(TokenInfo.class);
        } catch (RestClientException e) {
            throw ApiException.unauthorized("Jeton Google invalide");
        }
        if (info == null || !clientId.equals(info.aud()) || !EMETTEURS.contains(info.iss())) {
            throw ApiException.unauthorized("Jeton Google invalide");
        }
        return new CompteGoogle(info.sub(), info.email(), "true".equals(info.email_verified()),
                info.given_name() != null ? info.given_name() : "Utilisateur",
                info.family_name() != null ? info.family_name() : "Google");
    }
}
