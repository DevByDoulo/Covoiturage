package sn.isep.Convoiturage.messagerie;

import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

interface MessageRepository extends JpaRepository<Message, Long> {

    /** Les derniers messages, du plus récent au plus ancien. */
    List<Message> findByConversationIdOrderByDateEnvoiDescIdDesc(Long conversationId, Pageable page);

    Optional<Message> findFirstByConversationIdOrderByDateEnvoiDescIdDesc(Long conversationId);

    long countByConversationIdAndExpediteurIdNotAndDateLectureIsNull(Long conversationId, Long lecteurId);

    @Modifying
    @Query("""
            update Message m set m.dateLecture = :maintenant
            where m.conversation.id = :conversation and m.expediteur.id <> :lecteur and m.dateLecture is null""")
    int marquerLus(@Param("conversation") Long conversationId, @Param("lecteur") Long lecteurId,
                   @Param("maintenant") LocalDateTime maintenant);

    @Query("""
            select count(m) from Message m join m.conversation c join c.trajet t
            where m.dateLecture is null and m.expediteur.id <> :u and (c.passager.id = :u or t.conducteur.id = :u)""")
    long nonLus(@Param("u") Long utilisateurId);

    long countByExpediteurIdAndDateEnvoiAfter(Long expediteurId, LocalDateTime depuis);

    /** Vocaux dont le fichier existe encore et dont le trajet est parti avant {@code limite}. */
    @Query("""
            select m from Message m join m.conversation c join c.trajet t
            where m.fichierAudio is not null and t.dateHeureDepart < :limite""")
    List<Message> vocauxEchus(@Param("limite") LocalDateTime limite);

    @Query("select m.fichierAudio from Message m where m.fichierAudio in :noms")
    List<String> fichiersAudioCites(@Param("noms") List<String> noms);
}
