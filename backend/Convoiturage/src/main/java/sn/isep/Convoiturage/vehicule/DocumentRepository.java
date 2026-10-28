package sn.isep.Convoiturage.vehicule;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.EntityGraph;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;

public interface DocumentRepository extends JpaRepository<Document, Long> {

    @EntityGraph(attributePaths = "vehicule")
    List<Document> findByUtilisateurIdOrderByDateSoumissionDesc(Long utilisateurId);

    List<Document> findByUtilisateurIdAndTypeDocumentAndStatutValidation(Long utilisateurId, TypeDocument type, StatutValidation statut);

    boolean existsByUtilisateurIdAndTypeDocumentAndStatutValidation(Long utilisateurId, TypeDocument type, StatutValidation statut);

    long countByStatutValidation(StatutValidation statut);

    /** File de validation du back-office : filtre par type et par nom ou téléphone du titulaire (motif déjà en « %…% »). */
    @EntityGraph(attributePaths = {"utilisateur", "vehicule"})
    @Query(value = """
            select d from Document d join d.utilisateur u
            where d.statutValidation = :statut
              and (:type is null or d.typeDocument = :type)
              and (:motif is null
                   or lower(concat(u.prenom, ' ', u.nom)) like :motif
                   or coalesce(u.telephone, '') like :motif)
            """,
            countQuery = """
            select count(d) from Document d join d.utilisateur u
            where d.statutValidation = :statut
              and (:type is null or d.typeDocument = :type)
              and (:motif is null
                   or lower(concat(u.prenom, ' ', u.nom)) like :motif
                   or coalesce(u.telephone, '') like :motif)
            """)
    Page<Document> fileDeValidation(@Param("statut") StatutValidation statut, @Param("type") TypeDocument type,
                                    @Param("motif") String motif, Pageable pageable);
}
