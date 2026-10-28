package sn.isep.Convoiturage.notification;

import java.util.Map;

/** Envoi d'une notification push vers un appareil (jeton FCM). */
public interface PushSender {

    void envoyer(String fcmToken, String titre, String contenu, Map<String, String> donnees);
}
