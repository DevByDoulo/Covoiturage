package sn.isep.Convoiturage.avis;

/** Événements du module avis, que le module 06 Notifications peut écouter (« Vous avez reçu un avis »). */
public final class AvisEvenements {

    private AvisEvenements() {}

    public record AvisPublie(Long idEvaluation, Long idEvalue, int note) {}
}
