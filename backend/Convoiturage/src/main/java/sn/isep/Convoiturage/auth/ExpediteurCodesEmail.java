package sn.isep.Convoiturage.auth;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.scheduling.annotation.Async;
import org.springframework.stereotype.Component;
import org.springframework.transaction.event.TransactionalEventListener;

/**
 * Envoie les codes par email en arrière-plan, une fois la transaction validée (compte et code enregistrés).
 * Le dialogue avec le serveur SMTP prend plusieurs secondes : l'utilisateur n'a pas à l'attendre pour
 * passer à l'écran de saisie du code. En cas d'échec, l'erreur est journalisée et l'utilisateur peut
 * redemander un code (« Renvoyer le code »).
 */
@Slf4j
@Component
@RequiredArgsConstructor
class ExpediteurCodesEmail {

    /** Email de code à envoyer après validation de la transaction. */
    record CodeAEnvoyer(String email, String sujet, String texte) {}

    private final EmailSender emails;

    @Async
    @TransactionalEventListener(fallbackExecution = true)
    public void envoyer(CodeAEnvoyer code) {
        try {
            emails.envoyer(code.email(), code.sujet(), code.texte());
        } catch (RuntimeException e) {
            log.error("Code de vérification non envoyé à {} : {}", code.email(), e.getMessage());
        }
    }
}
