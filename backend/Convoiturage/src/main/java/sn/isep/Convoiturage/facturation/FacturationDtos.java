package sn.isep.Convoiturage.facturation;

import com.fasterxml.jackson.annotation.JsonInclude;
import sn.isep.Convoiturage.reservation.MoyenPaiement;
import sn.isep.Convoiturage.reservation.Paiement;
import sn.isep.Convoiturage.reservation.Reservation;
import sn.isep.Convoiturage.reservation.StatutPaiement;
import sn.isep.Convoiturage.trajet.Trajet;

import java.math.BigDecimal;
import java.time.LocalDateTime;

public final class FacturationDtos {

    private FacturationDtos() {}

    public record MoyenPaiementDto(MoyenPaiement moyen, boolean disponible) {}

    /** Facultatif : changer de moyen avant de payer (ex. Wave en échec -> espèces). */
    public record PaiementRequete(MoyenPaiement moyen) {}

    /** urlPaiement : à ouvrir par le passager (null pour les espèces, réglées au conducteur à l'embarquement). */
    @JsonInclude(JsonInclude.Include.NON_NULL)
    public record SessionPaiementDto(String referenceTransaction, MoyenPaiement moyen, StatutPaiement statut,
                                     BigDecimal montant, String urlPaiement) {}

    /** Ligne de l'historique : role = PASSAGER (j'ai payé) ou CONDUCTEUR (j'ai encaissé). */
    @JsonInclude(JsonInclude.Include.NON_NULL)
    public record PaiementDto(String referenceTransaction, Long idReservation, String role, String trajet,
                              LocalDateTime dateHeureDepart, String contrepartie, BigDecimal montant,
                              MoyenPaiement moyen, StatutPaiement statut, LocalDateTime dateInitiation,
                              LocalDateTime dateConfirmation, LocalDateTime dateRemboursement) {

        static PaiementDto de(Paiement p, boolean vuConducteur) {
            Reservation r = p.getReservation();
            Trajet t = r.getTrajet();
            String autre = vuConducteur
                    ? r.getPassager().getPrenom() + " " + r.getPassager().getNom()
                    : t.getConducteur().getPrenom() + " " + t.getConducteur().getNom();
            return new PaiementDto(p.getReferenceTransaction(), r.getId(), vuConducteur ? "CONDUCTEUR" : "PASSAGER",
                    t.getLieuDepart() + " → " + t.getLieuArrivee(), t.getDateHeureDepart(), autre, p.getMontant(),
                    p.getMoyenPaiement(), p.getStatut(), p.getDateInitiation(), p.getDateConfirmation(),
                    p.getDateRemboursement());
        }
    }

    /** Reçu d'un paiement réglé (ou remboursé). Pas de commission : le conducteur perçoit le montant total. */
    @JsonInclude(JsonInclude.Include.NON_NULL)
    public record RecuDto(String referenceTransaction, String referenceOperateur, LocalDateTime dateConfirmation,
                          String passager, String conducteur, String trajet, LocalDateTime dateHeureDepart,
                          int nombrePlaces, BigDecimal prixUnitaire, BigDecimal montant, BigDecimal commission,
                          BigDecimal montantConducteur, MoyenPaiement moyen, StatutPaiement statut,
                          LocalDateTime dateRemboursement) {

        static RecuDto de(Paiement p) {
            Reservation r = p.getReservation();
            Trajet t = r.getTrajet();
            return new RecuDto(p.getReferenceTransaction(), p.getReferenceExterne(), p.getDateConfirmation(),
                    r.getPassager().getPrenom() + " " + r.getPassager().getNom(),
                    t.getConducteur().getPrenom() + " " + t.getConducteur().getNom(),
                    t.getLieuDepart() + " → " + t.getLieuArrivee(), t.getDateHeureDepart(), r.getNombrePlaces(),
                    r.getPrixUnitaire(), p.getMontant(), BigDecimal.ZERO, p.getMontant(), p.getMoyenPaiement(),
                    p.getStatut(), p.getDateRemboursement());
        }
    }
}
