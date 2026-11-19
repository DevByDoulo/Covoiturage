package sn.isep.Convoiturage.utilisateur;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

public interface UtilisateurRepository extends JpaRepository<Utilisateur, Long> {

    Optional<Utilisateur> findByEmailIgnoreCase(String email);

    Optional<Utilisateur> findByTelephone(String telephone);

    Optional<Utilisateur> findByGoogleId(String googleId);

    Optional<Utilisateur> findByAppleId(String appleId);

    boolean existsByRole(Role role);

    long countByStatut(StatutCompte statut);

    long countByRole(Role role);

    /** Comptes dont la demande de suppression date d'avant {@code limite} (délai de grâce écoulé). */
    @Query("""
            select u.id from Utilisateur u
            where u.statut = sn.isep.Convoiturage.utilisateur.StatutCompte.SUPPRESSION_DEMANDEE
              and u.dateSuppressionDemandee <= :limite
            """)
    List<Long> comptesASupprimer(@Param("limite") LocalDateTime limite);

    long countByConducteurValideTrue();

    @Query("""
            select u from Utilisateur u
            where (:statut is null or u.statut = :statut)
              and (:motif is null
                   or lower(concat(u.prenom, ' ', u.nom)) like :motif
                   or lower(coalesce(u.email, '')) like :motif
                   or coalesce(u.telephone, '') like :motif)
            order by u.dateCreation desc
            """)
    Page<Utilisateur> rechercher(@Param("motif") String motif, @Param("statut") StatutCompte statut, Pageable pageable);
}
