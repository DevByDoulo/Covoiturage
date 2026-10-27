package sn.isep.Convoiturage.auth;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.scheduling.annotation.Async;
import org.springframework.stereotype.Component;
import org.springframework.transaction.event.TransactionalEventListener;

/**
 * Envoie les emails (codes, alertes de sécurité) en arrière-plan, une fois la transaction validée.
 * Le dialogue avec le serveur SMTP prend plusieurs secondes : l'utilisateur n'a pas à l'attendre pour
 * passer à l'écran suivant. En cas d'échec, l'erreur est journalisée et l'utilisateur peut
 * redemander un code (« Renvoyer le code »).
 */
@Slf4j
@Component
@RequiredArgsConstructor
public class ExpediteurEmails {

    /** Email à envoyer après validation de la transaction (à publier avec ApplicationEventPublisher). */
    public record EmailAEnvoyer(String email, String sujet, String texte) {}

    private final EmailSender emails;

    @Async
    @TransactionalEventListener(fallbackExecution = true)
    public void envoyer(EmailAEnvoyer email) {
        try {
            emails.envoyer(email.email(), email.sujet(), email.texte());
        } catch (RuntimeException e) {
            log.error("Email « {} » non envoyé à {} : {}", email.sujet(), email.email(), e.getMessage());
        }
    }
}
