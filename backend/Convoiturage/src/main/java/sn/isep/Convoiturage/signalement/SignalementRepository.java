package sn.isep.Convoiturage.signalement;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.EntityGraph;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.time.LocalDateTime;
import java.util.List;

interface SignalementRepository extends JpaRepository<Signalement, Long> {

    boolean existsBySignaleurIdAndSignaleIdAndStatutIn(Long signaleurId, Long signaleId, List<StatutSignalement> statuts);

    long countBySignaleurIdAndDateSignalementGreaterThanEqual(Long signaleurId, LocalDateTime depuis);

    long countBySignaleId(Long signaleId);

    @EntityGraph(attributePaths = {"signale", "trajet"})
    List<Signalement> findBySignaleurIdOrderByDateSignalementDesc(Long signaleurId);

    @EntityGraph(attributePaths = {"signaleur", "signale", "trajet", "admin"})
    @Query("""
            select s from Signalement s
            where (:statut is null or s.statut = :statut)
              and (:signaleId is null or s.signale.id = :signaleId)
            """)
    Page<Signalement> rechercher(@Param("statut") StatutSignalement statut, @Param("signaleId") Long signaleId,
                                 Pageable page);

    @EntityGraph(attributePaths = {"signaleur", "signale", "trajet", "admin"})
    java.util.Optional<Signalement> findDetailleById(Long id);
}
