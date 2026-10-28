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
import sn.isep.Convoiturage.auth.EmailSender;
import sn.isep.Convoiturage.auth.ExpediteurEmails.EmailAEnvoyer;
import sn.isep.Convoiturage.auth.SmsSender;
import sn.isep.Convoiturage.common.ApiException;
import sn.isep.Convoiturage.utilisateur.Utilisateur;

import java.time.LocalDateTime;
import java.util.HashMap;
import java.util.Map;

/**
 * Module 06 : notifications dans l'application (table notification), push Firebase si l'appareil a enregistré son
 * jeton, et email / SMS pour les notifications importantes. Les envois externes partent après la validation de la
 * transaction métier, en arrière-plan, pour ne pas ralentir la réponse HTTP.
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class NotificationService {

    private final NotificationRepository notifications;
    private final ApplicationEventPublisher evenements;
    private final PushSender pushSender;
    private final EmailSender emails;
    private final SmsSender sms;

    public record PushAEnvoyer(String fcmToken, String titre, String contenu, Map<String, String> donnees) {}

    public record NotificationDto(Long id, TypeNotification type, String titre, String contenu, String lien, boolean lu,
                                  LocalDateTime dateEnvoi) {
        static NotificationDto de(Notification n) {
            return new NotificationDto(n.getId(), n.getType(), n.getTitre(), n.getContenu(), n.getLien(), n.isLu(), n.getDateEnvoi());
        }
    }

    /**
     * Enregistre la notification (affichée dans l'application) et la relaie : push si possible, et pour une
     * notification IMPORTANTE, email (sinon SMS).
     */
    @Transactional
    public void notifier(Utilisateur destinataire, TypeNotification type, Priorite priorite, String titre, String contenu,
                         String lien) {
        Notification n = new Notification();
        n.setDestinataire(destinataire);
        n.setType(type);
        n.setTitre(titre.length() > 120 ? titre.substring(0, 117) + "..." : titre);
        n.setContenu(contenu.length() > 500 ? contenu.substring(0, 497) + "..." : contenu);
        n.setLien(lien);

        if (priorite == Priorite.IMPORTANTE) {
            if (destinataire.getEmail() != null && emails.disponible()) {
                n.setCanal(CanalNotification.EMAIL);
                evenements.publishEvent(new EmailAEnvoyer(destinataire.getEmail(), "YOBALEMAsn - " + titre,
                        "Bonjour " + destinataire.getPrenom() + ",\n\n" + contenu
                                + "\n\nRetrouvez le détail dans l'application YOBALEMAsn.\n\nL'équipe YOBALEMAsn"));
            } else if (destinataire.getTelephone() != null) {
                n.setCanal(CanalNotification.SMS);
                sms.envoyer(destinataire.getTelephone(), "YOBALEMAsn : " + titre + ". " + contenu);
            }
        }
        notifications.save(n);

        if (destinataire.getFcmToken() != null) {
            Map<String, String> donnees = new HashMap<>();
            donnees.put("type", type.name());
            if (lien != null) donnees.put("lien", lien);
            evenements.publishEvent(new PushAEnvoyer(destinataire.getFcmToken(), n.getTitre(), n.getContenu(), donnees));
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

    @Transactional(readOnly = true)
    public boolean dejaEnvoyee(Long utilisateurId, TypeNotification type, String lien) {
        return notifications.existsByDestinataireIdAndTypeAndLien(utilisateurId, type, lien);
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
