package sn.isep.Convoiturage.reservation;

import org.springframework.data.jpa.repository.EntityGraph;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.Collection;
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

    /**
     * Paiements en ligne non soldés (en attente ou remboursement demandé) où l'utilisateur est le passager ou le
     * conducteur ; les espèces sont exclues (suivies par la réservation elle-même). Suppression de compte.
     */
    @Query("""
            select count(p) from Paiement p
            where p.statut in :statuts and p.moyenPaiement <> :especes
              and (p.reservation.passager.id = :utilisateurId or p.reservation.trajet.conducteur.id = :utilisateurId)
            """)
    long compterNonSoldes(@Param("utilisateurId") Long utilisateurId, @Param("statuts") Collection<StatutPaiement> statuts,
                          @Param("especes") MoyenPaiement especes);

    /** Remboursements à relancer (le fournisseur n'a pas répondu au moment de l'annulation). */
    List<Paiement> findByStatut(StatutPaiement statut);
}
