package sn.isep.Convoiturage.common;

import org.springframework.boot.context.properties.ConfigurationProperties;

import java.util.List;

/** Propriétés applicatives (préfixe {@code app} dans application.yaml). */
@ConfigurationProperties("app")
public record AppProperties(Jwt jwt, Otp otp, Cors cors, Stockage stockage, Google google,
                            Firebase firebase, Admin admin) {

    public record Jwt(String secret, String issuer, long accessTokenMinutes, long refreshTokenDays) {}

    public record Otp(int longueur, int validiteMinutes, int tentativesMax, int delaiRenvoiSecondes) {}

    public record Cors(List<String> allowedOrigins) {}

    public record Stockage(String repertoire) {}

    public record Google(String clientId, String mapsApiKey) {}

    public record Firebase(String credentialsPath) {}

    public record Admin(String email, String motDePasse, String telephone) {}
}
