package sn.isep.Convoiturage.utilisateur;

/**
 * SUPPRESSION_DEMANDEE : délai de grâce de 30 jours après une demande de suppression (compte invisible, annulable
 * en se reconnectant). SUPPRIME : données personnelles anonymisées, définitif.
 */
public enum StatutCompte { EN_ATTENTE_OTP, ACTIF, BLOQUE, BANNI, DESACTIVE, SUPPRESSION_DEMANDEE, SUPPRIME }
