package sn.isep.Convoiturage.facturation;

import lombok.extern.slf4j.Slf4j;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;
import org.springframework.http.HttpStatus;
import org.springframework.transaction.PlatformTransactionManager;
import org.springframework.transaction.TransactionDefinition;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.transaction.event.TransactionalEventListener;
import org.springframework.transaction.support.TransactionTemplate;
import sn.isep.Convoiturage.common.ApiException;
import sn.isep.Convoiturage.facturation.FacturationDtos.*;
import sn.isep.Convoiturage.facturation.FournisseurPaiement.ErreurFournisseur;
import sn.isep.Convoiturage.facturation.FournisseurPaiement.SessionPaiement;
import sn.isep.Convoiturage.reservation.*;
import sn.isep.Convoiturage.reservation.ReservationEvenements.ReservationAnnulee;
import tools.jackson.core.JacksonException;
import tools.jackson.databind.ObjectMapper;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.Comparator;
import java.util.EnumMap;
import java.util.List;
import java.util.Map;

/**
 * Facturation : paiement en ligne (Wave direct, ou Wave et Orange Money via PayDunya), suivi par webhook ou IPN,
 * vérification au retour du passager, remboursements,
 * historique et reçus. Règles actuelles (en attente de la décision de l'encadrant) : aucune commission ;
 * toute réservation annulée avant le départ est remboursée intégralement.
 */
@Slf4j
@Service
public class FacturationService implements MoyensPaiement {

    /** Fournisseur utilisé pour chaque moyen (le direct s'il est configuré, sinon PayDunya). */
    private final Map<MoyenPaiement, FournisseurPaiement> fournisseurs = new EnumMap<>(MoyenPaiement.class);
    /** Tous les fournisseurs : un paiement est suivi et remboursé par celui qui l'a encaissé. */
    private final List<FournisseurPaiement> tous;
    private final PaiementRepository paiements;
    private final ReservationRepository reservations;
    private final WaveFournisseur wave;
    private final PayDunyaClient payDunya;
    private final ObjectMapper json;
    private final TransactionTemplate transaction;

    public FacturationService(List<FournisseurPaiement> liste, PaiementRepository paiements, ReservationRepository reservations,
                              WaveFournisseur wave, PayDunyaClient payDunya, ObjectMapper json, PlatformTransactionManager tm) {
        this.tous = List.copyOf(liste);
        liste.forEach(f -> fournisseurs.merge(f.moyen(), f, (a, b) -> priorite(b) > priorite(a) ? b : a));
        this.payDunya = payDunya;
        this.paiements = paiements;
        this.reservations = reservations;
        this.wave = wave;
        this.json = json;
        // Transaction neuve : les remboursements s'exécutent aussi après la validation de la transaction appelante.
        this.transaction = new TransactionTemplate(tm);
        this.transaction.setPropagationBehavior(TransactionDefinition.PROPAGATION_REQUIRES_NEW);
        fournisseurs.values().forEach(f -> log.info("Paiement {} : {}", f.moyen(),
                f.disponible() ? "disponible (" + f.nom() + ")" : "non configuré"));
    }

    /** L'opérateur direct (sans frais d'intermédiaire) passe avant l'agrégateur ; un fournisseur non configuré, après. */
    private static int priorite(FournisseurPaiement f) {
        if (!f.disponible()) return 0;
        return PayDunyaFournisseur.NOM.equals(f.nom()) ? 1 : 2;
    }

    /** Fournisseur qui a ouvert ce paiement (paiements anciens sans nom : celui du moyen). */
    private FournisseurPaiement fournisseurDe(Paiement p) {
        return tous.stream()
                .filter(f -> f.moyen() == p.getMoyenPaiement() && f.nom().equals(p.getFournisseur()))
                .findFirst()
                .orElse(fournisseurs.get(p.getMoyenPaiement()));
    }

    // ------------------------------------------------------------------ Moyens de paiement

    @Override
    public boolean disponible(MoyenPaiement moyen) {
        if (moyen == MoyenPaiement.ESPECES) return true;
        FournisseurPaiement f = fournisseurs.get(moyen);
        return f != null && f.disponible();
    }

    public List<MoyenPaiementDto> moyens() {
        return Arrays.stream(MoyenPaiement.values()).map(m -> new MoyenPaiementDto(m, disponible(m))).toList();
    }

    // ------------------------------------------------------------------ Paiement par le passager

    /**
     * Ouvre (ou rouvre après un échec) le paiement en ligne d'une réservation acceptée, ou bascule en espèces.
     * Pour Wave, le passager est ensuite redirigé vers {@code urlPaiement}.
     */
    @Transactional
    public SessionPaiementDto payer(Long passagerId, Long reservationId, PaiementRequete req) {
        Reservation r = reservations.findById(reservationId).orElseThrow(() -> ApiException.notFound("Réservation introuvable"));
        if (!r.getPassager().getId().equals(passagerId)) throw ApiException.notFound("Réservation introuvable");
        if (r.getStatut() != StatutReservation.ACCEPTEE) {
            throw ApiException.conflict("Le paiement est possible une fois la réservation acceptée par le conducteur");
        }
        Paiement p = paiements.findFirstByReservationIdOrderByDateInitiationDesc(r.getId()).orElseThrow();
        if (p.getStatut() == StatutPaiement.REUSSI) throw ApiException.conflict("Cette réservation est déjà payée");
        if (p.getStatut() != StatutPaiement.EN_ATTENTE && p.getStatut() != StatutPaiement.ECHOUE) {
            throw ApiException.conflict("Ce paiement ne peut plus être modifié");
        }
        MoyenPaiement moyen = req != null && req.moyen() != null ? req.moyen() : p.getMoyenPaiement();
        if (!disponible(moyen)) {
            throw ApiException.badRequest("Ce moyen de paiement n'est pas disponible pour le moment").surChamp("moyen");
        }
        p.setMoyenPaiement(moyen);
        p.setStatut(StatutPaiement.EN_ATTENTE);
        if (moyen == MoyenPaiement.ESPECES) {
            p.setFournisseur(null);
            p.setReferenceExterne(null);
            return new SessionPaiementDto(p.getReferenceTransaction(), moyen, p.getStatut(), p.getMontant(), null);
        }
        FournisseurPaiement f = fournisseurs.get(moyen);
        SessionPaiement s;
        try {
            s = f.ouvrirSession(p);
        } catch (ErreurFournisseur e) {
            log.warn("Ouverture du paiement {} impossible ({}) : {}", moyen, p.getReferenceTransaction(), e.getMessage());
            throw new ApiException(HttpStatus.BAD_GATEWAY,
                    "Le service de paiement ne répond pas. Réessayez dans quelques instants ou payez en espèces.");
        }
        p.setFournisseur(f.nom());
        p.setReferenceExterne(s.referenceExterne());
        p.setDateInitiation(LocalDateTime.now());
        return new SessionPaiementDto(p.getReferenceTransaction(), moyen, p.getStatut(), p.getMontant(), s.urlPaiement());
    }

    // ------------------------------------------------------------------ Webhook Wave

    /**
     * Notification de Wave. La signature est vérifiée sur le corps brut ; le traitement est idempotent
     * (Wave peut renvoyer le même événement). Un paiement arrivé après l'annulation de la réservation est remboursé.
     */
    public void webhookWave(String signature, String corpsBrut) {
        if (!wave.signatureValide(signature, corpsBrut)) {
            throw ApiException.unauthorized("Signature Wave invalide");
        }
        WaveFournisseur.Evenement e;
        try {
            e = json.readValue(corpsBrut, WaveFournisseur.Evenement.class);
        } catch (JacksonException ex) {
            throw ApiException.badRequest("Événement Wave illisible");
        }
        if (e.data() == null || e.data().clientReference() == null) {
            log.info("Événement Wave {} ignoré ({})", e.id(), e.type());
            return;
        }
        Boolean aRembourser = transaction.execute(t -> appliquerEvenementWave(e));
        if (Boolean.TRUE.equals(aRembourser)) rembourser(e.data().clientReference());
    }

    /** @return vrai si le paiement vient d'aboutir alors que la réservation n'est plus active (à rembourser). */
    private boolean appliquerEvenementWave(WaveFournisseur.Evenement e) {
        Paiement p = paiements.findByReferenceTransaction(e.data().clientReference()).orElse(null);
        if (p == null || p.getMoyenPaiement() != MoyenPaiement.WAVE) {
            log.warn("Événement Wave {} : paiement {} inconnu", e.id(), e.data().clientReference());
            return false;
        }
        switch (e.type()) {
            case "checkout.session.completed" -> {
                if (p.getStatut() == StatutPaiement.REUSSI || p.getStatut() == StatutPaiement.REMBOURSE
                        || p.getStatut() == StatutPaiement.REMBOURSEMENT_DEMANDE) return false;
                p.setStatut(StatutPaiement.REUSSI);
                p.setReferenceExterne(e.data().id());
                p.setDateConfirmation(LocalDateTime.now());
                log.info("Paiement Wave reçu : {} ({} FCFA)", p.getReferenceTransaction(), p.getMontant());
                return !p.getReservation().estActive();
            }
            case "checkout.session.payment_failed" -> {
                if (p.getStatut() == StatutPaiement.EN_ATTENTE) p.setStatut(StatutPaiement.ECHOUE);
                return false;
            }
            default -> {
                log.info("Événement Wave {} ignoré ({})", e.id(), e.type());
                return false;
            }
        }
    }

    // ------------------------------------------------------------------ PayDunya : IPN et vérification

    /**
     * IPN de PayDunya (formulaire {@code data[...]}). On vérifie {@code data[hash]} (SHA-512 de la clé principale),
     * puis on redemande l'état de la facture à PayDunya plutôt que de croire le statut reçu.
     */
    public void ipnPayDunya(Map<String, String> formulaire) {
        if (!payDunya.hashValide(formulaire.get("data[hash]"))) {
            throw ApiException.unauthorized("Notification PayDunya non authentifiée");
        }
        String token = formulaire.get("data[invoice][token]");
        if (token == null) {
            log.info("IPN PayDunya sans facture ignorée");
            return;
        }
        Paiement p = transaction.execute(t -> paiements.findByReferenceExterne(token).orElse(null));
        if (p == null || !PayDunyaFournisseur.NOM.equals(p.getFournisseur())) {
            log.warn("IPN PayDunya : facture {} inconnue", token);
            return;
        }
        synchroniser(p.getReferenceTransaction());
    }

    /**
     * Retour du passager sur l'application après paiement : on demande l'état du paiement à l'opérateur (utile
     * quand l'IPN ne peut pas joindre l'API, par exemple en local). Renvoie le statut à jour.
     */
    public StatutPaiement verifier(Long passagerId, String reference) {
        Paiement p = transaction.execute(t -> paiements.findByReferenceTransaction(reference)
                .filter(x -> x.getReservation().getPassager().getId().equals(passagerId)).orElse(null));
        if (p == null) throw ApiException.notFound("Paiement introuvable");
        return synchroniser(reference);
    }

    /** Met le paiement à jour d'après l'opérateur (appel hors transaction), et rembourse un paiement arrivé trop tard. */
    private StatutPaiement synchroniser(String reference) {
        Paiement p = transaction.execute(t -> paiements.findByReferenceTransaction(reference).orElse(null));
        if (p == null) return null;
        if (p.getStatut() != StatutPaiement.EN_ATTENTE && p.getStatut() != StatutPaiement.ECHOUE) return p.getStatut();
        if (p.getMoyenPaiement() == MoyenPaiement.ESPECES) return p.getStatut();
        StatutPaiement resultat;
        try {
            resultat = fournisseurDe(p).verifier(p);
        } catch (ErreurFournisseur e) {
            log.warn("Vérification du paiement {} impossible : {}", reference, e.getMessage());
            return p.getStatut();
        }
        if (resultat == null) return p.getStatut();
        Boolean aRembourser = transaction.execute(t -> appliquerResultat(reference, resultat));
        if (Boolean.TRUE.equals(aRembourser)) rembourser(reference);
        return transaction.execute(t -> paiements.findByReferenceTransaction(reference).map(Paiement::getStatut).orElse(null));
    }

    /** @return vrai si le paiement vient d'aboutir alors que la réservation n'est plus active (à rembourser). */
    private boolean appliquerResultat(String reference, StatutPaiement resultat) {
        Paiement p = paiements.findByReferenceTransaction(reference).orElse(null);
        if (p == null) return false;
        boolean ouvert = p.getStatut() == StatutPaiement.EN_ATTENTE || p.getStatut() == StatutPaiement.ECHOUE;
        if (resultat == StatutPaiement.REUSSI && ouvert) {
            p.setStatut(StatutPaiement.REUSSI);
            p.setDateConfirmation(LocalDateTime.now());
            log.info("Paiement {} reçu via {} ({} FCFA)", reference, p.getFournisseur(), p.getMontant());
            return !p.getReservation().estActive();
        }
        if (resultat == StatutPaiement.ECHOUE && p.getStatut() == StatutPaiement.EN_ATTENTE) p.setStatut(StatutPaiement.ECHOUE);
        return false;
    }

    // ------------------------------------------------------------------ Remboursements

    /** Annulation avant le départ : remboursement intégral des paiements en ligne déjà réglés (après validation). */
    @TransactionalEventListener
    public void surReservationAnnulee(ReservationAnnulee e) {
        if (!e.avantDepart()) return;
        paiements.findFirstByReservationIdOrderByDateInitiationDesc(e.idReservation())
                .filter(p -> p.getStatut() == StatutPaiement.REUSSI && p.getMoyenPaiement() != MoyenPaiement.ESPECES)
                .ifPresent(p -> rembourser(p.getReferenceTransaction()));
    }

    /** Relance régulière des remboursements que l'opérateur n'a pas pu traiter. */
    @Scheduled(fixedDelayString = "${app.paiement.relance-remboursements:PT10M}", initialDelayString = "PT1M")
    public void relancerRemboursements() {
        paiements.findByStatut(StatutPaiement.REMBOURSEMENT_DEMANDE)
                .forEach(p -> rembourser(p.getReferenceTransaction()));
    }

    /** Appelle l'opérateur hors de toute transaction, puis enregistre le résultat. */
    void rembourser(String reference) {
        // Passager chargé dans la transaction : le remboursement PayDunya a besoin de son numéro.
        Paiement p = transaction.execute(t -> paiements.findByReferenceTransaction(reference)
                .map(x -> {
                    x.getReservation().getPassager().getTelephone();
                    return x;
                }).orElse(null));
        if (p == null || p.getMoyenPaiement() == MoyenPaiement.ESPECES) return;
        StatutPaiement resultat;
        try {
            fournisseurDe(p).rembourser(p);
            resultat = StatutPaiement.REMBOURSE;
            log.info("Remboursement {} effectué ({} FCFA)", reference, p.getMontant());
        } catch (RuntimeException ex) {
            resultat = StatutPaiement.REMBOURSEMENT_DEMANDE;
            log.warn("Remboursement {} en attente, nouvel essai plus tard : {}", reference, ex.getMessage());
        }
        StatutPaiement statut = resultat;
        transaction.executeWithoutResult(t -> paiements.findByReferenceTransaction(reference).ifPresent(x -> {
            x.setStatut(statut);
            if (statut == StatutPaiement.REMBOURSE) x.setDateRemboursement(LocalDateTime.now());
        }));
    }

    // ------------------------------------------------------------------ Historique et reçus

    /** Paiements effectués (comme passager) et encaissements (comme conducteur), du plus récent au plus ancien. */
    @Transactional(readOnly = true)
    public List<PaiementDto> historique(Long utilisateurId) {
        List<PaiementDto> liste = new ArrayList<>();
        paiements.findByReservationPassagerIdOrderByDateInitiationDesc(utilisateurId)
                .forEach(p -> liste.add(PaiementDto.de(p, false)));
        paiements.findByReservationTrajetConducteurIdOrderByDateInitiationDesc(utilisateurId)
                .forEach(p -> liste.add(PaiementDto.de(p, true)));
        liste.sort(Comparator.comparing(PaiementDto::dateInitiation).reversed());
        return liste;
    }

    /** Reçu d'un paiement réglé ou remboursé, visible par le passager et le conducteur concernés. */
    @Transactional(readOnly = true)
    public RecuDto recu(Long utilisateurId, String reference) {
        Paiement p = paiements.findByReferenceTransaction(reference).orElseThrow(() -> ApiException.notFound("Paiement introuvable"));
        Reservation r = p.getReservation();
        boolean concerne = r.getPassager().getId().equals(utilisateurId)
                || r.getTrajet().getConducteur().getId().equals(utilisateurId);
        if (!concerne) throw ApiException.notFound("Paiement introuvable");
        if (p.getStatut() != StatutPaiement.REUSSI && p.getStatut() != StatutPaiement.REMBOURSE) {
            throw ApiException.conflict("Le reçu est disponible une fois le paiement réglé");
        }
        return RecuDto.de(p);
    }
}
