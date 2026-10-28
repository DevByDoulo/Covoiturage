package sn.isep.Convoiturage.reservation;

/**
 * Moyens de paiement réellement utilisables (Wave / Orange Money seulement si leur API est configurée).
 * Implémenté par le module facturation : réservation n'en dépend pas directement.
 */
public interface MoyensPaiement {

    boolean disponible(MoyenPaiement moyen);
}
