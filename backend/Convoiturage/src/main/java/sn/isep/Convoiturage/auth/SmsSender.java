package sn.isep.Convoiturage.auth;

import lombok.extern.slf4j.Slf4j;
import org.springframework.context.annotation.Profile;
import org.springframework.stereotype.Component;

/**
 * Envoi de SMS. Aucun fournisseur réel n'est encore branché (Orange SMS API, Twilio...) : à ajouter ici pour la
 * production, avec une implémentation hors des profils {@code dev} et {@code test}.
 */
public interface SmsSender {

    void envoyer(String telephone, String message);

    /** Développement et tests : le message, code compris, est écrit dans les journaux du backend. */
    @Slf4j
    @Component
    @Profile({"dev", "test"})
    class JournalSmsSender implements SmsSender {
        @Override
        public void envoyer(String telephone, String message) {
            log.info("[SMS simulé] à {} : {}", telephone, message);
        }
    }

    /**
     * Autres profils tant qu'aucun fournisseur SMS n'est branché : le SMS n'est pas envoyé et son contenu (le code de
     * vérification) n'est jamais écrit dans les journaux.
     */
    @Slf4j
    @Component
    @Profile("!dev & !test")
    class SmsNonConfigure implements SmsSender {
        @Override
        public void envoyer(String telephone, String message) {
            log.warn("SMS non envoyé à {} : aucun fournisseur SMS n'est configuré", telephone);
        }
    }
}
