package sn.isep.Convoiturage.notification;

import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import sn.isep.Convoiturage.common.SecurityUtils;
import sn.isep.Convoiturage.notification.NotificationService.NotificationDto;
import sn.isep.Convoiturage.notification.NotificationService.PreferencesNotificationDto;

import java.util.Map;

@RestController
@RequestMapping("/api/moi/notifications")
@RequiredArgsConstructor
public class NotificationController {

    private final NotificationService service;

    @GetMapping
    public Page<NotificationDto> lister(@RequestParam(defaultValue = "0") int page,
                                        @RequestParam(defaultValue = "20") int taille) {
        return service.lister(SecurityUtils.utilisateurCourantId(), page, taille);
    }

    @GetMapping("/non-lues")
    public Map<String, Long> nombreNonLues() {
        return Map.of("nombre", service.nombreNonLues(SecurityUtils.utilisateurCourantId()));
    }

    @PostMapping("/{id}/lue")
    public ResponseEntity<Void> marquerLue(@PathVariable Long id) {
        service.marquerLue(SecurityUtils.utilisateurCourantId(), id);
        return ResponseEntity.noContent().build();
    }

    /** Préférence : recevoir ou non les notifications push (elles restent visibles dans l'application). */
    @GetMapping("/preferences")
    public PreferencesNotificationDto preferences() {
        return service.preferences(SecurityUtils.utilisateurCourantId());
    }

    @PutMapping("/preferences")
    public PreferencesNotificationDto modifierPreferences(@RequestBody PreferencesNotificationDto req) {
        return service.modifierPreferences(SecurityUtils.utilisateurCourantId(), req);
    }

    @PostMapping("/lues")
    public ResponseEntity<Void> marquerToutesLues() {
        service.marquerToutesLues(SecurityUtils.utilisateurCourantId());
        return ResponseEntity.noContent().build();
    }
}
