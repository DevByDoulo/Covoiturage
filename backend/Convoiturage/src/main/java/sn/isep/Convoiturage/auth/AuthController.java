package sn.isep.Convoiturage.auth;

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

    @PostMapping("/google")
    public AuthReponse google(@Valid @RequestBody GoogleRequete req) {
        return auth.connecterAvecGoogle(req);
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
    public AuthReponse motDePasseOublie(@Valid @RequestBody IdentifiantRequete req) {
        return auth.motDePasseOublie(req);
    }

    @PostMapping("/mot-de-passe/reinitialiser")
    public ResponseEntity<Void> reinitialiser(@Valid @RequestBody ReinitialisationRequete req) {
        auth.reinitialiserMotDePasse(req);
        return ResponseEntity.noContent().build();
    }
}
