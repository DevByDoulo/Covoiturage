package sn.isep.Convoiturage.trajet;

/**
 * Événements publiés par le module trajet et traités (dans la même transaction) par le module
 * réservation : notification des passagers, annulation/clôture des réservations.
 * Cela évite une dépendance directe trajet -> réservation.
 */
public final class TrajetEvenements {

    private TrajetEvenements() {}

    /** Nouveau trajet : déclenche les alertes de recherche (module recherche), après validation de la transaction. */
    public record TrajetPublie(Long idTrajet) {}

    public record TrajetModifie(Long idTrajet, String changements) {}

    public record TrajetAnnule(Long idTrajet, String motif) {}

    public record TrajetTermine(Long idTrajet) {}
}
