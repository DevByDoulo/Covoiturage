package sn.isep.Convoiturage.signalement;

/** Avancement du traitement d'un signalement par l'administration. */
public enum StatutSignalement {
    EN_ATTENTE, EN_COURS,
    /** Une mesure a été prise (avertissement, blocage ou bannissement). */
    TRAITE,
    /** Classé sans suite. */
    REJETE;

    public boolean estOuvert() {
        return this == EN_ATTENTE || this == EN_COURS;
    }
}
