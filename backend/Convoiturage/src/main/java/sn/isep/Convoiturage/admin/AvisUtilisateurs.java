package sn.isep.Convoiturage.admin;

import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;
import sn.isep.Convoiturage.notification.NotificationService;
import sn.isep.Convoiturage.notification.Priorite;
import sn.isep.Convoiturage.notification.TypeNotification;
import sn.isep.Convoiturage.utilisateur.Utilisateur;

/**
 * Informe l'utilisateur des décisions de l'administration (document validé ou refusé, compte bloqué…) : notification
 * dans l'application et, ces décisions étant importantes, par email (ou SMS) — module 06.
 */
@Component
@RequiredArgsConstructor
class AvisUtilisateurs {

    private final NotificationService notifications;

    void envoyer(Utilisateur u, TypeNotification type, String titre, String message, String lien) {
        notifications.notifier(u, type, Priorite.IMPORTANTE, titre, message, lien);
    }
}
