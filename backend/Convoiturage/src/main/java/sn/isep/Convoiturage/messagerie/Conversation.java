package sn.isep.Convoiturage.messagerie;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;
import sn.isep.Convoiturage.trajet.Trajet;
import sn.isep.Convoiturage.utilisateur.Utilisateur;

import java.time.LocalDateTime;

/** Fil de discussion entre un passager et le conducteur d'un trajet (le conducteur est celui du trajet). */
@Entity
@Table(name = "conversation")
@Getter
@Setter
@NoArgsConstructor
public class Conversation {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "id_conversation")
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "id_trajet", nullable = false)
    private Trajet trajet;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "id_passager", nullable = false)
    private Utilisateur passager;

    @Column(name = "date_creation", nullable = false, updatable = false)
    private LocalDateTime dateCreation = LocalDateTime.now();

    @Column(name = "date_dernier_message")
    private LocalDateTime dateDernierMessage;

    public Utilisateur conducteur() {
        return trajet.getConducteur();
    }

    public boolean participe(Long utilisateurId) {
        return passager.getId().equals(utilisateurId) || conducteur().getId().equals(utilisateurId);
    }

    /** L'autre participant, vu par {@code utilisateurId}. */
    public Utilisateur interlocuteurDe(Long utilisateurId) {
        return passager.getId().equals(utilisateurId) ? conducteur() : passager;
    }
}
