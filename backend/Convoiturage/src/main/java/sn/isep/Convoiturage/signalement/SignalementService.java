package sn.isep.Convoiturage.signalement;

import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Sort;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import sn.isep.Convoiturage.admin.AdminService;
import sn.isep.Convoiturage.admin.TypeActionAdmin;
import sn.isep.Convoiturage.common.ApiException;
import sn.isep.Convoiturage.notification.NotificationService;
import sn.isep.Convoiturage.notification.Priorite;
import sn.isep.Convoiturage.notification.TypeNotification;
import sn.isep.Convoiturage.reservation.ReservationRepository;
import sn.isep.Convoiturage.signalement.SignalementDtos.*;
import sn.isep.Convoiturage.trajet.TrajetRepository;
import sn.isep.Convoiturage.utilisateur.Role;
import sn.isep.Convoiturage.utilisateur.Utilisateur;
import sn.isep.Convoiturage.utilisateur.UtilisateurRepository;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;

/**
 * Signalements (module 10) : un utilisateur signale une personne avec qui il a partagé un trajet ; un administrateur
 * le traite (classement sans suite, avertissement, blocage ou bannissement). Les sanctions réutilisent
 * {@link AdminService}, qui les inscrit dans l'historique du compte et prévient la personne sanctionnée.
 */
@Service
@RequiredArgsConstructor
public class SignalementService {

    static final int MAX_PAR_JOUR = 5;

    private final SignalementRepository signalements;
    private final UtilisateurRepository utilisateurs;
    private final TrajetRepository trajets;
    private final ReservationRepository reservations;
    private final AdminService admin;
    private final NotificationService notifications;

    // ------------------------------------------------------------------ Côté utilisateur

    @Transactional
    public SignalementDto signaler(Long signaleurId, SignalementRequete req) {
        if (signaleurId.equals(req.idUtilisateur())) throw ApiException.badRequest("Vous ne pouvez pas vous signaler vous-même");
        Utilisateur signale = utilisateurs.findById(req.idUtilisateur())
                .orElseThrow(() -> ApiException.notFound("Utilisateur introuvable"));
        if (signale.getRole() == Role.ADMIN) throw ApiException.forbidden("Ce compte ne peut pas être signalé");

        String description = req.description() == null ? "" : req.description().trim();
        if (req.motif() == MotifSignalement.AUTRE && description.isEmpty()) {
            throw ApiException.badRequest("Décrivez la situation").surChamp("description");
        }
        if (!reservations.ontPartageUnTrajet(signaleurId, signale.getId(), req.idTrajet())) {
            throw ApiException.forbidden("Vous ne pouvez signaler que les personnes avec qui vous avez partagé un trajet");
        }
        if (signalements.existsBySignaleurIdAndSignaleIdAndStatutIn(signaleurId, signale.getId(),
                List.of(StatutSignalement.EN_ATTENTE, StatutSignalement.EN_COURS))) {
            throw ApiException.conflict("Vous avez déjà un signalement en cours de traitement pour cette personne");
        }
        if (signalements.countBySignaleurIdAndDateSignalementGreaterThanEqual(signaleurId, LocalDate.now().atStartOfDay())
                >= MAX_PAR_JOUR) {
            throw ApiException.tooManyRequests("Vous avez atteint la limite de " + MAX_PAR_JOUR + " signalements par jour");
        }

        Signalement s = new Signalement();
        s.setSignaleur(utilisateurs.getReferenceById(signaleurId));
        s.setSignale(signale);
        s.setTrajet(req.idTrajet() == null ? null : trajets.getReferenceById(req.idTrajet()));
        s.setMotif(req.motif());
        s.setDescription(description.isEmpty() ? null : description);
        signalements.save(s);
        return SignalementDto.de(s);
    }

    @Transactional(readOnly = true)
    public List<SignalementDto> mesSignalements(Long signaleurId) {
        return signalements.findBySignaleurIdOrderByDateSignalementDesc(signaleurId).stream().map(SignalementDto::de).toList();
    }

    // ------------------------------------------------------------------ Modération

    @Transactional(readOnly = true)
    public Page<SignalementAdminDto> liste(StatutSignalement statut, Long idSignale, boolean plusAnciensDabord,
                                           int page, int taille) {
        Sort tri = Sort.by(plusAnciensDabord ? Sort.Direction.ASC : Sort.Direction.DESC, "dateSignalement");
        return signalements.rechercher(statut, idSignale, PageRequest.of(page, Math.min(taille, 100), tri))
                .map(this::vue);
    }

    @Transactional(readOnly = true)
    public SignalementAdminDto detail(Long id) {
        return vue(charger(id));
    }

    @Transactional
    public SignalementAdminDto decider(Long adminId, Long id, DecisionRequete req) {
        Signalement s = charger(id);
        if (!s.getStatut().estOuvert()) throw ApiException.conflict("Ce signalement a déjà été traité");
        Utilisateur signale = s.getSignale();

        if (req.decision() == Decision.PRENDRE_EN_CHARGE) {
            if (s.getStatut() != StatutSignalement.EN_ATTENTE) throw ApiException.conflict("Ce signalement est déjà pris en charge");
            s.setStatut(StatutSignalement.EN_COURS);
            s.setAdmin(utilisateurs.getReferenceById(adminId));
            return vue(s);
        }

        String message = req.message() == null ? "" : req.message().trim();
        if (message.isEmpty()) throw ApiException.badRequest("Indiquez le motif de la décision").surChamp("message");

        switch (req.decision()) {
            case CLASSER_SANS_SUITE -> admin.tracerDecision(adminId, signale.getId(), TypeActionAdmin.SIGNALEMENT_CLASSE, message);
            case AVERTIR -> {
                admin.tracerDecision(adminId, signale.getId(), TypeActionAdmin.AVERTISSEMENT, message);
                notifications.notifier(signale, TypeNotification.SIGNALEMENT_TRAITE, Priorite.IMPORTANTE,
                        "Avertissement de l'équipe YOBALEMAsn",
                        "Suite à un signalement, l'équipe YOBALEMAsn vous adresse un avertissement : « " + message
                                + " ». Une récidive peut entraîner le blocage de votre compte.", null);
            }
            case BLOQUER -> admin.bloquer(adminId, signale.getId(), message);
            case BANNIR -> admin.bannir(adminId, signale.getId(), message);
            default -> throw new IllegalStateException("Décision inattendue : " + req.decision());
        }

        boolean classe = req.decision() == Decision.CLASSER_SANS_SUITE;
        s.setStatut(classe ? StatutSignalement.REJETE : StatutSignalement.TRAITE);
        s.setDecisionAdmin(message);
        s.setAdmin(utilisateurs.getReferenceById(adminId));
        s.setDateTraitement(LocalDateTime.now());

        notifications.notifier(s.getSignaleur(), TypeNotification.SIGNALEMENT_TRAITE, Priorite.NORMALE,
                "Votre signalement a été examiné",
                classe ? "Merci pour votre signalement concernant " + signale.getPrenom()
                        + ". Après examen, l'équipe n'y a pas donné suite."
                        : "Merci pour votre signalement concernant " + signale.getPrenom()
                        + ". L'équipe a pris les mesures nécessaires.", "/signalements");
        return vue(s);
    }

    // ------------------------------------------------------------------ Interne

    private Signalement charger(Long id) {
        return signalements.findDetailleById(id).orElseThrow(() -> ApiException.notFound("Signalement introuvable"));
    }

    private SignalementAdminDto vue(Signalement s) {
        return SignalementAdminDto.de(s, signalements.countBySignaleId(s.getSignale().getId()));
    }
}
