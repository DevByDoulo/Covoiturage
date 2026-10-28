package sn.isep.Convoiturage.admin;

import org.springframework.data.jpa.repository.EntityGraph;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface ActionAdminRepository extends JpaRepository<ActionAdmin, Long> {

    @EntityGraph(attributePaths = "admin")
    List<ActionAdmin> findTop50ByUtilisateurIdOrderByDateDesc(Long utilisateurId);
}
