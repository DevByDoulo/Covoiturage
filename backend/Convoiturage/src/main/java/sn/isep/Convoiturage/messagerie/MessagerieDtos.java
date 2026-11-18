package sn.isep.Convoiturage.messagerie;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import sn.isep.Convoiturage.trajet.StatutTrajet;
import sn.isep.Convoiturage.trajet.Trajet;
import sn.isep.Convoiturage.utilisateur.UtilisateurDtos.UtilisateurResume;

import java.time.LocalDateTime;
import java.util.List;

public final class MessagerieDtos {

    private MessagerieDtos() {}

    /** Le conducteur indique le passager à qui il écrit ; un passager n'envoie rien. */
    public record OuvertureRequete(Long idPassager) {}

    public record EnvoiRequete(@NotBlank @Size(max = 1000) String contenu) {}

    public record TrajetResume(Long id, String lieuDepart, String lieuArrivee, LocalDateTime dateHeureDepart,
                               StatutTrajet statut) {
        static TrajetResume de(Trajet t) {
            return new TrajetResume(t.getId(), t.getLieuDepart(), t.getLieuArrivee(), t.getDateHeureDepart(), t.getStatut());
        }
    }

    public record ConversationResume(Long id, TrajetResume trajet, UtilisateurResume interlocuteur,
                                     boolean jeSuisConducteur, String dernierMessage, boolean dernierDeMoi,
                                     LocalDateTime dateDernierMessage, long nonLus) {}

    /**
     * Un message. Vocal : {@code contenu} est null (ou « [message supprimé] »), {@code audioDisponible} est faux une
     * fois le fichier effacé (expiration, compte supprimé) et {@code ecoute} passe à vrai quand le destinataire l'a lu.
     */
    public record MessageDto(Long id, TypeMessage type, String contenu, Integer dureeMs, List<Integer> formeOnde,
                             boolean audioDisponible, LocalDateTime dateEnvoi, boolean deMoi, boolean lu,
                             boolean ecoute) {
        static MessageDto de(Message m, Long lecteurId) {
            return new MessageDto(m.getId(), m.getType(), m.getContenu(), m.getDureeMs(), FormeOnde.lire(m.getFormeOnde()),
                    m.getFichierAudio() != null, m.getDateEnvoi(), m.getExpediteur().getId().equals(lecteurId),
                    m.getDateLecture() != null, m.getDateEcoute() != null);
        }
    }

    /** Message signalé, vu par le module signalements (et par l'administrateur qui le modère). */
    public record MessageSignale(Long id, Long idExpediteur, Long idTrajet, TypeMessage type, String contenu,
                                 Integer dureeMs, boolean audioDisponible, LocalDateTime dateEnvoi) {
        static MessageSignale de(Message m) {
            return new MessageSignale(m.getId(), m.getExpediteur().getId(), m.getConversation().getTrajet().getId(),
                    m.getType(), m.getContenu(), m.getDureeMs(), m.getFichierAudio() != null, m.getDateEnvoi());
        }
    }

    /** Une conversation ouverte : en-tête, possibilité d'écrire et derniers messages (du plus ancien au plus récent). */
    public record ConversationDetail(Long id, TrajetResume trajet, UtilisateurResume interlocuteur,
                                     boolean jeSuisConducteur, String fermeture, List<MessageDto> messages) {}

    public record NombreDto(long nombre) {}
}
