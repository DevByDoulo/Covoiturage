package sn.isep.Convoiturage.vehicule;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.EntityGraph;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface DocumentRepository extends JpaRepository<Document, Long> {

    List<Document> findByUtilisateurIdOrderByDateSoumissionDesc(Long utilisateurId);

    @EntityGraph(attributePaths = {"utilisateur", "vehicule"})
    Page<Document> findByStatutValidationOrderByDateSoumissionAsc(StatutValidation statut, Pageable pageable);

    boolean existsByUtilisateurIdAndTypeDocumentAndStatutValidation(Long utilisateurId, TypeDocument type, StatutValidation statut);

    long countByStatutValidation(StatutValidation statut);
}
