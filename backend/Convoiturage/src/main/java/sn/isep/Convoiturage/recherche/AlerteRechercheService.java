package sn.isep.Convoiturage.recherche;

import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.PlatformTransactionManager;
import org.springframework.transaction.TransactionDefinition;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.transaction.event.TransactionalEventListener;
import org.springframework.transaction.support.TransactionTemplate;
import sn.isep.Convoiturage.common.ApiException;
import sn.isep.Convoiturage.notification.NotificationService;
import sn.isep.Convoiturage.notification.TypeNotification;
import sn.isep.Convoiturage.recherche.AlerteDtos.AlerteDto;
import sn.isep.Convoiturage.recherche.AlerteDtos.CreationAlerteRequete;
import sn.isep.Convoiturage.trajet.Trajet;
import sn.isep.Convoiturage.trajet.TrajetEvenements.TrajetPublie;
import sn.isep.Convoiturage.trajet.TrajetRepository;
import sn.isep.Convoiturage.utilisateur.Utilisateur;
import sn.isep.Convoiturage.utilisateur.UtilisateurRepository;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.format.DateTimeFormatter;
import java.util.List;
import java.util.Map;

/** F5 — Alertes de recherche : création par le passager, déclenchement à la publication d'un trajet. */
@Slf4j
@Service
public class AlerteRechercheService {

    static final int ALERTES_MAX = 10;
    private static final DateTimeFormatter FORMAT = DateTimeFormatter.ofPattern("dd/MM 'à' HH'h'mm");

    private final AlerteRechercheRepository alertes;
    private final UtilisateurRepository utilisateurs;
    private final TrajetRepository trajets;
    private final NotificationService notifications;
    private final TransactionTemplate nouvelleTransaction;

    public AlerteRechercheService(AlerteRechercheRepository alertes, UtilisateurRepository utilisateurs,
                                  TrajetRepository trajets, NotificationService notifications,
                                  PlatformTransactionManager transactions) {
        this.alertes = alertes;
        this.utilisateurs = utilisateurs;
        this.trajets = trajets;
        this.notifications = notifications;
        this.nouvelleTransaction = new TransactionTemplate(transactions);
        this.nouvelleTransaction.setPropagationBehavior(TransactionDefinition.PROPAGATION_REQUIRES_NEW);
    }

    @Transactional
    public AlerteDto creer(Long utilisateurId, CreationAlerteRequete req) {
        if (alertes.countByUtilisateurIdAndActifTrueAndDateDepartGreaterThanEqual(utilisateurId, LocalDate.now()) >= ALERTES_MAX) {
            throw ApiException.conflict("Vous avez déjà " + ALERTES_MAX + " alertes actives : supprimez-en une pour en créer une nouvelle");
        }
        Utilisateur u = utilisateurs.findById(utilisateurId).orElseThrow(() -> ApiException.notFound("Utilisateur introuvable"));
        AlerteRecherche a = new AlerteRecherche();
        a.setUtilisateur(u);
        a.setVilleDepart(req.depart().lieu().trim());
        a.setLatitudeDepart(req.depart().latitude());
        a.setLongitudeDepart(req.depart().longitude());
        a.setVilleArrivee(req.arrivee().lieu().trim());
        a.setLatitudeArrivee(req.arrivee().latitude());
        a.setLongitudeArrivee(req.arrivee().longitude());
        a.setDateDepart(req.date());
        if (req.rayonKm() != null) a.setRayonKm(req.rayonKm());
        a.setPrixMax(req.prixMax());
        return AlerteDto.de(alertes.save(a));
    }

    @Transactional(readOnly = true)
    public List<AlerteDto> mesAlertes(Long utilisateurId) {
        return alertes.findByUtilisateurIdAndActifTrueAndDateDepartGreaterThanEqualOrderByDateDepartAsc(utilisateurId, LocalDate.now())
                .stream().map(AlerteDto::de).toList();
    }

    @Transactional
    public void supprimer(Long utilisateurId, Long alerteId) {
        alertes.findByIdAndUtilisateurId(alerteId, utilisateurId)
                .orElseThrow(() -> ApiException.notFound("Alerte introuvable"))
                .setActif(false);
    }

    /**
     * Après la publication d'un trajet, une fois sa transaction validée : prévient chaque passager dont
     * l'alerte correspond. Le traitement a sa propre transaction et ses erreurs sont seulement
     * journalisées, pour qu'un problème ici ne fasse jamais échouer la publication.
     */
    @TransactionalEventListener
    public void surTrajetPublie(TrajetPublie evenement) {
        try {
            nouvelleTransaction.executeWithoutResult(statut -> notifierAlertes(evenement.idTrajet()));
        } catch (RuntimeException e) {
            log.warn("Alertes de recherche non traitées pour le trajet {} : {}", evenement.idTrajet(), e.getMessage());
        }
    }

    private void notifierAlertes(Long idTrajet) {
        Trajet t = trajets.findById(idTrajet).orElse(null);
        if (t == null) return;
        List<AlerteRecherche> concernees = alertes.correspondantAuTrajet(t.getId());
        BigDecimal prix = t.getTarification().getPrixFinal();
        for (AlerteRecherche a : concernees) {
            notifications.notifier(a.getUtilisateur(), TypeNotification.ALERTE_TRAJET, "Un trajet correspond à votre recherche",
                    t.getLieuDepart() + " → " + t.getLieuArrivee() + " le " + FORMAT.format(t.getDateHeureDepart())
                            + " : " + prix.toBigInteger() + " FCFA par place. Réservez vite !",
                    Map.of("idTrajet", t.getId().toString(), "idAlerte", a.getId().toString()));
        }
        if (!concernees.isEmpty()) log.debug("Trajet {} : {} alerte(s) de recherche déclenchée(s)", t.getId(), concernees.size());
    }
}
