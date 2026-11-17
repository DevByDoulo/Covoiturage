package sn.isep.Convoiturage.notification;

import java.util.Map;

/** Envoi d'une notification push vers un appareil (jeton Firebase Cloud Messaging). */
public interface PushSender {

    enum Resultat {
        ENVOYE,
        /** Le jeton n'est plus valable (application désinstallée, permission retirée) : à supprimer. */
        JETON_INVALIDE,
        /** Échec passager (réseau, quota) : le jeton est conservé. */
        ECHEC
    }

    Resultat envoyer(String jeton, PlateformeAppareil plateforme, String titre, String contenu, Map<String, String> donnees);
}
