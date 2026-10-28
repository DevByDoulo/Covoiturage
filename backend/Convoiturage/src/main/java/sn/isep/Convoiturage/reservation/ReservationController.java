package sn.isep.Convoiturage.reservation;

import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;
import sn.isep.Convoiturage.common.SecurityUtils;
import sn.isep.Convoiturage.reservation.ReservationDtos.*;

import java.util.List;

@RestController
@RequestMapping("/api")
@RequiredArgsConstructor
public class ReservationController {

    private final ReservationService service;

    // ---- Passager

    @PostMapping("/trajets/{idTrajet}/reservations")
    @ResponseStatus(HttpStatus.CREATED)
    @PreAuthorize("hasRole('PASSAGER')")
    public ReservationDto reserver(@PathVariable Long idTrajet, @Valid @RequestBody ReservationRequete req) {
        return service.reserver(SecurityUtils.utilisateurCourantId(), idTrajet, req);
    }

    /** Historique des réservations du passager connecté. */
    @GetMapping("/moi/reservations")
    @PreAuthorize("hasRole('PASSAGER')")
    public List<ReservationDto> mesReservations() {
        return service.mesReservations(SecurityUtils.utilisateurCourantId());
    }

    @PostMapping("/reservations/{id}/annuler")
    @PreAuthorize("hasRole('PASSAGER')")
    public ReservationDto annuler(@PathVariable Long id, @Valid @RequestBody(required = false) MotifRequete req) {
        return service.annulerParPassager(SecurityUtils.utilisateurCourantId(), id, req == null ? null : req.motif());
    }

    /** PIN + contenu du QR code à présenter au conducteur. */
    @GetMapping("/reservations/{id}/embarquement")
    @PreAuthorize("hasRole('PASSAGER')")
    public CodeEmbarquementDto codeEmbarquement(@PathVariable Long id) {
        return service.codeEmbarquement(SecurityUtils.utilisateurCourantId(), id);
    }

    // ---- Conducteur

    @GetMapping("/trajets/{idTrajet}/reservations")
    @PreAuthorize("hasRole('CONDUCTEUR')")
    public List<ReservationDto> reservationsDuTrajet(@PathVariable Long idTrajet) {
        return service.reservationsDuTrajet(SecurityUtils.utilisateurCourantId(), idTrajet);
    }

    @PostMapping("/reservations/{id}/accepter")
    @PreAuthorize("hasRole('CONDUCTEUR')")
    public ReservationDto accepter(@PathVariable Long id) {
        return service.accepter(SecurityUtils.utilisateurCourantId(), id);
    }

    @PostMapping("/reservations/{id}/refuser")
    @PreAuthorize("hasRole('CONDUCTEUR')")
    public ReservationDto refuser(@PathVariable Long id, @Valid @RequestBody(required = false) MotifRequete req) {
        return service.refuser(SecurityUtils.utilisateurCourantId(), id, req == null ? null : req.motif());
    }

    @PostMapping("/trajets/{idTrajet}/embarquement")
    @PreAuthorize("hasRole('CONDUCTEUR')")
    public EmbarquementConfirmeDto confirmerEmbarquement(@PathVariable Long idTrajet, @Valid @RequestBody EmbarquementRequete req) {
        return service.confirmerEmbarquement(SecurityUtils.utilisateurCourantId(), idTrajet, req.code());
    }
}
