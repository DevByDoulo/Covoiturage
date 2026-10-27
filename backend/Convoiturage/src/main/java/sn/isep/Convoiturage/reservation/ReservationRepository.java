package sn.isep.Convoiturage.reservation;

import org.springframework.data.jpa.repository.EntityGraph;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Collection;
import java.util.List;

public interface ReservationRepository extends JpaRepository<Reservation, Long> {

    @EntityGraph(attributePaths = {"trajet", "trajet.conducteur", "trajet.vehicule"})
    List<Reservation> findByPassagerIdOrderByDateDemandeDesc(Long passagerId);

    @EntityGraph(attributePaths = {"passager"})
    List<Reservation> findByTrajetIdOrderByDateDemandeAsc(Long trajetId);

    List<Reservation> findByTrajetIdAndStatutIn(Long trajetId, Collection<StatutReservation> statuts);

    boolean existsByTrajetIdAndPassagerIdAndStatutIn(Long trajetId, Long passagerId, Collection<StatutReservation> statuts);

    long countByStatut(StatutReservation statut);
}
