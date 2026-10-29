package sn.isep.Convoiturage.facturation;

import lombok.RequiredArgsConstructor;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;
import sn.isep.Convoiturage.common.SecurityUtils;
import sn.isep.Convoiturage.facturation.FacturationDtos.*;
import sn.isep.Convoiturage.reservation.StatutPaiement;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api")
@RequiredArgsConstructor
public class FacturationController {

    private final FacturationService service;

    /** Moyens proposés au passager (Wave / Orange Money seulement si leur API est configurée). */
    @GetMapping("/paiements/moyens")
    public List<MoyenPaiementDto> moyens() {
        return service.moyens();
    }

    /** Paiement en ligne d'une réservation acceptée (ou passage aux espèces). */
    @PostMapping("/reservations/{id}/paiement")
    @PreAuthorize("hasRole('PASSAGER')")
    public SessionPaiementDto payer(@PathVariable Long id, @RequestBody(required = false) PaiementRequete req) {
        return service.payer(SecurityUtils.utilisateurCourantId(), id, req);
    }

    /** Historique : paiements effectués comme passager et encaissements comme conducteur. */
    @GetMapping("/moi/paiements")
    public List<PaiementDto> historique() {
        return service.historique(SecurityUtils.utilisateurCourantId());
    }

    @GetMapping("/paiements/{reference}/recu")
    public RecuDto recu(@PathVariable String reference) {
        return service.recu(SecurityUtils.utilisateurCourantId(), reference);
    }

    /** Retour du passager après paiement : demande l'état à l'opérateur et renvoie le statut à jour. */
    @PostMapping("/paiements/{reference}/verifier")
    @PreAuthorize("hasRole('PASSAGER')")
    public Map<String, StatutPaiement> verifier(@PathVariable String reference) {
        StatutPaiement statut = service.verifier(SecurityUtils.utilisateurCourantId(), reference);
        return Map.of("statut", statut);
    }

    /**
     * IPN PayDunya (public, authentifié par {@code data[hash]}), en formulaire. Adresse envoyée avec chaque facture
     * si {@code app.paiement.url-api} est renseignée : https://&lt;domaine-de-l'API&gt;/api/paiements/webhooks/paydunya
     */
    @PostMapping(value = "/paiements/webhooks/paydunya", consumes = MediaType.APPLICATION_FORM_URLENCODED_VALUE)
    public ResponseEntity<Void> ipnPayDunya(@RequestParam Map<String, String> formulaire) {
        service.ipnPayDunya(formulaire);
        return ResponseEntity.ok().build();
    }

    /**
     * Webhook Wave (public, authentifié par la signature HMAC). Adresse à déclarer dans le portail Wave Business :
     * https://&lt;domaine-de-l'API&gt;/api/paiements/webhooks/wave
     */
    @PostMapping("/paiements/webhooks/wave")
    public ResponseEntity<Void> webhookWave(@RequestHeader(value = "Wave-Signature", required = false) String signature,
                                            @RequestBody String corpsBrut) {
        service.webhookWave(signature, corpsBrut);
        return ResponseEntity.ok().build();
    }
}
