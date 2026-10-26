package sn.isep.Convoiturage.auth;

import lombok.RequiredArgsConstructor;
import org.springframework.context.ApplicationEventPublisher;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Propagation;
import org.springframework.transaction.annotation.Transactional;
import sn.isep.Convoiturage.common.ApiException;
import sn.isep.Convoiturage.common.AppProperties;

import java.security.SecureRandom;
import java.time.Duration;
import java.time.LocalDateTime;

/**
 * Codes à usage unique : 6 chiffres, valables 5 minutes, 5 essais maximum, un renvoi au plus
 * toutes les 60 secondes, et un nombre limité de codes par heure et par jour (contre la recherche du code
 * par essais successifs et l'envoi massif de SMS). Seul le hash BCrypt du code est conservé. Le code est
 * rattaché au numéro du compte ; il part par email si un serveur SMTP est configuré et que le compte a
 * un email, sinon par SMS. L'email est envoyé en arrière-plan après validation de la transaction
 * ({@link ExpediteurEmails}).
 */
@Service
@RequiredArgsConstructor
public class OtpService {

    private static final SecureRandom RANDOM = new SecureRandom();

    /** Motifs joints aux refus 429, pour que l'interface sache si un code déjà envoyé reste utilisable. */
    static final String MOTIF_DELAI_RENVOI = "DELAI_RENVOI";
    static final String MOTIF_QUOTA = "QUOTA_CODES";

    private final OtpCodeRepository otps;
    private final PasswordEncoder encoder;
    private final SmsSender sms;
    private final EmailSender emails;
    private final ApplicationEventPublisher evenements;
    private final AppProperties props;

    /** Canal utilisé pour un compte ayant cet email (null si le compte n'en a pas). */
    public CanalOtp canalPour(String email) {
        return email != null && !email.isBlank() && emails.disponible() ? CanalOtp.EMAIL : CanalOtp.SMS;
    }

    @Transactional
    public CanalOtp envoyer(String telephone, String email, ObjetOtp objet) {
        CanalOtp canal = canalPour(email);
        String code = creer(telephone, objet, canal);

        AppProperties.Otp conf = props.otp();
        String texte = "YOBALEMAsn : votre code de vérification est " + code
                + ". Il expire dans " + conf.validiteMinutes() + " minutes. Ne le partagez avec personne.";
        if (canal == CanalOtp.EMAIL) {
            String sujet = objet == ObjetOtp.REINITIALISATION_MOT_DE_PASSE
                    ? "YOBALEMAsn - Réinitialisation de votre mot de passe"
                    : "YOBALEMAsn - Votre code de vérification";
            // Envoi en arrière-plan après validation : la réponse HTTP n'attend pas le serveur SMTP.
            evenements.publishEvent(new ExpediteurEmails.EmailAEnvoyer(email, sujet,
                    texte + "\n\nSi vous n'êtes pas à l'origine de cette demande, ignorez cet email."));
        } else {
            sms.envoyer(telephone, texte);
        }
        return canal;
    }

    /**
     * Comme {@link #envoyer}, mais le code n'est envoyé à personne : utilisé pour les comptes inexistants,
     * afin que délais, quotas, essais et temps de réponse soient exactement ceux d'un vrai compte.
     */
    @Transactional
    public void simulerEnvoi(String cle, ObjetOtp objet, CanalOtp canal) {
        creer(cle, objet, canal);
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

    /** Applique délai de renvoi et quotas, invalide le code précédent et enregistre le nouveau (haché). */
    private String creer(String telephone, ObjetOtp objet, CanalOtp canal) {
        AppProperties.Otp conf = props.otp();
        LocalDateTime maintenant = LocalDateTime.now();
        otps.findFirstByTelephoneAndObjetOrderByDateCreationDesc(telephone, objet).ifPresent(dernier -> {
            LocalDateTime renvoiPossible = dernier.getDateCreation().plusSeconds(conf.delaiRenvoiSecondes());
            if (renvoiPossible.isAfter(maintenant)) {
                long attente = Math.max(1, Duration.between(maintenant, renvoiPossible).toSeconds());
                throw ApiException.tooManyRequests("Veuillez patienter " + attente + " s avant de demander un nouveau code")
                        .avec("reessayerDansSecondes", attente).avec("motif", MOTIF_DELAI_RENVOI);
            }
        });
        verifierQuota(telephone, objet, conf.maxCodesParHeure(), Duration.ofHours(1), maintenant);
        verifierQuota(telephone, objet, conf.maxCodesParJour(), Duration.ofDays(1), maintenant);
        otps.findFirstByTelephoneAndObjetOrderByDateCreationDesc(telephone, objet).ifPresent(dernier -> dernier.setUtilise(true));

        String code = genererCode(conf.longueur());
        OtpCode otp = new OtpCode();
        otp.setTelephone(telephone);
        otp.setObjet(objet);
        otp.setCanal(canal);
        otp.setCodeHash(encoder.encode(code));
        otp.setDateExpiration(maintenant.plusMinutes(conf.validiteMinutes()));
        otps.save(otp);
        return code;
    }

    private void verifierQuota(String telephone, ObjetOtp objet, int max, Duration fenetre, LocalDateTime maintenant) {
        LocalDateTime debut = maintenant.minus(fenetre);
        if (otps.countByTelephoneAndObjetAndDateCreationAfter(telephone, objet, debut) < max) return;
        // Un nouveau code sera possible quand le plus ancien de la fenêtre en sortira.
        LocalDateTime possible = otps.findFirstByTelephoneAndObjetAndDateCreationAfterOrderByDateCreationAsc(telephone, objet, debut)
                .map(o -> o.getDateCreation().plus(fenetre))
                .orElse(maintenant.plus(fenetre));
        long secondes = Math.max(1, Duration.between(maintenant, possible).toSeconds());
        throw ApiException.tooManyRequests("Trop de codes demandés. Réessayez dans " + enClair(secondes) + ".")
                .avec("reessayerDansSecondes", secondes).avec("motif", MOTIF_QUOTA);
    }

    /** 125 s → « 3 minutes » ; 7 200 s → « 2 heures ». */
    private static String enClair(long secondes) {
        if (secondes > 3600) {
            long heures = (secondes + 3599) / 3600;
            return heures + " heure" + (heures > 1 ? "s" : "");
        }
        long minutes = (secondes + 59) / 60;
        return minutes + " minute" + (minutes > 1 ? "s" : "");
    }

    private static String genererCode(int longueur) {
        StringBuilder sb = new StringBuilder(longueur);
        for (int i = 0; i < longueur; i++) sb.append(RANDOM.nextInt(10));
        return sb.toString();
    }
}
