package sn.isep.Convoiturage.notification;

import jakarta.validation.Valid;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import sn.isep.Convoiturage.common.SecurityUtils;

/** Appareils qui reçoivent les notifications push de l'utilisateur connecté. */
@RestController
@RequestMapping("/api/moi")
@RequiredArgsConstructor
public class AppareilController {

    private final AppareilService service;

    public record AppareilRequete(@NotBlank @Size(max = 512) String jeton, @NotNull PlateformeAppareil plateforme) {}

    /** Ancien format (un seul jeton, appli mobile) : conservé pour compatibilité. */
    public record FcmTokenRequete(@NotNull @Size(max = 512) String token) {}

    /** Après la connexion (et à chaque renouvellement du jeton par Firebase). */
    @PostMapping("/appareils")
    public ResponseEntity<Void> enregistrer(@Valid @RequestBody AppareilRequete req) {
        service.enregistrer(SecurityUtils.utilisateurCourantId(), req.jeton(), req.plateforme());
        return ResponseEntity.noContent().build();
    }

    /** À la déconnexion : l'appareil ne reçoit plus les notifications de ce compte. */
    @DeleteMapping("/appareils/{jeton}")
    public ResponseEntity<Void> supprimer(@PathVariable String jeton) {
        service.supprimer(SecurityUtils.utilisateurCourantId(), jeton);
        return ResponseEntity.noContent().build();
    }

    @PutMapping("/fcm-token")
    public ResponseEntity<Void> enregistrerFcmToken(@Valid @RequestBody FcmTokenRequete req) {
        if (!req.token().isBlank()) {
            service.enregistrer(SecurityUtils.utilisateurCourantId(), req.token(), PlateformeAppareil.ANDROID);
        }
        return ResponseEntity.noContent().build();
    }
}
