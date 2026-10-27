package sn.isep.Convoiturage.utilisateur;

import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface ContactUrgenceRepository extends JpaRepository<ContactUrgence, Long> {

    List<ContactUrgence> findByUtilisateurIdOrderByDateCreationAsc(Long utilisateurId);

    long countByUtilisateurId(Long utilisateurId);

    boolean existsByUtilisateurIdAndTelephone(Long utilisateurId, String telephone);

    Optional<ContactUrgence> findByIdAndUtilisateurId(Long id, Long utilisateurId);
}
