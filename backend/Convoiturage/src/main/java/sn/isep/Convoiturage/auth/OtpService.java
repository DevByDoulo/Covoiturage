package sn.isep.Convoiturage.auth;

import lombok.RequiredArgsConstructor;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Propagation;
import org.springframework.transaction.annotation.Transactional;
import sn.isep.Convoiturage.common.ApiException;
import sn.isep.Convoiturage.common.AppProperties;

import java.security.SecureRandom;
import java.time.LocalDateTime;

/**
 * Codes à usage unique : 6 chiffres, valables 5 minutes, 5 essais maximum, un renvoi au plus
 * toutes les 60 secondes. Seul le hash BCrypt du code est conservé. Le code est rattaché au numéro
 * du compte ; il part par email si un serveur SMTP est configuré et que le compte a un email, sinon par SMS.
 */
@Service
@RequiredArgsConstructor
public class OtpService {

    private static final SecureRandom RANDOM = new SecureRandom();

    private final OtpCodeRepository otps;
    private final PasswordEncoder encoder;
    private final SmsSender sms;
    private final EmailSender emails;
    private final AppProperties props;

    /** Canal utilisé pour un compte ayant cet email (null si le compte n'en a pas). */
    public CanalOtp canalPour(String email) {
        return email != null && !email.isBlank() && emails.disponible() ? CanalOtp.EMAIL : CanalOtp.SMS;
    }

    @Transactional
    public CanalOtp envoyer(String telephone, String email, ObjetOtp objet) {
        AppProperties.Otp conf = props.otp();
        otps.findFirstByTelephoneAndObjetOrderByDateCreationDesc(telephone, objet).ifPresent(dernier -> {
            LocalDateTime renvoiPossible = dernier.getDateCreation().plusSeconds(conf.delaiRenvoiSecondes());
            if (renvoiPossible.isAfter(LocalDateTime.now())) {
                long attente = Math.max(1, java.time.Duration.between(LocalDateTime.now(), renvoiPossible).toSeconds());
                throw ApiException.tooManyRequests("Veuillez patienter " + attente + " s avant de demander un nouveau code")
                        .avec("reessayerDansSecondes", attente);
            }
            dernier.setUtilise(true);
        });
        String code = genererCode(conf.longueur());
        CanalOtp canal = canalPour(email);
        OtpCode otp = new OtpCode();
        otp.setTelephone(telephone);
        otp.setObjet(objet);
        otp.setCanal(canal);
        otp.setCodeHash(encoder.encode(code));
        otp.setDateExpiration(LocalDateTime.now().plusMinutes(conf.validiteMinutes()));
        otps.save(otp);

        String texte = "YOBALEMAsn : votre code de vérification est " + code
                + ". Il expire dans " + conf.validiteMinutes() + " minutes. Ne le partagez avec personne.";
        if (canal == CanalOtp.EMAIL) {
            String sujet = objet == ObjetOtp.REINITIALISATION_MOT_DE_PASSE
                    ? "YOBALEMAsn - Réinitialisation de votre mot de passe"
                    : "YOBALEMAsn - Votre code de vérification";
            emails.envoyer(email, sujet, texte + "\n\nSi vous n'êtes pas à l'origine de cette demande, ignorez cet email.");
        } else {
            sms.envoyer(telephone, texte);
        }
        return canal;
    }

    /**
     * Vérifie le code et le consomme. Les tentatives échouées sont enregistrées même si
     * la transaction appelante est annulée (REQUIRES_NEW).
     *
     * @return le canal par lequel le code avait été envoyé : sa saisie prouve la possession de
     *         l'adresse email (EMAIL) ou du numéro (SMS), pas des deux.
     */
    @Transactional(propagation = Propagation.REQUIRES_NEW, noRollbackFor = ApiException.class)
    public CanalOtp verifier(String telephone, ObjetOtp objet, String code) {
        OtpCode otp = otps.findFirstByTelephoneAndObjetOrderByDateCreationDesc(telephone, objet)
                .filter(o -> !o.isUtilise())
                .orElseThrow(() -> ApiException.badRequest("Aucun code en attente pour ce numéro. Demandez un nouveau code."));
        if (otp.getDateExpiration().isBefore(LocalDateTime.now())) {
            throw ApiException.badRequest("Ce code a expiré. Demandez un nouveau code.");
        }
        if (otp.getTentatives() >= props.otp().tentativesMax()) {
            throw ApiException.tooManyRequests("Trop de tentatives. Demandez un nouveau code.");
        }
        otp.setTentatives(otp.getTentatives() + 1);
        if (code == null || !encoder.matches(code, otp.getCodeHash())) {
            int restantes = props.otp().tentativesMax() - otp.getTentatives();
            String suite = restantes > 0
                    ? "Il vous reste " + restantes + " tentative" + (restantes > 1 ? "s" : "") + "."
                    : "Demandez un nouveau code.";
            throw ApiException.badRequest("Code incorrect. " + suite).avec("tentativesRestantes", restantes);
        }
        otp.setUtilise(true);
        return otp.getCanal();
    }

    private static String genererCode(int longueur) {
        StringBuilder sb = new StringBuilder(longueur);
        for (int i = 0; i < longueur; i++) sb.append(RANDOM.nextInt(10));
        return sb.toString();
    }
}
