package sn.isep.Convoiturage.trajet;

import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.HttpStatus;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;
import sn.isep.Convoiturage.common.SecurityUtils;
import sn.isep.Convoiturage.trajet.TrajetDtos.*;
import sn.isep.Convoiturage.trajet.TrajetService.CriteresRecherche;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalTime;
import java.util.List;

@RestController
@RequestMapping("/api")
@RequiredArgsConstructor
public class TrajetController {

    private final TrajetService service;

    /**
     * Recherche publique. Exemple :
     * GET /api/trajets/recherche?latDepart=14.69&lngDepart=-17.44&latArrivee=14.79&lngArrivee=-16.93&date=2026-11-02
     */
    @GetMapping("/trajets/recherche")
    public List<TrajetDto> rechercher(@RequestParam double latDepart, @RequestParam double lngDepart,
                                      @RequestParam double latArrivee, @RequestParam double lngArrivee,
                                      @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate date,
                                      @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.TIME) LocalTime heureMin,
                                      @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.TIME) LocalTime heureMax,
                                      @RequestParam(defaultValue = "1") int places,
                                      @RequestParam(defaultValue = "5") double rayonKm,
                                      @RequestParam(required = false) BigDecimal prixMax,
                                      @RequestParam(required = false) BigDecimal noteMin,
                                      @RequestParam(defaultValue = "false") boolean femmesUniquement,
                                      @RequestParam(required = false) String conducteur) {
        return service.rechercher(new CriteresRecherche(latDepart, lngDepart, latArrivee, lngArrivee, date, heureMin,
                heureMax, places, rayonKm, prixMax, noteMin, femmesUniquement, conducteur));
    }

    @GetMapping("/trajets/{id}")
    public TrajetDto detail(@PathVariable Long id) {
        return service.detail(id);
    }

    @PostMapping("/trajets/estimation")
    @PreAuthorize("hasRole('CONDUCTEUR')")
    public EstimationReponse estimer(@Valid @RequestBody EstimationRequete req) {
        return service.estimer(SecurityUtils.utilisateurCourantId(), req);
    }

    @PostMapping("/trajets")
    @ResponseStatus(HttpStatus.CREATED)
    @PreAuthorize("hasRole('CONDUCTEUR')")
    public TrajetDto publier(@Valid @RequestBody PublicationRequete req) {
        return service.publier(SecurityUtils.utilisateurCourantId(), req);
    }

    @PutMapping("/trajets/{id}")
    @PreAuthorize("hasRole('CONDUCTEUR')")
    public TrajetDto modifier(@PathVariable Long id, @Valid @RequestBody ModificationTrajetRequete req) {
        return service.modifier(SecurityUtils.utilisateurCourantId(), id, req);
    }

    @PostMapping("/trajets/{id}/annuler")
    @PreAuthorize("hasRole('CONDUCTEUR')")
    public TrajetDto annuler(@PathVariable Long id, @Valid @RequestBody(required = false) AnnulationRequete req) {
        return service.annuler(SecurityUtils.utilisateurCourantId(), id, req == null ? null : req.motif());
    }

    @PostMapping("/trajets/{id}/demarrer")
    @PreAuthorize("hasRole('CONDUCTEUR')")
    public TrajetDto demarrer(@PathVariable Long id) {
        return service.demarrer(SecurityUtils.utilisateurCourantId(), id);
    }

    @PostMapping("/trajets/{id}/terminer")
    @PreAuthorize("hasRole('CONDUCTEUR')")
    public TrajetDto terminer(@PathVariable Long id) {
        return service.terminer(SecurityUtils.utilisateurCourantId(), id);
    }

    /** Historique des trajets proposés par le conducteur connecté. */
    @GetMapping("/moi/trajets")
    @PreAuthorize("hasRole('CONDUCTEUR')")
    public List<TrajetDto> mesTrajets() {
        return service.mesTrajets(SecurityUtils.utilisateurCourantId());
    }
}
