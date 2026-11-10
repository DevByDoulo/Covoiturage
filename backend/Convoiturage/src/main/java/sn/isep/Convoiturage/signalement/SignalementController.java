package sn.isep.Convoiturage.signalement;

import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.*;
import sn.isep.Convoiturage.common.SecurityUtils;
import sn.isep.Convoiturage.signalement.SignalementDtos.*;

import java.util.List;

/** Signalements : côté utilisateur (/api/signalements) et modération (/api/admin/signalements, rôle ADMIN). */
@RestController
@RequestMapping("/api")
@RequiredArgsConstructor
public class SignalementController {

    private final SignalementService service;

    @PostMapping("/signalements")
    @ResponseStatus(HttpStatus.CREATED)
    public SignalementDto signaler(@Valid @RequestBody SignalementRequete req) {
        return service.signaler(SecurityUtils.utilisateurCourantId(), req);
    }

    @GetMapping("/signalements/mes")
    public List<SignalementDto> mes() {
        return service.mesSignalements(SecurityUtils.utilisateurCourantId());
    }

    @GetMapping("/admin/signalements")
    public Page<SignalementAdminDto> liste(@RequestParam(required = false) StatutSignalement statut,
                                           @RequestParam(required = false) Long utilisateur,
                                           @RequestParam(defaultValue = "true") boolean plusAnciensDabord,
                                           @RequestParam(defaultValue = "0") int page,
                                           @RequestParam(defaultValue = "20") int taille) {
        return service.liste(statut, utilisateur, plusAnciensDabord, page, taille);
    }

    @GetMapping("/admin/signalements/{id}")
    public SignalementAdminDto detail(@PathVariable Long id) {
        return service.detail(id);
    }

    @PatchMapping("/admin/signalements/{id}")
    public SignalementAdminDto decider(@PathVariable Long id, @Valid @RequestBody DecisionRequete req) {
        return service.decider(SecurityUtils.utilisateurCourantId(), id, req);
    }
}
