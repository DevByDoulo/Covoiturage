package sn.isep.Convoiturage.reservation;

import org.springframework.data.jpa.repository.EntityGraph;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.math.BigDecimal;
import java.util.Collection;
import java.util.List;
import java.util.Optional;

interface ReservationRepository extends JpaRepository<Reservation, Long> {

    @EntityGraph(attributePaths = {"trajet", "trajet.conducteur", "trajet.vehicule"})
    List<Reservation> findByPassagerIdOrderByDateDemandeDesc(Long passagerId);

    @EntityGraph(attributePaths = {"passager"})
    List<Reservation> findByTrajetIdOrderByDateDemandeAsc(Long trajetId);

    List<Reservation> findByTrajetIdAndStatutIn(Long trajetId, Collection<StatutReservation> statuts);

    boolean existsByTrajetIdAndPassagerIdAndStatutIn(Long trajetId, Long passagerId, Collection<StatutReservation> statuts);

    long countByStatut(StatutReservation statut);
}

interface PaiementRepository extends JpaRepository<Paiement, Long> {

    Optional<Paiement> findFirstByReservationIdOrderByDateInitiationDesc(Long reservationId);

    @Query("select coalesce(sum(p.montant), 0) from Paiement p where p.statut = :statut")
    BigDecimal sommeParStatut(@Param("statut") StatutPaiement statut);
}

interface ConfirmationEmbarquementRepository extends JpaRepository<ConfirmationEmbarquement, Long> {

    Optional<ConfirmationEmbarquement> findByReservationId(Long reservationId);

    @Query("""
            select c from ConfirmationEmbarquement c join fetch c.reservation r join fetch r.passager
            where r.trajet.id = :trajetId and c.statut = :statut
              and (c.codePin = :code or c.qrToken = :code)
            """)
    Optional<ConfirmationEmbarquement> trouverPourEmbarquement(@Param("trajetId") Long trajetId,
                                                              @Param("code") String code,
                                                              @Param("statut") StatutConfirmation statut);

    @Query("""
            select count(c) > 0 from ConfirmationEmbarquement c
            where c.reservation.trajet.id = :trajetId and c.codePin = :pin
              and c.statut = sn.isep.Convoiturage.reservation.StatutConfirmation.EN_ATTENTE
            """)
    boolean pinDejaUtilise(@Param("trajetId") Long trajetId, @Param("pin") String pin);
}
