package sn.isep.Convoiturage.messagerie;

import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;
import java.util.Optional;

interface ConversationRepository extends JpaRepository<Conversation, Long> {

    Optional<Conversation> findByTrajetIdAndPassagerId(Long trajetId, Long passagerId);

    /** Conversations de l'utilisateur (passager ou conducteur) ayant au moins un message, la plus récente d'abord. */
    @Query("""
            select c from Conversation c join fetch c.trajet t join fetch t.conducteur join fetch c.passager
            where (c.passager.id = :u or t.conducteur.id = :u) and c.dateDernierMessage is not null
            order by c.dateDernierMessage desc""")
    List<Conversation> deUtilisateur(@Param("u") Long utilisateurId, Pageable page);
}
