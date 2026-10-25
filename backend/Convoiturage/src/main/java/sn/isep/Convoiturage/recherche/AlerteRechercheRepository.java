package sn.isep.Convoiturage.recherche;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.time.LocalDate;
import java.util.List;
import java.util.Optional;

public interface AlerteRechercheRepository extends JpaRepository<AlerteRecherche, Long> {

    List<AlerteRecherche> findByUtilisateurIdAndActifTrueAndDateDepartGreaterThanEqualOrderByDateDepartAsc(
            Long utilisateurId, LocalDate aPartirDu);

    long countByUtilisateurIdAndActifTrueAndDateDepartGreaterThanEqual(Long utilisateurId, LocalDate aPartirDu);

    Optional<AlerteRecherche> findByIdAndUtilisateurId(Long id, Long utilisateurId);

    /**
     * Alertes satisfaites par un trajet : mêmes règles que la recherche (le tracé passe près du départ
     * et de l'arrivée de l'alerte, dans le bon sens), même jour, prix et « femmes uniquement » respectés.
     */
    @Query(nativeQuery = true, value = """
            SELECT a.* FROM alerte_recherche a
            JOIN trajet t ON t.id_trajet = :idTrajet
            JOIN tarification tf ON tf.id_trajet = t.id_trajet
            JOIN utilisateur u ON u.id_utilisateur = a.id_utilisateur
            WHERE a.actif
              AND u.statut = 'ACTIF'
              AND a.id_utilisateur <> t.id_conducteur
              AND a.date_depart = CAST(t.date_heure_depart AS date)
              AND (a.prix_max IS NULL OR tf.prix_final <= a.prix_max)
              AND (NOT t.femmes_uniquement OR u.sexe = 'FEMME')
              AND ST_DWithin(t.itineraire::geography,
                             ST_SetSRID(ST_MakePoint(a.longitude_depart, a.latitude_depart), 4326)::geography,
                             a.rayon_km * 1000)
              AND ST_DWithin(t.itineraire::geography,
                             ST_SetSRID(ST_MakePoint(a.longitude_arrivee, a.latitude_arrivee), 4326)::geography,
                             a.rayon_km * 1000)
              AND ST_LineLocatePoint(t.itineraire, ST_SetSRID(ST_MakePoint(a.longitude_depart, a.latitude_depart), 4326))
                < ST_LineLocatePoint(t.itineraire, ST_SetSRID(ST_MakePoint(a.longitude_arrivee, a.latitude_arrivee), 4326))
            """)
    List<AlerteRecherche> correspondantAuTrajet(@Param("idTrajet") Long idTrajet);
}
