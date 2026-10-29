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

    public record MessageDto(Long id, String contenu, LocalDateTime dateEnvoi, boolean deMoi, boolean lu) {
        static MessageDto de(Message m, Long lecteurId) {
            return new MessageDto(m.getId(), m.getContenu(), m.getDateEnvoi(),
                    m.getExpediteur().getId().equals(lecteurId), m.getDateLecture() != null);
        }
    }

    /** Une conversation ouverte : en-tête, possibilité d'écrire et derniers messages (du plus ancien au plus récent). */
    public record ConversationDetail(Long id, TrajetResume trajet, UtilisateurResume interlocuteur,
                                     boolean jeSuisConducteur, String fermeture, List<MessageDto> messages) {}

    public record NombreDto(long nombre) {}
}
