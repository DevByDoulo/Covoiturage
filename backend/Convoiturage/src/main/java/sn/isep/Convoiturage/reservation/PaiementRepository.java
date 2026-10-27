package sn.isep.Convoiturage.reservation;

import org.springframework.data.jpa.repository.EntityGraph;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface PaiementRepository extends JpaRepository<Paiement, Long> {

    Optional<Paiement> findFirstByReservationIdOrderByDateInitiationDesc(Long reservationId);

    Optional<Paiement> findByReferenceTransaction(String referenceTransaction);

    Optional<Paiement> findByReferenceExterne(String referenceExterne);

    /** Historique du passager : ses paiements, du plus récent au plus ancien. */
    @EntityGraph(attributePaths = {"reservation", "reservation.trajet"})
    List<Paiement> findByReservationPassagerIdOrderByDateInitiationDesc(Long passagerId);

    /** Encaissements du conducteur : paiements des réservations de ses trajets. */
    @EntityGraph(attributePaths = {"reservation", "reservation.trajet", "reservation.passager"})
    List<Paiement> findByReservationTrajetConducteurIdOrderByDateInitiationDesc(Long conducteurId);

    /** Remboursements à relancer (le fournisseur n'a pas répondu au moment de l'annulation). */
    List<Paiement> findByStatut(StatutPaiement statut);
}
