package sn.isep.Convoiturage.admin;

import lombok.RequiredArgsConstructor;
import org.springframework.context.ApplicationEventPublisher;
import org.springframework.stereotype.Component;
import sn.isep.Convoiturage.auth.EmailSender;
import sn.isep.Convoiturage.auth.ExpediteurEmails.EmailAEnvoyer;
import sn.isep.Convoiturage.auth.SmsSender;
import sn.isep.Convoiturage.utilisateur.Utilisateur;

/**
 * Informe l'utilisateur des décisions de l'administration (document validé ou refusé, compte bloqué…), par email
 * si possible, sinon par SMS. Les notifications dans l'application viendront avec le module 06.
 */
@Component
@RequiredArgsConstructor
class AvisUtilisateurs {

    private final EmailSender emails;
    private final SmsSender sms;
    private final ApplicationEventPublisher evenements;

    void envoyer(Utilisateur u, String sujet, String message) {
        if (u.getEmail() != null && emails.disponible()) {
            evenements.publishEvent(new EmailAEnvoyer(u.getEmail(), "YOBALEMAsn - " + sujet,
                    "Bonjour " + u.getPrenom() + ",\n\n" + message + "\n\nL'équipe YOBALEMAsn"));
        } else if (u.getTelephone() != null) {
            sms.envoyer(u.getTelephone(), "YOBALEMAsn : " + message);
        }
    }
}
