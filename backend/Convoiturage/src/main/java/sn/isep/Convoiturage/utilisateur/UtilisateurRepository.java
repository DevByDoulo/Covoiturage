package sn.isep.Convoiturage.utilisateur;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.Optional;

public interface UtilisateurRepository extends JpaRepository<Utilisateur, Long> {

    Optional<Utilisateur> findByEmailIgnoreCase(String email);

    Optional<Utilisateur> findByTelephone(String telephone);

    Optional<Utilisateur> findByGoogleId(String googleId);

    boolean existsByRole(Role role);

    long countByStatut(StatutCompte statut);

    long countByRole(Role role);

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
