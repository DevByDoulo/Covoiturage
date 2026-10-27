package sn.isep.Convoiturage.facturation;

import org.springframework.stereotype.Component;
import sn.isep.Convoiturage.reservation.MoyenPaiement;
import sn.isep.Convoiturage.reservation.Paiement;

/**
 * Orange Money Sénégal (Sonatel) — À BRANCHER.
 * <p>
 * L'API marchande de Sonatel (création du paiement par QR code / lien Max It, notification du résultat,
 * remboursement) n'est documentée qu'aux comptes du portail https://developer.orange-sonatel.com
 * (environnement de test gratuit ; la production exige RCCM, NINEA et pièces d'identité).
 * Tant que cette documentation n'est pas disponible, Orange Money n'est pas proposé aux passagers
 * ({@link #disponible()} renvoie toujours faux), même si des identifiants sont renseignés.
 * Pour le brancher : implémenter {@link #ouvrirSession} et {@link #rembourser} d'après la documentation
 * Sonatel, ajouter le webhook dans {@link FacturationController} et retirer la condition ci-dessous.
 */
@Component
public class OrangeMoneyFournisseur implements FournisseurPaiement {

    static final boolean API_IMPLEMENTEE = false;

    private final PaiementProperties props;

    public OrangeMoneyFournisseur(PaiementProperties props) {
        this.props = props;
    }

    @Override
    public MoyenPaiement moyen() {
        return MoyenPaiement.ORANGE_MONEY;
    }

    @Override
    public boolean disponible() {
        return API_IMPLEMENTEE && props.orangeMoney().configure();
    }

    @Override
    public SessionPaiement ouvrirSession(Paiement paiement) {
        throw new ErreurFournisseur("Le paiement Orange Money n'est pas encore disponible");
    }

    @Override
    public void rembourser(Paiement paiement) {
        throw new ErreurFournisseur("Le remboursement Orange Money n'est pas encore disponible");
    }
}
