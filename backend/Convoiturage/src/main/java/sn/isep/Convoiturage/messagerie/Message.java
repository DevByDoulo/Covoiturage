package sn.isep.Convoiturage.messagerie;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;
import sn.isep.Convoiturage.utilisateur.Utilisateur;

import java.time.LocalDateTime;

/** Message d'une conversation : un texte ou un vocal (fichier audio stocké hors de la base). */
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

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 10)
    private TypeMessage type = TypeMessage.TEXTE;

    /** Texte du message ; null pour un vocal (sauf « [message supprimé] » après anonymisation de l'expéditeur). */
    @Column(length = 1000)
    private String contenu;

    /** Vocal : nom aléatoire du fichier dans le dossier « vocaux » ; null une fois le fichier effacé. */
    @Column(name = "fichier_audio", length = 60)
    private String fichierAudio;

    @Column(name = "type_mime_audio", length = 30)
    private String typeMimeAudio;

    /** Vocal : durée lue dans le fichier par le serveur. */
    @Column(name = "duree_ms")
    private Integer dureeMs;

    /** Vocal : niveaux sonores (0 à 100, séparés par des virgules) mesurés pendant l'enregistrement. */
    @Column(name = "forme_onde", length = 400)
    private String formeOnde;

    @Column(name = "date_envoi", nullable = false, updatable = false)
    private LocalDateTime dateEnvoi = LocalDateTime.now();

    /** Null tant que le destinataire n'a pas ouvert la conversation. */
    @Column(name = "date_lecture")
    private LocalDateTime dateLecture;

    /** Vocal : date à laquelle le destinataire l'a écouté. */
    @Column(name = "date_ecoute")
    private LocalDateTime dateEcoute;

    public boolean estVocal() {
        return type == TypeMessage.VOCAL;
    }

    /** Aperçu d'une ligne (liste des conversations, notifications, push) : « 🎤 Message vocal (0:23) » pour un vocal. */
    public String apercu(int max) {
        if (estVocal()) {
            return contenu != null ? contenu : "🎤 Message vocal (" + duree(dureeMs == null ? 0 : dureeMs) + ")";
        }
        return contenu.length() > max ? contenu.substring(0, max - 3) + "..." : contenu;
    }

    /** « 0:23 », « 4:59 » (secondes entières, comme sur le lecteur). */
    static String duree(long ms) {
        long s = Math.round(ms / 1000.0);
        return (s / 60) + ":" + String.format("%02d", s % 60);
    }
}
