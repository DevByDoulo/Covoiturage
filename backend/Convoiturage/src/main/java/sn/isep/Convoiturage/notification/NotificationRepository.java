package sn.isep.Convoiturage.notification;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.Optional;

public interface NotificationRepository extends JpaRepository<Notification, Long> {

    Page<Notification> findByDestinataireIdOrderByDateEnvoiDesc(Long utilisateurId, Pageable pageable);

    Optional<Notification> findByIdAndDestinataireId(Long id, Long utilisateurId);

    long countByDestinataireIdAndLuFalse(Long utilisateurId);

    /** Évite d'envoyer deux fois le même rappel (même type, même destinataire, même écran). */
    boolean existsByDestinataireIdAndTypeAndLien(Long utilisateurId, TypeNotification type, String lien);

    @Modifying
    @Query("update Notification n set n.lu = true where n.destinataire.id = :utilisateurId and n.lu = false")
    int marquerToutesLues(@Param("utilisateurId") Long utilisateurId);
}
