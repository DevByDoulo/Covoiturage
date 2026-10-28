package sn.isep.Convoiturage.notification;

/** Événements signalés à l'utilisateur (icône et regroupement côté interface). */
public enum TypeNotification {
    RESERVATION_DEMANDEE,
    RESERVATION_CONFIRMEE,
    RESERVATION_REFUSEE,
    RESERVATION_ANNULEE,
    TRAJET_MODIFIE,
    TRAJET_ANNULE,
    /** Rappel envoyé une heure avant le départ, au conducteur et à ses passagers. */
    RAPPEL_TRAJET,
    EMBARQUEMENT_CONFIRME,
    DOCUMENT_VALIDE,
    DOCUMENT_REFUSE,
    COMPTE_SUSPENDU,
    COMPTE_REACTIVE,
    /** Un trajet correspondant à une alerte de recherche vient d'être publié. */
    ALERTE_TRAJET
}
