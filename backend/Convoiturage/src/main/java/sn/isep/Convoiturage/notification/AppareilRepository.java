package sn.isep.Convoiturage.notification;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.Optional;

public interface AppareilRepository extends JpaRepository<Appareil, Long> {

    Optional<Appareil> findByJeton(String jeton);

    List<Appareil> findByUtilisateurIdOrderByDerniereUtilisationDesc(Long utilisateurId);

    @Transactional
    @Modifying
    @Query("delete from Appareil a where a.jeton = :jeton and a.utilisateur.id = :utilisateurId")
    int supprimerDeLUtilisateur(@Param("jeton") String jeton, @Param("utilisateurId") Long utilisateurId);

    /** Jeton déclaré invalide par Firebase (application désinstallée, permission retirée…). */
    @Transactional
    @Modifying
    @Query("delete from Appareil a where a.jeton = :jeton")
    int supprimerJeton(@Param("jeton") String jeton);
}
