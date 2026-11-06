package sn.isep.Convoiturage.suivi;

import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;
import sn.isep.Convoiturage.common.SecurityUtils;
import sn.isep.Convoiturage.suivi.SuiviDtos.PositionDto;
import sn.isep.Convoiturage.suivi.SuiviDtos.PositionRequete;

/** 08 — Position du conducteur en temps réel (partage par le conducteur, suivi par ses passagers). */
@RestController
@RequestMapping("/api/trajets/{id}/position")
@RequiredArgsConstructor
public class SuiviController {

    private final SuiviService service;

    /** Le conducteur envoie sa position (toutes les quelques secondes pendant le partage). */
    @PostMapping
    @PreAuthorize("hasRole('CONDUCTEUR')")
    public PositionDto partager(@PathVariable Long id, @Valid @RequestBody PositionRequete req) {
        return service.partager(SecurityUtils.utilisateurCourantId(), id, req);
    }

    /** Dernière position ; 204 si le conducteur ne partage pas (ou plus) sa position. */
    @GetMapping
    public ResponseEntity<PositionDto> consulter(@PathVariable Long id) {
        return service.consulter(SecurityUtils.utilisateurCourantId(), id)
                .map(ResponseEntity::ok)
                .orElseGet(() -> ResponseEntity.noContent().build());
    }

    /** Le conducteur arrête le partage : la position est effacée. */
    @DeleteMapping
    @PreAuthorize("hasRole('CONDUCTEUR')")
    public ResponseEntity<Void> arreter(@PathVariable Long id) {
        service.arreter(SecurityUtils.utilisateurCourantId(), id);
        return ResponseEntity.noContent().build();
    }
}
