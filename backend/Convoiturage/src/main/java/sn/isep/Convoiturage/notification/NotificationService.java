package sn.isep.Convoiturage.notification;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.context.ApplicationEventPublisher;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.scheduling.annotation.Async;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.transaction.event.TransactionalEventListener;
import sn.isep.Convoiturage.common.ApiException;
import sn.isep.Convoiturage.utilisateur.Utilisateur;

import java.time.LocalDateTime;
import java.util.Map;

/**
 * Notifications in-app (table notification) + push Firebase.
 * Le push part uniquement après le commit de la transaction métier, et de façon asynchrone
 * pour ne pas ralentir la réponse HTTP.
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class NotificationService {

    private final NotificationRepository notifications;
    private final ApplicationEventPublisher evenements;
    private final PushSender pushSender;

    public record PushAEnvoyer(String fcmToken, String titre, String contenu, Map<String, String> donnees) {}

    public record NotificationDto(Long id, TypeNotification type, String titre, String contenu, boolean lu,
                                  LocalDateTime dateEnvoi) {
        static NotificationDto de(Notification n) {
            return new NotificationDto(n.getId(), n.getType(), n.getTitre(), n.getContenu(), n.isLu(), n.getDateEnvoi());
        }
    }

    @Transactional
    public void notifier(Utilisateur destinataire, TypeNotification type, String titre, String contenu,
                         Map<String, String> donnees) {
        Notification n = new Notification();
        n.setDestinataire(destinataire);
        n.setType(type);
        n.setTitre(titre);
        n.setContenu(contenu.length() > 500 ? contenu.substring(0, 497) + "..." : contenu);
        notifications.save(n);
        if (destinataire.getFcmToken() != null) {
            Map<String, String> data = new java.util.HashMap<>(donnees);
            data.put("type", type.name());
            evenements.publishEvent(new PushAEnvoyer(destinataire.getFcmToken(), titre, n.getContenu(), data));
        }
    }

    @Async
    @TransactionalEventListener(fallbackExecution = true)
    public void envoyerPush(PushAEnvoyer push) {
        try {
            pushSender.envoyer(push.fcmToken(), push.titre(), push.contenu(), push.donnees());
        } catch (RuntimeException e) {
            log.warn("Notification push non envoyée : {}", e.getMessage());
        }
    }

    @Transactional(readOnly = true)
    public Page<NotificationDto> lister(Long utilisateurId, int page, int taille) {
        return notifications.findByDestinataireIdOrderByDateEnvoiDesc(utilisateurId, PageRequest.of(page, Math.min(taille, 50)))
                .map(NotificationDto::de);
    }

    @Transactional(readOnly = true)
    public long nombreNonLues(Long utilisateurId) {
        return notifications.countByDestinataireIdAndLuFalse(utilisateurId);
    }

    @Transactional
    public void marquerLue(Long utilisateurId, Long notificationId) {
        notifications.findByIdAndDestinataireId(notificationId, utilisateurId)
                .orElseThrow(() -> ApiException.notFound("Notification introuvable"))
                .setLu(true);
    }

    @Transactional
    public void marquerToutesLues(Long utilisateurId) {
        notifications.marquerToutesLues(utilisateurId);
    }
}
