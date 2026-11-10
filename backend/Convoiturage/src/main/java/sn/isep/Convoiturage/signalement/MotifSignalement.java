package sn.isep.Convoiturage.signalement;

/** Raison pour laquelle une personne en signale une autre. */
public enum MotifSignalement {
    COMPORTEMENT,
    CONDUITE_DANGEREUSE,
    NON_PRESENTATION,
    ANNULATION_TARDIVE,
    FRAUDE_DOCUMENTS,
    HARCELEMENT,
    /** Exige une description. */
    AUTRE
}
