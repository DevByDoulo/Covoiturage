package sn.isep.Convoiturage.auth;

import lombok.RequiredArgsConstructor;
import org.springframework.security.oauth2.jose.jws.MacAlgorithm;
import org.springframework.security.oauth2.jwt.JwsHeader;
import org.springframework.security.oauth2.jwt.JwtClaimsSet;
import org.springframework.security.oauth2.jwt.JwtEncoder;
import org.springframework.security.oauth2.jwt.JwtEncoderParameters;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import sn.isep.Convoiturage.common.ApiException;
import sn.isep.Convoiturage.common.AppProperties;
import sn.isep.Convoiturage.utilisateur.Utilisateur;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.security.SecureRandom;
import java.time.Instant;
import java.time.LocalDateTime;
import java.time.temporal.ChronoUnit;
import java.util.Base64;
import java.util.HexFormat;

/**
 * Jetons d'accès JWT (courte durée) et jetons de rafraîchissement opaques (longue durée,
 * stockés hachés, rotation à chaque utilisation, révocables).
 */
@Service
@RequiredArgsConstructor
public class TokenService {

    private static final SecureRandom RANDOM = new SecureRandom();

    private final JwtEncoder jwtEncoder;
    private final RefreshTokenRepository refreshTokens;
    private final AppProperties props;

    public record Jetons(String accessToken, String refreshToken, long expiresIn) {}

    @Transactional
    public Jetons emettre(Utilisateur u) {
        u.setDerniereConnexion(LocalDateTime.now());
        return new Jetons(genererAccessToken(u), creerRefreshToken(u), props.jwt().accessTokenMinutes() * 60);
    }

    /** Échange un refresh token valide contre une nouvelle paire ; l'ancien est révoqué. */
    @Transactional
    public Utilisateur consommerRefreshToken(String brut) {
        RefreshToken rt = refreshTokens.findByTokenHash(hash(brut))
                .orElseThrow(() -> ApiException.unauthorized("Session invalide, veuillez vous reconnecter"));
        if (rt.isRevoque()) {
            // Réutilisation d'un jeton déjà consommé : vol probable -> on coupe toutes les sessions.
            refreshTokens.revoquerTous(rt.getUtilisateur().getId());
            throw ApiException.unauthorized("Session invalide, veuillez vous reconnecter");
        }
        if (rt.getDateExpiration().isBefore(LocalDateTime.now())) {
            throw ApiException.unauthorized("Session expirée, veuillez vous reconnecter");
        }
        rt.setRevoque(true);
        return rt.getUtilisateur();
    }

    @Transactional
    public void revoquer(String brut) {
        refreshTokens.findByTokenHash(hash(brut)).ifPresent(rt -> rt.setRevoque(true));
    }

    @Transactional
    public void revoquerTous(Long utilisateurId) {
        refreshTokens.revoquerTous(utilisateurId);
    }

    private String genererAccessToken(Utilisateur u) {
        Instant maintenant = Instant.now();
        JwtClaimsSet claims = JwtClaimsSet.builder()
                .issuer(props.jwt().issuer())
                .subject(u.getId().toString())
                .issuedAt(maintenant)
                .expiresAt(maintenant.plus(props.jwt().accessTokenMinutes(), ChronoUnit.MINUTES))
                .claim("roles", u.autorites())
                .claim("prenom", u.getPrenom())
                .build();
        JwsHeader header = JwsHeader.with(MacAlgorithm.HS256).build();
        return jwtEncoder.encode(JwtEncoderParameters.from(header, claims)).getTokenValue();
    }

    private String creerRefreshToken(Utilisateur u) {
        byte[] octets = new byte[32];
        RANDOM.nextBytes(octets);
        String brut = Base64.getUrlEncoder().withoutPadding().encodeToString(octets);
        RefreshToken rt = new RefreshToken();
        rt.setUtilisateur(u);
        rt.setTokenHash(hash(brut));
        rt.setDateExpiration(LocalDateTime.now().plusDays(props.jwt().refreshTokenDays()));
        refreshTokens.save(rt);
        return brut;
    }

    static String hash(String valeur) {
        try {
            byte[] d = MessageDigest.getInstance("SHA-256").digest(valeur.getBytes(StandardCharsets.UTF_8));
            return HexFormat.of().formatHex(d);
        } catch (NoSuchAlgorithmException e) {
            throw new IllegalStateException(e);
        }
    }
}
