package sn.isep.Convoiturage.reservation;

import com.fasterxml.jackson.annotation.JsonInclude;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import sn.isep.Convoiturage.trajet.Escale;
import sn.isep.Convoiturage.trajet.StatutTrajet;
import sn.isep.Convoiturage.trajet.Trajet;
import sn.isep.Convoiturage.utilisateur.UtilisateurDtos.UtilisateurResume;

import java.math.BigDecimal;
import java.time.LocalDateTime;

public final class ReservationDtos {

    private ReservationDtos() {}

    public record ReservationRequete(
            @NotNull @Min(1) @Max(8) Integer nombrePlaces,
            /* Escale du trajet choisie comme point de ramassage (facultatif). */
            Long idEscaleRamassage,
            /* Lot 1 : ESPECES uniquement. */
            MoyenPaiement moyenPaiement) {}

    public record MotifRequete(@Size(max = 500) String motif) {}

    /** Le conducteur saisit le PIN à 6 chiffres ou le contenu du QR code présenté par le passager. */
    public record EmbarquementRequete(@NotBlank @Size(max = 64) String code) {}

    public record TrajetResumeDto(Long id, String lieuDepart, String lieuArrivee, LocalDateTime dateHeureDepart,
                                  StatutTrajet statut, UtilisateurResume conducteur) {
        static TrajetResumeDto de(Trajet t) {
            return new TrajetResumeDto(t.getId(), t.getLieuDepart(), t.getLieuArrivee(), t.getDateHeureDepart(),
                    t.getStatut(), UtilisateurResume.de(t.getConducteur()));
        }
    }

    @JsonInclude(JsonInclude.Include.NON_NULL)
    public record ReservationDto(Long id, TrajetResumeDto trajet, UtilisateurResume passager, Integer nombrePlaces,
                                 BigDecimal prixUnitaire, BigDecimal montantTotal, StatutReservation statut,
                                 String pointRamassage, MoyenPaiement moyenPaiement, StatutPaiement statutPaiement,
                                 boolean embarque, String motifAnnulation, LocalDateTime dateDemande,
                                 LocalDateTime dateReponse) {

        static ReservationDto de(Reservation r, Paiement p, ConfirmationEmbarquement c) {
            Escale e = r.getEscaleRamassage();
            return new ReservationDto(r.getId(), TrajetResumeDto.de(r.getTrajet()), UtilisateurResume.de(r.getPassager()),
                    r.getNombrePlaces(), r.getPrixUnitaire(), r.getMontantTotal(), r.getStatut(),
                    e != null ? e.getLieu() : r.getTrajet().getLieuDepart(),
                    p == null ? null : p.getMoyenPaiement(), p == null ? null : p.getStatut(),
                    c != null && c.getStatut() == StatutConfirmation.CONFIRMEE,
                    r.getMotifAnnulation(), r.getDateDemande(), r.getDateReponse());
        }
    }

    /** Ce que le passager présente au conducteur. qrContenu est à encoder tel quel dans le QR code. */
    public record CodeEmbarquementDto(Long idReservation, String codePin, String qrContenu, StatutConfirmation statut,
                                      LocalDateTime dateExpiration, BigDecimal montantAPayer) {}

    /** Réponse au conducteur après validation : qui monte et combien encaisser. */
    public record EmbarquementConfirmeDto(Long idReservation, UtilisateurResume passager, int nombrePlaces,
                                          BigDecimal montantAEncaisser, MoyenPaiement moyenPaiement) {}

    public record StatistiquesReservations(long total, long enAttente, long acceptees, long terminees, long annulees,
                                           long refusees, double tauxAnnulation, BigDecimal montantEncaisse) {}
}
