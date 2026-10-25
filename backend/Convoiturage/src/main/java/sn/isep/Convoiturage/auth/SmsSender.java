package sn.isep.Convoiturage.auth;

import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;

/**
 * Envoi de SMS. L'implémentation par défaut écrit le message dans les logs (développement) ;
 * brancher ici un fournisseur réel (Orange SMS API, Twilio...) pour la production.
 */
public interface SmsSender {

    void envoyer(String telephone, String message);

    @Slf4j
    @Component
    class JournalSmsSender implements SmsSender {
        @Override
        public void envoyer(String telephone, String message) {
            log.info("[SMS simulé] à {} : {}", telephone, message);
        }
    }
}
