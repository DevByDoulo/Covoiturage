package sn.isep.Convoiturage.avis;

import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.EntityGraph;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.Collection;
import java.util.List;
import java.util.Set;

interface EvaluationRepository extends JpaRepository<Evaluation, Long> {

    boolean existsByReservationIdAndEvaluateurId(Long reservationId, Long evaluateurId);

    /** Réservations déjà notées par cet utilisateur, parmi celles indiquées. */
    @Query("select e.reservation.id from Evaluation e where e.evaluateur.id = :evaluateurId and e.reservation.id in :reservations")
    Set<Long> reservationsDejaNotees(@Param("evaluateurId") Long evaluateurId, @Param("reservations") Collection<Long> reservations);

    @EntityGraph(attributePaths = {"evaluateur", "trajet", "trajet.conducteur"})
    List<Evaluation> findByEvalueIdOrderByDateEvaluationDesc(Long evalueId, Pageable page);

    long countByEvalueId(Long evalueId);

    @Query("select avg(e.note) from Evaluation e where e.evalue.id = :evalueId")
    Double moyenne(@Param("evalueId") Long evalueId);

    /** Nombre d'avis par note (1 à 5) : lignes [note, nombre]. */
    @Query("select e.note, count(e) from Evaluation e where e.evalue.id = :evalueId group by e.note")
    List<Object[]> repartition(@Param("evalueId") Long evalueId);
}
