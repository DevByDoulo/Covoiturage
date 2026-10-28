package sn.isep.Convoiturage.reservation;

/**
 * Événements publiés par le module réservation. Le module facturation (remboursements) les écoute déjà ;
 * le module 06 Notifications pourra les écouter pour prévenir passagers et conducteurs.
 * Ainsi, réservation ne dépend ni de la facturation ni des notifications.
 */
public final class ReservationEvenements {

    private ReservationEvenements() {}

    /** Demande en attente de la réponse du conducteur (mode manuel). */
    public record ReservationDemandee(Long idReservation) {}

    /** Places attribuées (acceptation par le conducteur, ou immédiatement en mode automatique). */
    public record ReservationAcceptee(Long idReservation) {}

    public record ReservationRefusee(Long idReservation, String motif) {}

    /**
     * Réservation annulée (par le passager, ou parce que le conducteur a annulé le trajet).
     * avantDepart = vrai si l'annulation a lieu avant le départ : le passager est alors remboursé intégralement.
     */
    public record ReservationAnnulee(Long idReservation, String motif, boolean avantDepart) {}

    public record EmbarquementConfirme(Long idReservation) {}
}
