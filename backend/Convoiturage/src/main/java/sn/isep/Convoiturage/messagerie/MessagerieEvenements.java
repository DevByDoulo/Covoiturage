package sn.isep.Convoiturage.messagerie;

/** Événements de la messagerie, écoutés par le module notifications. */
public final class MessagerieEvenements {

    private MessagerieEvenements() {}

    /** Un message vient d'être envoyé : le destinataire est l'autre participant de la conversation. */
    public record MessageEnvoye(Long idMessage) {}
}
