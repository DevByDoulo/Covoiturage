package sn.isep.Convoiturage.vehicule;

import org.springframework.data.jpa.repository.EntityGraph;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface DocumentRepository extends JpaRepository<Document, Long> {

    @EntityGraph(attributePaths = "vehicule")
    List<Document> findByUtilisateurIdOrderByDateSoumissionDesc(Long utilisateurId);

    List<Document> findByUtilisateurIdAndTypeDocumentAndStatutValidation(Long utilisateurId, TypeDocument type, StatutValidation statut);

    boolean existsByUtilisateurIdAndTypeDocumentAndStatutValidation(Long utilisateurId, TypeDocument type, StatutValidation statut);
}
