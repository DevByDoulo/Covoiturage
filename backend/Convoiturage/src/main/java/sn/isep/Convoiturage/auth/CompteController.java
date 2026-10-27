package sn.isep.Convoiturage.auth;

import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import sn.isep.Convoiturage.auth.AuthDtos.*;
import sn.isep.Convoiturage.common.SecurityUtils;

/** Sécurité du compte de l'utilisateur connecté : mot de passe et désactivation. */
@RestController
@RequestMapping("/api/moi")
@RequiredArgsConstructor
public class CompteController {

    private final AuthService auth;

    /** Renvoie de nouveaux jetons : les autres appareils sont déconnectés, pas celui-ci. */
    @PutMapping("/mot-de-passe")
    public AuthReponse changerMotDePasse(@Valid @RequestBody ChangementMotDePasseRequete req) {
        return auth.changerMotDePasse(SecurityUtils.utilisateurCourantId(), req);
    }

    @PostMapping("/desactivation")
    public ResponseEntity<Void> desactiver(@RequestBody DesactivationRequete req) {
        auth.desactiver(SecurityUtils.utilisateurCourantId(), req);
        return ResponseEntity.noContent().build();
    }
}
