package sn.isep.Convoiturage.trajet;

import jakarta.persistence.LockModeType;
import org.springframework.data.jpa.repository.EntityGraph;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Lock;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.Collection;
import java.util.List;
import java.util.Optional;

public interface TrajetRepository extends JpaRepository<Trajet, Long> {

    /** Verrou pessimiste : évite la sur-réservation quand deux passagers réservent en même temps. */
    @Lock(LockModeType.PESSIMISTIC_WRITE)
    @Query("select t from Trajet t where t.id = :id")
    Optional<Trajet> findByIdForUpdate(@Param("id") Long id);

    @EntityGraph(attributePaths = {"conducteur", "vehicule", "tarification"})
    List<Trajet> findByIdIn(Collection<Long> ids);

    @EntityGraph(attributePaths = {"vehicule", "tarification"})
    List<Trajet> findByConducteurIdOrderByDateHeureDepartDesc(Long conducteurId);

    long countByStatut(StatutTrajet statut);

    /** Ligne brute de la recherche : distances au tracé et points de ramassage/dépose projetés sur l'itinéraire. */
    interface ResultatRecherche {
        Long getIdTrajet();
        Double getDistanceDepartM();
        Double getDistanceArriveeM();
        Double getLatRamassage();
        Double getLngRamassage();
        Double getLatDepose();
        Double getLngDepose();
    }

    /**
     * Trajets dont l'itinéraire passe à moins de {@code rayonM} mètres du départ ET de l'arrivée
     * du passager, dans le bon sens (le point de ramassage précède le point de dépose sur le tracé).
     * Utilise l'index GIST sur (itineraire::geography).
     */
    @Query(nativeQuery = true, value = """
            WITH p AS (
                SELECT ST_SetSRID(ST_MakePoint(:lngDepart, :latDepart), 4326)   AS pd,
                       ST_SetSRID(ST_MakePoint(:lngArrivee, :latArrivee), 4326) AS pa
            )
            SELECT t.id_trajet                                         AS "idTrajet",
                   ST_Distance(t.itineraire::geography, p.pd::geography) AS "distanceDepartM",
                   ST_Distance(t.itineraire::geography, p.pa::geography) AS "distanceArriveeM",
                   ST_Y(ST_ClosestPoint(t.itineraire, p.pd))             AS "latRamassage",
                   ST_X(ST_ClosestPoint(t.itineraire, p.pd))             AS "lngRamassage",
                   ST_Y(ST_ClosestPoint(t.itineraire, p.pa))             AS "latDepose",
                   ST_X(ST_ClosestPoint(t.itineraire, p.pa))             AS "lngDepose"
            FROM trajet t
            CROSS JOIN p
            JOIN tarification tf ON tf.id_trajet = t.id_trajet
            JOIN utilisateur u ON u.id_utilisateur = t.id_conducteur
            WHERE t.statut = 'PUBLIE'
              AND u.statut = 'ACTIF'
              AND t.nombre_places_disponibles >= :places
              AND t.date_heure_depart > :maintenant
              AND t.date_heure_depart + make_interval(mins => t.flexibilite_minutes) >= :debut
              AND t.date_heure_depart - make_interval(mins => t.flexibilite_minutes) <= :fin
              AND ST_DWithin(t.itineraire::geography, p.pd::geography, :rayonM)
              AND ST_DWithin(t.itineraire::geography, p.pa::geography, :rayonM)
              AND ST_LineLocatePoint(t.itineraire, p.pd) < ST_LineLocatePoint(t.itineraire, p.pa)
              AND (CAST(:prixMax AS numeric) IS NULL OR tf.prix_final <= CAST(:prixMax AS numeric))
              AND (CAST(:noteMin AS numeric) IS NULL OR COALESCE(u.note_moyenne, 0) >= CAST(:noteMin AS numeric))
              AND (:femmesUniquement = FALSE OR t.femmes_uniquement = TRUE)
              AND (CAST(:conducteur AS text) IS NULL OR lower(u.prenom || ' ' || u.nom) LIKE CAST(:conducteur AS text))
              AND t.id_conducteur <> :exclureConducteurId
            ORDER BY t.date_heure_depart ASC, "distanceDepartM" ASC
            LIMIT 50
            """)
    List<ResultatRecherche> rechercher(@Param("latDepart") double latDepart, @Param("lngDepart") double lngDepart,
                                       @Param("latArrivee") double latArrivee, @Param("lngArrivee") double lngArrivee,
                                       @Param("rayonM") double rayonM, @Param("places") int places,
                                       @Param("maintenant") LocalDateTime maintenant,
                                       @Param("debut") LocalDateTime debut, @Param("fin") LocalDateTime fin,
                                       @Param("prixMax") BigDecimal prixMax, @Param("noteMin") BigDecimal noteMin,
                                       @Param("femmesUniquement") boolean femmesUniquement,
                                       @Param("conducteur") String conducteur,
                                       @Param("exclureConducteurId") long exclureConducteurId);
}
