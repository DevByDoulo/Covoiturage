package sn.isep.Convoiturage.admin;

import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import sn.isep.Convoiturage.auth.TokenService;
import sn.isep.Convoiturage.common.ApiException;
import sn.isep.Convoiturage.notification.NotificationService;
import sn.isep.Convoiturage.notification.TypeNotification;
import sn.isep.Convoiturage.reservation.ReservationDtos.StatistiquesReservations;
import sn.isep.Convoiturage.reservation.ReservationService;
import sn.isep.Convoiturage.trajet.StatutTrajet;
import sn.isep.Convoiturage.trajet.TrajetRepository;
import sn.isep.Convoiturage.utilisateur.Role;
import sn.isep.Convoiturage.utilisateur.StatutCompte;
import sn.isep.Convoiturage.utilisateur.Utilisateur;
import sn.isep.Convoiturage.utilisateur.UtilisateurDtos.ProfilDto;
import sn.isep.Convoiturage.utilisateur.UtilisateurRepository;
import sn.isep.Convoiturage.vehicule.DocumentRepository;
import sn.isep.Convoiturage.vehicule.StatutValidation;

import java.util.Map;

@Service
@RequiredArgsConstructor
public class AdminService {

    private final UtilisateurRepository utilisateurs;
    private final DocumentRepository documents;
    private final TrajetRepository trajets;
    private final ReservationService reservations;
    private final TokenService tokens;
    private final NotificationService notifications;

    public record StatistiquesDto(long utilisateursInscrits, long utilisateursActifs, long conducteursValides,
                                  long documentsEnAttente, long trajetsPublies, long trajetsComplets,
                                  long trajetsTermines, long trajetsAnnules, StatistiquesReservations reservations) {}

    @Transactional(readOnly = true)
    public StatistiquesDto statistiques() {
        return new StatistiquesDto(
                utilisateurs.count(),
                utilisateurs.countByStatut(StatutCompte.ACTIF),
                utilisateurs.countByConducteurValideTrue(),
                documents.countByStatutValidation(StatutValidation.EN_ATTENTE),
                trajets.countByStatut(StatutTrajet.PUBLIE),
                trajets.countByStatut(StatutTrajet.COMPLET),
                trajets.countByStatut(StatutTrajet.TERMINE),
                trajets.countByStatut(StatutTrajet.ANNULE),
                reservations.statistiques());
    }

    @Transactional(readOnly = true)
    public Page<ProfilDto> utilisateurs(String recherche, StatutCompte statut, int page, int taille) {
        String motif = recherche == null || recherche.isBlank() ? null : "%" + recherche.trim().toLowerCase() + "%";
        return utilisateurs.rechercher(motif, statut, PageRequest.of(page, Math.min(taille, 100))).map(ProfilDto::de);
    }

    @Transactional(readOnly = true)
    public ProfilDto utilisateur(Long id) {
        return ProfilDto.de(charger(id));
    }

    /** Bloquer (temporaire), bannir (définitif) ou réactiver un compte. Les sessions en cours sont révoquées. */
    @Transactional
    public ProfilDto changerStatut(Long adminId, Long utilisateurId, StatutCompte nouveau, String motif) {
        if (adminId.equals(utilisateurId)) throw ApiException.badRequest("Vous ne pouvez pas modifier votre propre compte");
        Utilisateur u = charger(utilisateurId);
        if (u.getRole() == Role.ADMIN) throw ApiException.forbidden("Le statut d'un administrateur ne peut pas être modifié ici");
        if (nouveau == StatutCompte.ACTIF && !u.estVerifie()) {
            throw ApiException.conflict("Ce compte n'a encore vérifié ni son email ni son numéro de téléphone");
        }
        u.setStatut(nouveau);
        if (nouveau != StatutCompte.ACTIF) {
            tokens.revoquerTous(u.getId());
            notifications.notifier(u, TypeNotification.COMPTE_SUSPENDU,
                    nouveau == StatutCompte.BANNI ? "Compte banni" : "Compte bloqué",
                    "Votre compte a été " + (nouveau == StatutCompte.BANNI ? "banni" : "bloqué")
                            + (motif == null || motif.isBlank() ? "." : " : " + motif), Map.of());
        }
        return ProfilDto.de(u);
    }

    private Utilisateur charger(Long id) {
        return utilisateurs.findById(id).orElseThrow(() -> ApiException.notFound("Utilisateur introuvable"));
    }
}
