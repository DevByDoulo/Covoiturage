package sn.isep.Convoiturage.facturation;

import sn.isep.Convoiturage.reservation.MoyenPaiement;
import sn.isep.Convoiturage.reservation.Paiement;

/** Paiement en ligne auprès d'un opérateur (Wave, Orange Money). */
public interface FournisseurPaiement {

    MoyenPaiement moyen();

    /** Faux tant que les clés de l'opérateur ne sont pas renseignées : le moyen n'est alors pas proposé. */
    boolean disponible();

    /**
     * Ouvre une session de paiement pour ce montant.
     * @return identifiant de la session chez l'opérateur et adresse à ouvrir par le passager pour payer
     */
    SessionPaiement ouvrirSession(Paiement paiement);

    /** Rembourse intégralement un paiement réussi. Lève une exception si l'opérateur refuse ou ne répond pas. */
    void rembourser(Paiement paiement);

    record SessionPaiement(String referenceExterne, String urlPaiement) {}

    /** Erreur de l'opérateur (réseau, refus, configuration). */
    class ErreurFournisseur extends RuntimeException {
        public ErreurFournisseur(String message, Throwable cause) {
            super(message, cause);
        }

        public ErreurFournisseur(String message) {
            super(message);
        }
    }
}
