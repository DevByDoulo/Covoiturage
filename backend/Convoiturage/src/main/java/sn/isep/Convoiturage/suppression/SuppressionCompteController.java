package sn.isep.Convoiturage.suppression;

import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import sn.isep.Convoiturage.auth.AuthDtos.AuthReponse;
import sn.isep.Convoiturage.auth.AuthService;
import sn.isep.Convoiturage.common.SecurityUtils;
import sn.isep.Convoiturage.suppression.SuppressionDtos.SuppressionReponse;
import sn.isep.Convoiturage.suppression.SuppressionDtos.SuppressionRequete;

/** Suppression du compte de l'utilisateur connecté (RGPD). L'annulation se fait en se reconnectant. */
@RestController
@RequestMapping("/api/moi/suppression")
@RequiredArgsConstructor
public class SuppressionCompteController {

    private final SuppressionCompteService suppression;
    private final AuthService auth;

    /** Comptes sans mot de passe (Google) : envoie le code de confirmation par email ou SMS. */
    @PostMapping("/code")
    public AuthReponse envoyerCode() {
        return auth.envoyerCodeSuppression(SecurityUtils.utilisateurCourantId());
    }

    @PostMapping
    public SuppressionReponse demander(@RequestBody SuppressionRequete req) {
        return suppression.demander(SecurityUtils.utilisateurCourantId(), req.motDePasse(), req.code());
    }
}
