package sn.isep.Convoiturage.recherche;

import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;
import sn.isep.Convoiturage.common.SecurityUtils;
import sn.isep.Convoiturage.recherche.AlerteDtos.AlerteDto;
import sn.isep.Convoiturage.recherche.AlerteDtos.CreationAlerteRequete;

import java.util.List;

@RestController
@RequestMapping("/api/moi/alertes")
@PreAuthorize("hasRole('PASSAGER')")
@RequiredArgsConstructor
public class AlerteRechercheController {

    private final AlerteRechercheService service;

    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    public AlerteDto creer(@Valid @RequestBody CreationAlerteRequete req) {
        return service.creer(SecurityUtils.utilisateurCourantId(), req);
    }

    @GetMapping
    public List<AlerteDto> mesAlertes() {
        return service.mesAlertes(SecurityUtils.utilisateurCourantId());
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> supprimer(@PathVariable Long id) {
        service.supprimer(SecurityUtils.utilisateurCourantId(), id);
        return ResponseEntity.noContent().build();
    }
}
