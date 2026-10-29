package sn.isep.Convoiturage.facturation;

import lombok.extern.slf4j.Slf4j;
import sn.isep.Convoiturage.facturation.PayDunyaClient.Actions;
import sn.isep.Convoiturage.facturation.PayDunyaClient.Facture;
import sn.isep.Convoiturage.facturation.PayDunyaClient.FactureCreee;
import sn.isep.Convoiturage.facturation.PayDunyaClient.Invoice;
import sn.isep.Convoiturage.facturation.PayDunyaClient.Reponse;
import sn.isep.Convoiturage.facturation.PayDunyaClient.Store;
import sn.isep.Convoiturage.reservation.MoyenPaiement;
import sn.isep.Convoiturage.reservation.Paiement;
import sn.isep.Convoiturage.reservation.StatutPaiement;
import sn.isep.Convoiturage.trajet.Trajet;

import java.math.RoundingMode;
import java.util.List;
import java.util.Map;

/**
 * Wave ou Orange Money Sénégal par l'intermédiaire de PayDunya : la page de paiement PayDunya ne propose que le
 * canal choisi par le passager. Deux instances (une par moyen), déclarées dans {@link PayDunyaConfig}.
 * Quand PayDunya est configuré, il est préféré au fournisseur direct du même moyen (voir FacturationService).
 */
@Slf4j
public class PayDunyaFournisseur implements FournisseurPaiement {

    static final String NOM = "PAYDUNYA";
    static final String CHEMIN_IPN = "/api/paiements/webhooks/paydunya";

    private final MoyenPaiement moyen;
    private final PayDunyaClient client;
    private final PaiementProperties props;

    public PayDunyaFournisseur(MoyenPaiement moyen, PayDunyaClient client, PaiementProperties props) {
        this.moyen = moyen;
        this.client = client;
        this.props = props;
    }

    /** Canal PayDunya du moyen : page de paiement et déboursement. */
    String canal() {
        return switch (moyen) {
            case WAVE -> "wave-senegal";
            case ORANGE_MONEY -> "orange-money-senegal";
            case ESPECES -> throw new IllegalStateException("Pas de canal PayDunya pour les espèces");
        };
    }

    @Override
    public MoyenPaiement moyen() {
        return moyen;
    }

    @Override
    public String nom() {
        return NOM;
    }

    @Override
    public boolean disponible() {
        return props.paydunya().configure() && props.urlRetour() != null && !props.urlRetour().isBlank();
    }

    @Override
    public SessionPaiement ouvrirSession(Paiement p) {
        if (!disponible()) throw new ErreurFournisseur("PayDunya n'est pas configuré sur ce serveur");
        String retour = props.urlRetour().replaceAll("/+$", "") + "/reservations?paiement=";
        String ref = p.getReferenceTransaction();
        Trajet t = p.getReservation().getTrajet();
        int places = p.getReservation().getNombrePlaces();
        Facture facture = new Facture(
                new Invoice(p.getMontant().setScale(0, RoundingMode.HALF_UP).longValueExact(),
                        "Covoiturage " + t.getLieuDepart() + " → " + t.getLieuArrivee() + " (" + places
                                + (places > 1 ? " places)" : " place)"),
                        List.of(canal())),
                new Store("YOBALEMAsn", props.urlRetour()),
                Map.of("reference", ref),
                new Actions(retour + "echec&ref=" + ref, retour + "succes&ref=" + ref, urlIpn()));
        FactureCreee f = client.creerFacture(facture);
        return new SessionPaiement(f.token(), f.url());
    }

    @Override
    public StatutPaiement verifier(Paiement p) {
        if (p.getReferenceExterne() == null) return null;
        Reponse r = client.confirmer(p.getReferenceExterne());
        Object reference = r.customData() == null ? null : r.customData().get("reference");
        if (reference != null && !p.getReferenceTransaction().equals(reference.toString())) {
            log.warn("Facture PayDunya {} : référence {} inattendue pour {}", p.getReferenceExterne(), reference,
                    p.getReferenceTransaction());
            return null;
        }
        String statut = r.status() == null ? "" : r.status().toLowerCase();
        return switch (statut) {
            case "completed" -> StatutPaiement.REUSSI;
            case "cancelled", "failed" -> StatutPaiement.ECHOUE;
            default -> StatutPaiement.EN_ATTENTE;
        };
    }

    @Override
    public void rembourser(Paiement p) {
        String telephone = p.getReservation().getPassager().getTelephone();
        if (telephone == null) throw new ErreurFournisseur("Numéro du passager inconnu pour " + p.getReferenceTransaction());
        String numeroLocal = telephone.replaceAll("\\D", "").replaceFirst("^221(?=\\d{9}$)", "");
        String rappel = urlIpn() != null ? urlIpn() : props.urlRetour();
        client.debourser(numeroLocal, p.getMontant().setScale(0, RoundingMode.HALF_UP).longValueExact(), canal(), rappel,
                p.getReferenceTransaction());
    }

    /** Adresse de l'IPN, si l'API a une adresse publique ; sinon le paiement est vérifié au retour du passager. */
    private String urlIpn() {
        String api = props.urlApi();
        return api == null || api.isBlank() ? null : api.replaceAll("/+$", "") + CHEMIN_IPN;
    }
}
