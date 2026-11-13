package sn.isep.Convoiturage.suppression;

import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import sn.isep.Convoiturage.auth.AlertesSecurite;
import sn.isep.Convoiturage.auth.AuthService;
import sn.isep.Convoiturage.auth.TokenService;
import sn.isep.Convoiturage.common.ApiException;
import sn.isep.Convoiturage.reservation.MoyenPaiement;
import sn.isep.Convoiturage.reservation.PaiementRepository;
import sn.isep.Convoiturage.reservation.Reservation;
import sn.isep.Convoiturage.reservation.ReservationRepository;
import sn.isep.Convoiturage.reservation.ReservationService;
import sn.isep.Convoiturage.reservation.StatutPaiement;
import sn.isep.Convoiturage.reservation.StatutReservation;
import sn.isep.Convoiturage.suppression.SuppressionDtos.SuppressionReponse;
import sn.isep.Convoiturage.trajet.StatutTrajet;
import sn.isep.Convoiturage.trajet.TrajetRepository;
import sn.isep.Convoiturage.utilisateur.Role;
import sn.isep.Convoiturage.utilisateur.StatutCompte;
import sn.isep.Convoiturage.utilisateur.Utilisateur;
import sn.isep.Convoiturage.utilisateur.UtilisateurRepository;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;

/**
 * Droit à l'effacement (RGPD). La demande ouvre un délai de grâce de {@value #DELAI_GRACE_JOURS} jours pendant lequel le
 * compte est déconnecté et invisible ; se reconnecter l'annule (voir {@code AuthService}). Passé ce délai,
 * {@link AnonymisationPlanifiee} efface les données personnelles ({@link AnonymisationService}).
 */
@Service
@RequiredArgsConstructor
public class SuppressionCompteService {

    public static final int DELAI_GRACE_JOURS = 30;

    private final UtilisateurRepository utilisateurs;
    private final TrajetRepository trajets;
    private final ReservationRepository reservations;
    private final PaiementRepository paiements;
    private final ReservationService reservationService;
    private final AuthService auth;
    private final TokenService tokens;
    private final AlertesSecurite alertes;

    /**
     * Enregistre la demande après confirmation de l'identité (mot de passe, ou code pour un compte Google).
     * Refusée tant qu'un engagement est en cours : trajet à venir, réservation acceptée à venir, paiement non soldé.
     */
    @Transactional
    public SuppressionReponse demander(Long utilisateurId, String motDePasse, String code) {
        Utilisateur u = utilisateurs.findById(utilisateurId).orElseThrow(() -> ApiException.notFound("Utilisateur introuvable"));
        if (u.getRole() == Role.ADMIN) {
            throw ApiException.forbidden("Un compte administrateur ne peut pas être supprimé ici");
        }
        if (u.getStatut() != StatutCompte.ACTIF) {
            throw ApiException.conflict("Ce compte ne peut pas être supprimé dans son état actuel");
        }
        auth.confirmerIdentite(u, motDePasse, code);

        List<String> obstacles = obstacles(u.getId());
        if (!obstacles.isEmpty()) {
            throw ApiException.conflict("Suppression impossible pour le moment : " + String.join(" ", obstacles))
                    .avec("obstacles", obstacles);
        }

        // Les demandes de réservation encore sans réponse sont annulées (le passager n'attend plus de trajet).
        for (Reservation r : reservations.findByPassagerIdAndStatut(u.getId(), StatutReservation.EN_ATTENTE)) {
            try {
                reservationService.annulerParPassager(u.getId(), r.getId(), "Compte supprimé par le passager");
            } catch (ApiException e) {
                // Trajet déjà parti : la demande reste sans suite, elle ne bloque pas la suppression.
            }
        }

        LocalDateTime maintenant = LocalDateTime.now();
        u.setStatut(StatutCompte.SUPPRESSION_DEMANDEE);
        u.setDateSuppressionDemandee(maintenant);
        tokens.revoquerTous(u.getId());
        LocalDateTime dateEffective = maintenant.plusDays(DELAI_GRACE_JOURS);
        alertes.suppressionDemandee(u, dateEffective);
        return new SuppressionReponse(dateEffective);
    }

    /** Raisons (en clair, avec la marche à suivre) pour lesquelles le compte ne peut pas être supprimé maintenant. */
    List<String> obstacles(Long utilisateurId) {
        LocalDateTime maintenant = LocalDateTime.now();
        List<String> obstacles = new ArrayList<>();

        long trajetsAVenir = trajets.compterAVenir(utilisateurId, StatutTrajet.EN_COURS,
                List.of(StatutTrajet.PUBLIE, StatutTrajet.COMPLET), maintenant);
        if (trajetsAVenir > 0) {
            obstacles.add("Vous avez " + trajetsAVenir + (trajetsAVenir > 1 ? " trajets" : " trajet")
                    + " à venir ou en cours en tant que conducteur : annulez-" + (trajetsAVenir > 1 ? "les" : "le")
                    + " ou terminez-" + (trajetsAVenir > 1 ? "les" : "le") + " depuis « Mes trajets ».");
        }

        long reservationsAcceptees = reservations.compterAccepteesAVenir(utilisateurId, StatutReservation.ACCEPTEE,
                StatutTrajet.EN_COURS, maintenant);
        if (reservationsAcceptees > 0) {
            obstacles.add("Vous avez " + reservationsAcceptees + (reservationsAcceptees > 1 ? " réservations acceptées" : " réservation acceptée")
                    + " à venir : annulez-" + (reservationsAcceptees > 1 ? "les" : "la") + " depuis « Mes réservations » ou faites le trajet.");
        }

        long paiementsEnAttente = paiements.compterNonSoldes(utilisateurId,
                List.of(StatutPaiement.EN_ATTENTE, StatutPaiement.REMBOURSEMENT_DEMANDE), MoyenPaiement.ESPECES);
        if (paiementsEnAttente > 0) {
            obstacles.add("Vous avez " + paiementsEnAttente + (paiementsEnAttente > 1 ? " paiements" : " paiement")
                    + " en attente (paiement en cours ou remboursement à venir) : attendez qu'" + (paiementsEnAttente > 1 ? "ils soient" : "il soit")
                    + " confirmé" + (paiementsEnAttente > 1 ? "s" : "") + " ou remboursé" + (paiementsEnAttente > 1 ? "s" : "") + ", puis réessayez.");
        }
        return obstacles;
    }
}
