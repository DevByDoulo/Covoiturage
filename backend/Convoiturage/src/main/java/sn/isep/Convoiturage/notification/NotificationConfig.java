package sn.isep.Convoiturage.notification;

import com.google.auth.oauth2.GoogleCredentials;
import com.google.firebase.FirebaseApp;
import com.google.firebase.FirebaseOptions;
import com.google.firebase.messaging.AndroidConfig;
import com.google.firebase.messaging.AndroidNotification;
import com.google.firebase.messaging.FirebaseMessaging;
import com.google.firebase.messaging.FirebaseMessagingException;
import com.google.firebase.messaging.Message;
import com.google.firebase.messaging.MessagingErrorCode;
import com.google.firebase.messaging.WebpushConfig;
import lombok.extern.slf4j.Slf4j;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import sn.isep.Convoiturage.common.AppProperties;

import java.io.FileInputStream;
import java.io.IOException;
import java.io.InputStream;
import java.util.HashMap;
import java.util.Map;
import java.util.Set;

/**
 * Choix de l'implémentation push : Firebase Cloud Messaging si un compte de service est configuré
 * ({@code app.firebase.credentials-path} / FIREBASE_CREDENTIALS_PATH, fichier hors du dépôt), sinon simple
 * journalisation (développement, tests).
 */
@Slf4j
@Configuration
public class NotificationConfig {

    /** Canal Android créé par l'application mobile (lib/core/push.dart). */
    static final String CANAL_ANDROID = "yobalema_notifications";

    private static final Set<MessagingErrorCode> JETON_INVALIDE = Set.of(
            MessagingErrorCode.UNREGISTERED, MessagingErrorCode.INVALID_ARGUMENT, MessagingErrorCode.SENDER_ID_MISMATCH);

    @Bean
    PushSender pushSender(AppProperties props) {
        String chemin = props.firebase().credentialsPath();
        if (chemin == null || chemin.isBlank()) {
            log.warn("Firebase non configuré : les notifications push seront seulement journalisées");
            return simule();
        }
        FirebaseMessaging messaging;
        try (InputStream in = new FileInputStream(chemin)) {
            FirebaseOptions options = FirebaseOptions.builder().setCredentials(GoogleCredentials.fromStream(in)).build();
            FirebaseApp app = FirebaseApp.getApps().isEmpty() ? FirebaseApp.initializeApp(options) : FirebaseApp.getInstance();
            messaging = FirebaseMessaging.getInstance(app);
        } catch (IOException | RuntimeException e) {
            log.error("Compte de service Firebase illisible : les notifications push seront seulement journalisées ({})",
                    e.getMessage());
            return simule();
        }
        log.info("Notifications push Firebase Cloud Messaging activées");
        return (jeton, plateforme, titre, contenu, donnees) -> {
            try {
                messaging.send(message(jeton, plateforme, titre, contenu, donnees));
                return PushSender.Resultat.ENVOYE;
            } catch (FirebaseMessagingException e) {
                if (JETON_INVALIDE.contains(e.getMessagingErrorCode())) return PushSender.Resultat.JETON_INVALIDE;
                log.warn("Échec d'envoi FCM ({}) : {}", e.getMessagingErrorCode(), e.getMessage());
                return PushSender.Resultat.ECHEC;
            }
        };
    }

    private static PushSender simule() {
        return (jeton, plateforme, titre, contenu, donnees) -> {
            log.info("[PUSH simulé] {} titre=\"{}\" contenu=\"{}\" donnees={}", plateforme, titre, contenu, donnees);
            return PushSender.Resultat.ENVOYE;
        };
    }

    /**
     * Android / iOS : notification affichée par le système + données (lien de l'écran à ouvrir).
     * Navigateur : données seules, affichées par le service worker (public/firebase-messaging-sw.js), qui ouvre le lien.
     */
    static Message message(String jeton, PlateformeAppareil plateforme, String titre, String contenu,
                           Map<String, String> donnees) {
        Message.Builder m = Message.builder().setToken(jeton);
        if (plateforme == PlateformeAppareil.WEB) {
            Map<String, String> tout = new HashMap<>(donnees);
            tout.put("titre", titre);
            tout.put("contenu", contenu);
            return m.putAllData(tout)
                    .setWebpushConfig(WebpushConfig.builder().putHeader("Urgency", "high").build())
                    .build();
        }
        return m.setNotification(com.google.firebase.messaging.Notification.builder().setTitle(titre).setBody(contenu).build())
                .putAllData(donnees)
                .setAndroidConfig(AndroidConfig.builder()
                        .setPriority(AndroidConfig.Priority.HIGH)
                        .setNotification(AndroidNotification.builder().setChannelId(CANAL_ANDROID).build())
                        .build())
                .build();
    }
}
