package sn.isep.Convoiturage.reservation;

import org.springframework.data.jpa.repository.EntityGraph;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.time.LocalDateTime;
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

    /**
     * Voyages effectués (réservations TERMINEE : passager embarqué, trajet terminé) où l'utilisateur était
     * passager ou conducteur, partis depuis {@code depuis} : ce sont les voyages qu'il peut encore noter (module 05).
     */
    @Query("""
            select r from Reservation r join fetch r.trajet t join fetch t.conducteur join fetch r.passager
            where r.statut = sn.isep.Convoiturage.reservation.StatutReservation.TERMINEE
              and t.dateHeureDepart >= :depuis
              and (r.passager.id = :utilisateurId or t.conducteur.id = :utilisateurId)
            order by t.dateHeureDepart desc
            """)
    List<Reservation> voyagesTerminesDepuis(@Param("utilisateurId") Long utilisateurId, @Param("depuis") LocalDateTime depuis);
}
