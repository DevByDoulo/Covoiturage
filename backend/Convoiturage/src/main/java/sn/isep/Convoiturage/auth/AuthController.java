package sn.isep.Convoiturage.auth;

import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import sn.isep.Convoiturage.auth.AuthDtos.*;

@RestController
@RequestMapping("/api/auth")
@RequiredArgsConstructor
public class AuthController {

    private final AuthService auth;
    private final LimiteurParIp limiteurIp;

    @PostMapping("/inscription")
    @ResponseStatus(HttpStatus.CREATED)
    public AuthReponse inscrire(@Valid @RequestBody InscriptionRequete req) {
        return auth.inscrire(req);
    }

    @PostMapping("/otp/verifier")
    public AuthReponse verifierOtp(@Valid @RequestBody VerificationOtpRequete req) {
        return auth.verifierOtp(req);
    }

    @PostMapping("/otp/renvoyer")
    public AuthReponse renvoyerOtp(@Valid @RequestBody IdentifiantRequete req) {
        return auth.renvoyerOtp(req);
    }

    @PostMapping("/connexion")
    public AuthReponse connecter(@Valid @RequestBody ConnexionRequete req) {
        return auth.connecter(req);
    }

    /** Connexion ou inscription par téléphone, étape 1 : code envoyé par SMS. */
    @PostMapping("/telephone/code")
    public AuthReponse codeTelephone(@Valid @RequestBody TelephoneRequete req, HttpServletRequest http) {
        limiteurIp.consommer(LimiteurParIp.Action.DEMANDE_CODE, http.getRemoteAddr());
        return auth.envoyerCodeTelephone(req);
    }

    /** Étape 2 : CONNECTE (numéro déjà connu) ou PROFIL_REQUIS avec le jeton d'inscription. */
    @PostMapping("/telephone/verifier")
    public AuthReponse verifierTelephone(@Valid @RequestBody VerificationTelephoneRequete req, HttpServletRequest http) {
        limiteurIp.consommer(LimiteurParIp.Action.VERIFICATION_CODE, http.getRemoteAddr());
        return auth.verifierCodeTelephone(req);
    }

    /** Étape 3 (numéro inconnu) : création du compte, puis connexion. */
    @PostMapping("/telephone/terminer")
    @ResponseStatus(HttpStatus.CREATED)
    public AuthReponse terminerTelephone(@Valid @RequestBody FinInscriptionTelephoneRequete req) {
        return auth.terminerInscriptionTelephone(req);
    }

    @PostMapping("/google")
    public AuthReponse google(@Valid @RequestBody GoogleRequete req) {
        return auth.connecterAvecGoogle(req);
    }

    @PostMapping("/apple")
    public AuthReponse apple(@Valid @RequestBody AppleRequete req) {
        return auth.connecterAvecApple(req);
    }

    @PostMapping("/refresh")
    public AuthReponse rafraichir(@Valid @RequestBody RefreshRequete req) {
        return auth.rafraichir(req);
    }

    @PostMapping("/deconnexion")
    public ResponseEntity<Void> deconnecter(@Valid @RequestBody RefreshRequete req) {
        auth.deconnecter(req);
        return ResponseEntity.noContent().build();
    }

    @PostMapping("/mot-de-passe/oublie")
    public AuthReponse motDePasseOublie(@Valid @RequestBody IdentifiantRequete req, HttpServletRequest http) {
        limiteurIp.consommer(LimiteurParIp.Action.DEMANDE_CODE, http.getRemoteAddr());
        return auth.motDePasseOublie(req);
    }

    @PostMapping("/mot-de-passe/verifier-code")
    public CodeVerifieReponse verifierCodeReinitialisation(@Valid @RequestBody VerificationOtpRequete req,
                                                           HttpServletRequest http) {
        limiteurIp.consommer(LimiteurParIp.Action.VERIFICATION_CODE, http.getRemoteAddr());
        return auth.verifierCodeReinitialisation(req);
    }

    @PostMapping("/mot-de-passe/reinitialiser")
    public ResponseEntity<Void> reinitialiser(@Valid @RequestBody ReinitialisationRequete req) {
        auth.reinitialiserMotDePasse(req);
        return ResponseEntity.noContent().build();
    }
}
