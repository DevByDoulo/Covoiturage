package sn.isep.Convoiturage.auth;

import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.ObjectProvider;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpStatus;
import org.springframework.mail.MailException;
import org.springframework.mail.SimpleMailMessage;
import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.stereotype.Component;
import sn.isep.Convoiturage.common.ApiException;

/**
 * Envoi d'emails. Actif dès qu'un serveur SMTP est configuré ({@code spring.mail.host}, voir
 * application-local.example.yml) ; sinon {@link #disponible()} renvoie false et les codes partent par SMS.
 */
public interface EmailSender {

    boolean disponible();

    void envoyer(String email, String sujet, String texte);

    @Slf4j
    @Component
    class SmtpEmailSender implements EmailSender {

        private final ObjectProvider<JavaMailSender> mail;
        private final String expediteur;

        SmtpEmailSender(ObjectProvider<JavaMailSender> mail,
                        @Value("${app.mail.expediteur:${spring.mail.username:}}") String expediteur) {
            this.mail = mail;
            this.expediteur = expediteur;
        }

        @Override
        public boolean disponible() {
            return mail.getIfAvailable() != null;
        }

        @Override
        public void envoyer(String email, String sujet, String texte) {
            SimpleMailMessage message = new SimpleMailMessage();
            if (!expediteur.isBlank()) message.setFrom(expediteur);
            message.setTo(email);
            message.setSubject(sujet);
            message.setText(texte);
            try {
                mail.getObject().send(message);
                log.debug("Email « {} » envoyé à {}", sujet, email);
            } catch (MailException e) {
                log.error("Échec de l'envoi de l'email à {} : {}", email, e.getMessage());
                throw new ApiException(HttpStatus.SERVICE_UNAVAILABLE,
                        "Le code n'a pas pu être envoyé par email. Réessayez dans quelques instants.");
            }
        }
    }
}
