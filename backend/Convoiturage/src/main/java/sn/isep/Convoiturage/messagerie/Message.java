package sn.isep.Convoiturage.messagerie;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;
import sn.isep.Convoiturage.utilisateur.Utilisateur;

import java.time.LocalDateTime;

@Entity
@Table(name = "message")
@Getter
@Setter
@NoArgsConstructor
public class Message {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "id_message")
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "id_conversation", nullable = false)
    private Conversation conversation;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "id_expediteur", nullable = false)
    private Utilisateur expediteur;

    @Column(nullable = false, length = 1000)
    private String contenu;

    @Column(name = "date_envoi", nullable = false, updatable = false)
    private LocalDateTime dateEnvoi = LocalDateTime.now();

    /** Null tant que le destinataire n'a pas ouvert la conversation. */
    @Column(name = "date_lecture")
    private LocalDateTime dateLecture;
}
