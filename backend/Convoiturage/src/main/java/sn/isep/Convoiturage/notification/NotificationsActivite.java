package sn.isep.Convoiturage.notification;

import jakarta.persistence.EntityManager;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;
import org.springframework.transaction.event.TransactionPhase;
import org.springframework.transaction.event.TransactionalEventListener;
import sn.isep.Convoiturage.avis.AvisEvenements.AvisPublie;
import sn.isep.Convoiturage.avis.Evaluation;
import sn.isep.Convoiturage.messagerie.Message;
import sn.isep.Convoiturage.messagerie.MessagerieEvenements.MessageEnvoye;
import sn.isep.Convoiturage.utilisateur.Utilisateur;
import sn.isep.Convoiturage.reservation.Reservation;
import sn.isep.Convoiturage.reservation.ReservationEvenements.*;
import sn.isep.Convoiturage.reservation.ReservationRepository;
import sn.isep.Convoiturage.reservation.StatutReservation;
import sn.isep.Convoiturage.trajet.ModeReservation;
import sn.isep.Convoiturage.trajet.StatutTrajet;
import sn.isep.Convoiturage.trajet.Trajet;
import sn.isep.Convoiturage.trajet.TrajetEvenements.TrajetModifie;
import sn.isep.Convoiturage.trajet.TrajetRepository;

import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.List;
import java.util.Locale;

/**
 * Traduit les événements des modules réservation, trajet, avis et messagerie en notifications. Les écouteurs s'exécutent juste avant
 * la validation de la transaction métier : la notification est enregistrée avec le changement qu'elle annonce, ou
 * pas du tout. Ces modules ne dépendent pas des notifications.
 */
@Component
@RequiredArgsConstructor
class NotificationsActivite {

    private static final DateTimeFormatter DATE = DateTimeFormatter.ofPattern("EEEE d MMMM 'à' HH'h'mm", Locale.FRENCH);
    private static final List<StatutReservation> ACTIVES = List.of(StatutReservation.EN_ATTENTE, StatutReservation.ACCEPTEE);

    private final NotificationService notifications;
    private final ReservationRepository reservations;
    private final TrajetRepository trajets;
    private final EntityManager em;

    // ------------------------------------------------------------------ Réservations

    @TransactionalEventListener(phase = TransactionPhase.BEFORE_COMMIT)
    public void surDemande(ReservationDemandee e) {
        Reservation r = reservation(e.idReservation());
        Trajet t = r.getTrajet();
        notifications.notifier(t.getConducteur(), TypeNotification.RESERVATION_DEMANDEE, Priorite.IMPORTANTE,
                "Nouvelle demande de réservation",
                r.getPassager().getPrenom() + " demande " + places(r.getNombrePlaces()) + " pour " + trajet(t)
                        + ". Acceptez ou refusez la demande au plus vite.",
                lienTrajet(t));
    }

    /** Passager : sa place est confirmée. Conducteur, en mode automatique : une place vient d'être prise. */
    @TransactionalEventListener(phase = TransactionPhase.BEFORE_COMMIT)
    public void surAcceptation(ReservationAcceptee e) {
        Reservation r = reservation(e.idReservation());
        Trajet t = r.getTrajet();
        notifications.notifier(r.getPassager(), TypeNotification.RESERVATION_CONFIRMEE, Priorite.IMPORTANTE,
                "Réservation confirmée",
                "Votre réservation (" + places(r.getNombrePlaces()) + ") pour " + trajet(t) + " est confirmée. "
                        + "Votre code d'embarquement est dans « Réservations ».",
                "/reservations");
        if (t.getModeReservation() == ModeReservation.AUTOMATIQUE) {
            notifications.notifier(t.getConducteur(), TypeNotification.RESERVATION_CONFIRMEE, Priorite.NORMALE,
                    "Nouvelle réservation",
                    r.getPassager().getPrenom() + " a réservé " + places(r.getNombrePlaces()) + " pour " + trajet(t) + ".",
                    lienTrajet(t));
        }
    }

    @TransactionalEventListener(phase = TransactionPhase.BEFORE_COMMIT)
    public void surRefus(ReservationRefusee e) {
        Reservation r = reservation(e.idReservation());
        notifications.notifier(r.getPassager(), TypeNotification.RESERVATION_REFUSEE, Priorite.NORMALE,
                "Demande refusée",
                "Le conducteur n'a pas accepté votre demande pour " + trajet(r.getTrajet())
                        + (vide(e.motif()) ? "." : " : « " + e.motif() + " ».") + " D'autres trajets vous attendent.",
                "/rechercher");
    }

    /**
     * Trajet annulé par le conducteur : chaque passager est prévenu (important). Annulation par le passager : le
     * conducteur est prévenu. Passager absent au départ : il est informé que sa réservation est close.
     */
    @TransactionalEventListener(phase = TransactionPhase.BEFORE_COMMIT)
    public void surAnnulation(ReservationAnnulee e) {
        Reservation r = reservation(e.idReservation());
        Trajet t = r.getTrajet();
        if (t.getStatut() == StatutTrajet.ANNULE) {
            notifications.notifier(r.getPassager(), TypeNotification.TRAJET_ANNULE, Priorite.IMPORTANTE,
                    "Trajet annulé",
                    "Le conducteur a annulé " + trajet(t) + (vide(t.getMotifAnnulation()) ? "." : " : « " + t.getMotifAnnulation() + " ».")
                            + (e.avantDepart() ? " Si vous aviez payé en ligne, vous êtes remboursé intégralement." : ""),
                    "/rechercher");
        } else if (e.avantDepart()) {
            notifications.notifier(t.getConducteur(), TypeNotification.RESERVATION_ANNULEE, Priorite.NORMALE,
                    "Réservation annulée",
                    r.getPassager().getPrenom() + " a annulé sa réservation (" + places(r.getNombrePlaces()) + ") pour "
                            + trajet(t) + ". Les places sont de nouveau proposées.",
                    lienTrajet(t));
        } else {
            notifications.notifier(r.getPassager(), TypeNotification.RESERVATION_ANNULEE, Priorite.NORMALE,
                    "Réservation close",
                    "Votre embarquement n'a pas été confirmé pour " + trajet(t) + " : la réservation est close.",
                    "/reservations");
        }
    }

    @TransactionalEventListener(phase = TransactionPhase.BEFORE_COMMIT)
    public void surEmbarquement(EmbarquementConfirme e) {
        Reservation r = reservation(e.idReservation());
        notifications.notifier(r.getPassager(), TypeNotification.EMBARQUEMENT_CONFIRME, Priorite.NORMALE,
                "Bon voyage !",
                "Votre embarquement pour " + r.getTrajet().getLieuDepart() + " → " + r.getTrajet().getLieuArrivee()
                        + " est confirmé. Bonne route avec YOBALEMAsn.",
                "/reservations");
    }

    // ------------------------------------------------------------------ Trajets

    /** Les passagers (demandes en attente comprises) sont prévenus de tout changement d'horaire, de lieu ou de prix. */
    @TransactionalEventListener(phase = TransactionPhase.BEFORE_COMMIT)
    public void surModification(TrajetModifie e) {
        Trajet t = trajets.findById(e.idTrajet()).orElse(null);
        if (t == null) return;
        for (Reservation r : reservations.findByTrajetIdAndStatutIn(t.getId(), ACTIVES)) {
            notifications.notifier(r.getPassager(), TypeNotification.TRAJET_MODIFIE, Priorite.IMPORTANTE,
                    "Trajet modifié",
                    "Le conducteur a modifié " + trajet(t) + (vide(e.changements()) ? "." : " (" + e.changements() + ").")
                            + " Vérifiez que cela vous convient toujours.",
                    lienTrajet(t));
        }
    }

    // ------------------------------------------------------------------ Avis

    @TransactionalEventListener(phase = TransactionPhase.BEFORE_COMMIT)
    public void surAvis(AvisPublie e) {
        Evaluation a = em.find(Evaluation.class, e.idEvaluation());
        if (a == null) return;
        String auteur = a.getEvaluateur().getPrenom() + (a.parConducteur() ? ", votre conducteur," : ", votre passager,");
        String commentaire = vide(a.getCommentaire()) ? "" : " : « " + a.getCommentaire() + " »";
        notifications.notifier(a.getEvalue(), TypeNotification.AVIS_RECU, Priorite.NORMALE,
                "Nouvel avis : " + e.note() + "/5",
                auteur + " vous a donné " + e.note() + "/5 pour " + trajet(a.getTrajet()) + commentaire,
                "/profil");
    }

    // ------------------------------------------------------------------ Messagerie

    /** Un seul rappel par conversation tant que le destinataire ne l'a pas lu : pas une notification par message. */
    @TransactionalEventListener(phase = TransactionPhase.BEFORE_COMMIT)
    public void surMessage(MessageEnvoye e) {
        Message m = em.find(Message.class, e.idMessage());
        if (m == null) return;
        Utilisateur destinataire = m.getConversation().interlocuteurDe(m.getExpediteur().getId());
        String lien = "/messages/" + m.getConversation().getId();
        if (notifications.nonLueEnAttente(destinataire.getId(), TypeNotification.MESSAGE_RECU, lien)) return;
        String contenu = m.getContenu().length() > 140 ? m.getContenu().substring(0, 137) + "..." : m.getContenu();
        notifications.notifier(destinataire, TypeNotification.MESSAGE_RECU, Priorite.NORMALE,
                "Nouveau message de " + m.getExpediteur().getPrenom(),
                "À propos du " + trajet(m.getConversation().getTrajet()).substring(3) + " : « " + contenu + " »", lien);
    }

    // ------------------------------------------------------------------ Textes

    private Reservation reservation(Long id) {
        return reservations.findById(id).orElseThrow(() -> new IllegalStateException("Réservation " + id + " introuvable"));
    }

    static String trajet(Trajet t) {
        return "le trajet " + t.getLieuDepart() + " → " + t.getLieuArrivee() + " du " + date(t.getDateHeureDepart());
    }

    static String date(LocalDateTime d) {
        return d.format(DATE);
    }

    static String lienTrajet(Trajet t) {
        return "/trajets/" + t.getId();
    }

    private static String places(Integer n) {
        return n + (n != null && n > 1 ? " places" : " place");
    }

    private static boolean vide(String s) {
        return s == null || s.isBlank();
    }
}
