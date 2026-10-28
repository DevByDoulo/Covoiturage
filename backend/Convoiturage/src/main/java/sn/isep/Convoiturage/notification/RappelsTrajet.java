package sn.isep.Convoiturage.notification;

import jakarta.persistence.EntityManager;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;
import sn.isep.Convoiturage.reservation.Reservation;
import sn.isep.Convoiturage.reservation.ReservationRepository;
import sn.isep.Convoiturage.reservation.StatutReservation;
import sn.isep.Convoiturage.trajet.StatutTrajet;
import sn.isep.Convoiturage.trajet.Trajet;
import sn.isep.Convoiturage.utilisateur.Utilisateur;

import java.time.Duration;
import java.time.LocalDateTime;
import java.util.List;

/**
 * Rappel envoyé une heure avant le départ au conducteur et à ses passagers confirmés. Vérifié toutes les 5 minutes ;
 * un rappel déjà envoyé (même trajet, même personne) ne l'est pas une seconde fois.
 */
@Slf4j
@Component
@RequiredArgsConstructor
public class RappelsTrajet {

    static final Duration AVANCE = Duration.ofHours(1);

    private final EntityManager em;
    private final ReservationRepository reservations;
    private final NotificationService notifications;

    @Scheduled(fixedDelayString = "PT5M", initialDelayString = "PT1M")
    @Transactional
    public void envoyer() {
        envoyer(LocalDateTime.now());
    }

    /** Trajets qui partent dans l'heure (et pas encore partis). Séparé pour les tests. */
    @Transactional
    public int envoyer(LocalDateTime maintenant) {
        List<Trajet> prochains = em.createQuery("""
                        select t from Trajet t
                        where t.statut in :statuts and t.dateHeureDepart > :maintenant and t.dateHeureDepart <= :limite
                        """, Trajet.class)
                .setParameter("statuts", List.of(StatutTrajet.PUBLIE, StatutTrajet.COMPLET))
                .setParameter("maintenant", maintenant)
                .setParameter("limite", maintenant.plus(AVANCE))
                .getResultList();
        int envoyes = 0;
        for (Trajet t : prochains) {
            String lien = NotificationsActivite.lienTrajet(t);
            String quand = "à " + t.getDateHeureDepart().toLocalTime().toString().replace(':', 'h');
            List<Reservation> passagers = reservations.findByTrajetIdAndStatutIn(t.getId(), List.of(StatutReservation.ACCEPTEE));
            if (!passagers.isEmpty()) {
                envoyes += rappeler(t.getConducteur(), lien, "Départ dans moins d'une heure",
                        "Vous partez " + quand + " de " + t.getLieuDepart() + " vers " + t.getLieuArrivee() + " avec "
                                + passagers.size() + " passager" + (passagers.size() > 1 ? "s" : "")
                                + ". Pensez à scanner leur code d'embarquement.");
            }
            for (Reservation r : passagers) {
                envoyes += rappeler(r.getPassager(), lien, "Votre trajet part bientôt",
                        "Départ " + quand + " de " + t.getLieuDepart() + " vers " + t.getLieuArrivee()
                                + ". Préparez votre code d'embarquement (dans « Réservations »).");
            }
        }
        if (envoyes > 0) log.info("{} rappel(s) de départ envoyé(s)", envoyes);
        return envoyes;
    }

    private int rappeler(Utilisateur u, String lien, String titre, String contenu) {
        if (notifications.dejaEnvoyee(u.getId(), TypeNotification.RAPPEL_TRAJET, lien)) return 0;
        notifications.notifier(u, TypeNotification.RAPPEL_TRAJET, Priorite.NORMALE, titre, contenu, lien);
        return 1;
    }
}
