package sn.isep.Convoiturage.suppression;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;
import sn.isep.Convoiturage.utilisateur.UtilisateurRepository;

import java.time.LocalDateTime;

/** Tous les jours à 3 h (Dakar) : anonymise les comptes dont la demande de suppression date de plus de 30 jours. */
@Slf4j
@Component
@RequiredArgsConstructor
public class AnonymisationPlanifiee {

    private final UtilisateurRepository utilisateurs;
    private final AnonymisationService anonymisation;

    @Scheduled(cron = "0 0 3 * * *", zone = "Africa/Dakar")
    public void executerChaqueNuit() {
        int n = anonymiserLesComptesEchus(LocalDateTime.now());
        if (n > 0) log.info("{} compte(s) anonymisé(s) après le délai de grâce", n);
    }

    /** Un compte par transaction : l'échec de l'un n'empêche pas les autres (il sera retenté la nuit suivante). */
    public int anonymiserLesComptesEchus(LocalDateTime maintenant) {
        int faits = 0;
        for (Long id : utilisateurs.comptesASupprimer(maintenant.minusDays(SuppressionCompteService.DELAI_GRACE_JOURS))) {
            try {
                if (anonymisation.anonymiser(id)) faits++;
            } catch (RuntimeException e) {
                log.error("Anonymisation du compte {} impossible : {}", id, e.getMessage(), e);
            }
        }
        return faits;
    }
}
