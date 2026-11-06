package sn.isep.Convoiturage.suivi;

import lombok.RequiredArgsConstructor;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.transaction.event.TransactionPhase;
import org.springframework.transaction.event.TransactionalEventListener;
import sn.isep.Convoiturage.common.ApiException;
import sn.isep.Convoiturage.notification.NotificationService;
import sn.isep.Convoiturage.notification.Priorite;
import sn.isep.Convoiturage.notification.TypeNotification;
import sn.isep.Convoiturage.reservation.Reservation;
import sn.isep.Convoiturage.reservation.ReservationRepository;
import sn.isep.Convoiturage.reservation.StatutReservation;
import sn.isep.Convoiturage.suivi.SuiviDtos.PositionDto;
import sn.isep.Convoiturage.suivi.SuiviDtos.PositionRequete;
import sn.isep.Convoiturage.trajet.StatutTrajet;
import sn.isep.Convoiturage.trajet.Trajet;
import sn.isep.Convoiturage.trajet.TrajetEvenements.TrajetAnnule;
import sn.isep.Convoiturage.trajet.TrajetEvenements.TrajetTermine;
import sn.isep.Convoiturage.trajet.TrajetRepository;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

/**
 * 08 — Suivi du conducteur en temps réel. Le conducteur partage sa position à partir d'une heure avant le départ et
 * jusqu'à la fin du trajet ; seuls ses passagers acceptés la voient. On ne garde que la dernière position, effacée
 * quand le partage s'arrête, quand le trajet se termine ou est annulé, et au plus tard 30 minutes après le dernier envoi.
 */
@Service
@RequiredArgsConstructor
public class SuiviService {

    /** Partage possible à partir de ce délai avant le départ (le conducteur se rend au point de départ). */
    static final long PARTAGE_AVANT_DEPART_MIN = 60;
    /** Au-delà, la position n'est plus montrée (téléphone éteint, partage interrompu sans l'arrêter). */
    static final long POSITION_PERIMEE_MIN = 30;

    private final PositionConducteurRepository positions;
    private final TrajetRepository trajets;
    private final ReservationRepository reservations;
    private final NotificationService notifications;

    @Transactional
    public PositionDto partager(Long conducteurId, Long trajetId, PositionRequete req) {
        Trajet t = trajet(trajetId);
        if (!t.getConducteur().getId().equals(conducteurId)) throw ApiException.forbidden("Ce trajet ne vous appartient pas");
        LocalDateTime maintenant = LocalDateTime.now();
        boolean ouvert = t.getStatut() == StatutTrajet.EN_COURS
                || ((t.getStatut() == StatutTrajet.PUBLIE || t.getStatut() == StatutTrajet.COMPLET)
                    && !maintenant.isBefore(t.getDateHeureDepart().minusMinutes(PARTAGE_AVANT_DEPART_MIN)));
        if (!ouvert) {
            throw ApiException.conflict("Le partage de position est possible à partir d'une heure avant le départ, "
                    + "jusqu'à la fin du trajet");
        }

        Optional<PositionConducteur> existante = positions.findById(trajetId);
        PositionConducteur p = existante.orElseGet(() -> new PositionConducteur(trajetId));
        if (existante.isEmpty()) {
            p.setDateDebut(maintenant);
            prevenirPassagers(t);
        }
        p.setLatitude(req.latitude());
        p.setLongitude(req.longitude());
        p.setPrecisionM(req.precisionM());
        p.setCap(req.cap());
        p.setVitesse(req.vitesse());
        p.setDateMaj(maintenant);
        positions.save(p);
        return PositionDto.de(p, maintenant);
    }

    /** Dernière position du conducteur, pour lui-même ou un passager accepté ; vide si rien de récent. */
    @Transactional(readOnly = true)
    public Optional<PositionDto> consulter(Long utilisateurId, Long trajetId) {
        Trajet t = trajet(trajetId);
        boolean conducteur = t.getConducteur().getId().equals(utilisateurId);
        boolean passager = reservations.existsByTrajetIdAndPassagerIdAndStatutIn(trajetId, utilisateurId,
                List.of(StatutReservation.ACCEPTEE));
        if (!conducteur && !passager) {
            throw ApiException.forbidden("Seuls les passagers acceptés de ce trajet peuvent suivre le conducteur");
        }
        LocalDateTime maintenant = LocalDateTime.now();
        return positions.findById(trajetId)
                .filter(p -> p.getDateMaj().isAfter(maintenant.minusMinutes(POSITION_PERIMEE_MIN)))
                .map(p -> PositionDto.de(p, maintenant));
    }

    @Transactional
    public void arreter(Long conducteurId, Long trajetId) {
        Trajet t = trajet(trajetId);
        if (!t.getConducteur().getId().equals(conducteurId)) throw ApiException.forbidden("Ce trajet ne vous appartient pas");
        positions.deleteById(trajetId);
    }

    @TransactionalEventListener(phase = TransactionPhase.BEFORE_COMMIT)
    public void surFin(TrajetTermine e) {
        positions.deleteById(e.idTrajet());
    }

    @TransactionalEventListener(phase = TransactionPhase.BEFORE_COMMIT)
    public void surAnnulation(TrajetAnnule e) {
        positions.deleteById(e.idTrajet());
    }

    /** Positions abandonnées (partage interrompu sans être arrêté). */
    @Scheduled(fixedDelay = 10 * 60_000L, initialDelay = 60_000L)
    @Transactional
    public void purger() {
        positions.supprimerAnciennes(LocalDateTime.now().minusMinutes(POSITION_PERIMEE_MIN));
    }

    /** Premier envoi : les passagers acceptés sont prévenus qu'ils peuvent suivre le conducteur. */
    private void prevenirPassagers(Trajet t) {
        String prenom = t.getConducteur().getPrenom();
        for (Reservation r : reservations.findByTrajetIdAndStatutIn(t.getId(), List.of(StatutReservation.ACCEPTEE))) {
            notifications.notifier(r.getPassager(), TypeNotification.POSITION_PARTAGEE, Priorite.NORMALE,
                    prenom + " est en route",
                    prenom + " partage sa position pour le trajet " + t.getLieuDepart() + " → " + t.getLieuArrivee()
                            + ". Suivez son arrivée au point de prise en charge.",
                    "/trajets/" + t.getId() + "/suivi");
        }
    }

    private Trajet trajet(Long id) {
        return trajets.findById(id).orElseThrow(() -> ApiException.notFound("Trajet introuvable"));
    }
}
