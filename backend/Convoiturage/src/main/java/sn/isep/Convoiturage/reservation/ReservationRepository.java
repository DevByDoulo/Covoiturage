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

    List<Reservation> findByPassagerIdAndStatut(Long passagerId, StatutReservation statut);

    /** Réservations acceptées du passager dont le trajet est en cours ou n'est pas encore parti (suppression de compte). */
    @Query("""
            select count(r) from Reservation r
            where r.passager.id = :passagerId
              and r.statut = :acceptee
              and (r.trajet.statut = :enCours or r.trajet.dateHeureDepart > :maintenant)
            """)
    long compterAccepteesAVenir(@Param("passagerId") Long passagerId, @Param("acceptee") StatutReservation acceptee,
                                @Param("enCours") sn.isep.Convoiturage.trajet.StatutTrajet enCours,
                                @Param("maintenant") LocalDateTime maintenant);

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

    /**
     * Vrai si les deux personnes ont partagé un trajet (l'une passagère acceptée ou ayant voyagé, l'autre conductrice),
     * éventuellement limité à {@code trajetId} (module 10 Signalements).
     */
    @Query("""
            select count(r) > 0 from Reservation r
            where r.statut in (sn.isep.Convoiturage.reservation.StatutReservation.ACCEPTEE,
                               sn.isep.Convoiturage.reservation.StatutReservation.TERMINEE)
              and (:trajetId is null or r.trajet.id = :trajetId)
              and ((r.passager.id = :a and r.trajet.conducteur.id = :b)
                or (r.passager.id = :b and r.trajet.conducteur.id = :a))
            """)
    boolean ontPartageUnTrajet(@Param("a") Long a, @Param("b") Long b, @Param("trajetId") Long trajetId);
}
