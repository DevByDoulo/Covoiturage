package sn.isep.Convoiturage.common;

import org.springframework.boot.context.properties.ConfigurationProperties;

import java.time.Duration;
import java.util.List;

/** Propriétés applicatives (préfixe {@code app} dans application.yaml). */
@ConfigurationProperties("app")
public record AppProperties(Jwt jwt, Otp otp, Cors cors, Stockage stockage, Google google, Admin admin, Ia ia) {

    public record Jwt(String secret, String issuer, long accessTokenMinutes, long refreshTokenDays) {}

    public record Otp(int longueur, int validiteMinutes, int tentativesMax, int delaiRenvoiSecondes,
                      int maxCodesParHeure, int maxCodesParJour) {}

    public record Cors(List<String> allowedOrigins) {}

    public record Stockage(String repertoire) {}

    public record Google(String clientId) {}

    public record Admin(String email, String motDePasse, String telephone) {}

    /** Service ia-tarification (FastAPI). URL vide : formule seule. */
    public record Ia(String url, Duration delai) {}
}
