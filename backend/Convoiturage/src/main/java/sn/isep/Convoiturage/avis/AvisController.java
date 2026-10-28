package sn.isep.Convoiturage.avis;

import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.*;
import sn.isep.Convoiturage.avis.AvisDtos.*;
import sn.isep.Convoiturage.common.SecurityUtils;

import java.util.List;

@RestController
@RequestMapping("/api")
@RequiredArgsConstructor
public class AvisController {

    private final AvisService service;

    /** Noter l'autre partie d'un voyage terminé (le conducteur si je suis passager, le passager si je conduisais). */
    @PostMapping("/reservations/{id}/evaluation")
    @ResponseStatus(HttpStatus.CREATED)
    public AvisDto evaluer(@PathVariable Long id, @Valid @RequestBody EvaluationRequete req) {
        return service.evaluer(SecurityUtils.utilisateurCourantId(), id, req);
    }

    /** Voyages terminés que je n'ai pas encore notés. */
    @GetMapping("/moi/avis-a-donner")
    public List<AvisADonnerDto> aDonner() {
        return service.aDonner(SecurityUtils.utilisateurCourantId());
    }

    /** Réputation publique (moyenne, répartition, derniers avis). */
    @GetMapping("/utilisateurs/{id}/avis")
    public ReputationDto reputation(@PathVariable Long id) {
        return service.reputation(id);
    }
}
