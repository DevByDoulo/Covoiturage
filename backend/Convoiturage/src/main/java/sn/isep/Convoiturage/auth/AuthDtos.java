package sn.isep.Convoiturage.auth;

import com.fasterxml.jackson.annotation.JsonInclude;
import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;
import sn.isep.Convoiturage.common.AppProperties;
import sn.isep.Convoiturage.utilisateur.Sexe;
import sn.isep.Convoiturage.utilisateur.UtilisateurDtos.ProfilDto;

public final class AuthDtos {

    private AuthDtos() {}

    static final String REGLE_MDP = "^(?=.*[A-Za-z])(?=.*\\d).{8,72}$";
    static final String MESSAGE_MDP = "Le mot de passe doit contenir au moins 8 caractères, dont une lettre et un chiffre";

    public record InscriptionRequete(
            @NotBlank @Size(max = 80) String prenom,
            @NotBlank @Size(max = 80) String nom,
            @NotBlank @Email @Size(max = 160) String email,
            @NotBlank String telephone,
            @NotBlank @Pattern(regexp = REGLE_MDP, message = MESSAGE_MDP) String motDePasse,
            Sexe sexe) {}

    /** identifiant = numéro de téléphone (ou email du compte en attente de vérification). */
    public record VerificationOtpRequete(@NotBlank String identifiant, @NotBlank @Pattern(regexp = "\\d{4,8}") String code) {}

    /** identifiant = email ou numéro de téléphone. */
    public record ConnexionRequete(@NotBlank String identifiant, @NotBlank String motDePasse) {}

    /** Le téléphone est demandé au premier passage (comptes Google sans numéro vérifié). */
    public record GoogleRequete(@NotBlank String idToken, String telephone, Sexe sexe) {}

    public record RefreshRequete(@NotBlank String refreshToken) {}

    /** Email ou numéro de téléphone. */
    public record IdentifiantRequete(@NotBlank String identifiant) {}

    /** Utilisateur connecté. motDePasseActuel est ignoré (et peut être absent) pour un compte créé avec Google. */
    public record ChangementMotDePasseRequete(
            String motDePasseActuel,
            @NotBlank @Pattern(regexp = REGLE_MDP, message = MESSAGE_MDP) String nouveauMotDePasse) {}

    /** Confirmation de la désactivation par le mot de passe (sauf compte créé avec Google). */
    public record DesactivationRequete(String motDePasse) {}

    /** Code accepté : le jeton autorise le choix du nouveau mot de passe pendant validiteSecondes. */
    public record CodeVerifieReponse(String jeton, long validiteSecondes) {}

    public record ReinitialisationRequete(
            @NotBlank String jeton,
            @NotBlank @Pattern(regexp = REGLE_MDP, message = MESSAGE_MDP) String nouveauMotDePasse) {}

    public enum EtapeAuth {
        /** Jetons délivrés. */
        CONNECTE,
        /** Un code a été envoyé (par email ou SMS, voir canal) : appeler /api/auth/otp/verifier. */
        OTP_ENVOYE,
        /** Compte Google sans téléphone : renvoyer la requête avec le champ telephone. */
        TELEPHONE_REQUIS
    }

    /**
     * Réponse unique des endpoints d'authentification. Pour OTP_ENVOYE, l'interface affiche le canal
     * (EMAIL ou SMS), l'adresse ou le numéro masqué, le compte à rebours de validité du code et le délai
     * avant de pouvoir le renvoyer.
     */
    @JsonInclude(JsonInclude.Include.NON_NULL)
    public record AuthReponse(EtapeAuth etape, String accessToken, String refreshToken, Long expiresIn,
                              CanalOtp canal, String telephoneMasque, String emailMasque,
                              Integer otpValiditeSecondes, Integer renvoiPossibleDansSecondes,
                              ProfilDto utilisateur) {

        static AuthReponse connecte(TokenService.Jetons j, ProfilDto u) {
            return new AuthReponse(EtapeAuth.CONNECTE, j.accessToken(), j.refreshToken(), j.expiresIn(),
                    null, null, null, null, null, u);
        }

        static AuthReponse otpEnvoye(CanalOtp canal, String telephoneMasque, String emailMasque, AppProperties.Otp conf) {
            return new AuthReponse(EtapeAuth.OTP_ENVOYE, null, null, null, canal, telephoneMasque, emailMasque,
                    conf.validiteMinutes() * 60, conf.delaiRenvoiSecondes(), null);
        }

        static AuthReponse telephoneRequis() {
            return new AuthReponse(EtapeAuth.TELEPHONE_REQUIS, null, null, null, null, null, null, null, null, null);
        }
    }
}
