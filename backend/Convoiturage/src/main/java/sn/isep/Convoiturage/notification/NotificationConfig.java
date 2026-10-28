package sn.isep.Convoiturage.notification;

import com.google.auth.oauth2.GoogleCredentials;
import com.google.firebase.FirebaseApp;
import com.google.firebase.FirebaseOptions;
import com.google.firebase.messaging.FirebaseMessaging;
import com.google.firebase.messaging.FirebaseMessagingException;
import com.google.firebase.messaging.Message;
import lombok.extern.slf4j.Slf4j;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import sn.isep.Convoiturage.common.AppProperties;

import java.io.FileInputStream;
import java.io.IOException;
import java.io.InputStream;

/**
 * Choix de l'implémentation push : Firebase Cloud Messaging si un compte de service est
 * configuré (FIREBASE_CREDENTIALS_PATH), sinon simple journalisation (développement).
 */
@Slf4j
@Configuration
public class NotificationConfig {

    @Bean
    PushSender pushSender(AppProperties props) throws IOException {
        String chemin = props.firebase().credentialsPath();
        if (chemin == null || chemin.isBlank()) {
            log.warn("Firebase non configuré : les notifications push seront seulement journalisées");
            return (token, titre, contenu, donnees) ->
                    log.info("[PUSH simulé] token={} titre=\"{}\" contenu=\"{}\" donnees={}", token, titre, contenu, donnees);
        }
        FirebaseApp app;
        try (InputStream in = new FileInputStream(chemin)) {
            FirebaseOptions options = FirebaseOptions.builder().setCredentials(GoogleCredentials.fromStream(in)).build();
            app = FirebaseApp.getApps().isEmpty() ? FirebaseApp.initializeApp(options) : FirebaseApp.getInstance();
        }
        FirebaseMessaging messaging = FirebaseMessaging.getInstance(app);
        return (token, titre, contenu, donnees) -> {
            Message message = Message.builder()
                    .setToken(token)
                    .setNotification(com.google.firebase.messaging.Notification.builder().setTitle(titre).setBody(contenu).build())
                    .putAllData(donnees)
                    .build();
            try {
                messaging.send(message);
            } catch (FirebaseMessagingException e) {
                log.warn("Échec d'envoi FCM ({}) : {}", e.getMessagingErrorCode(), e.getMessage());
            }
        };
    }
}
