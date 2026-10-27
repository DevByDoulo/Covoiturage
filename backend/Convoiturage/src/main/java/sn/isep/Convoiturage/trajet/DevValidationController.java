package sn.isep.Convoiturage.trajet;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.context.annotation.Profile;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RestController;
import sn.isep.Convoiturage.common.SecurityUtils;

import java.util.Map;

/**
 * PROFIL DEV UNIQUEMENT : valide d'un coup les véhicules et documents du compte connecté, pour pouvoir publier
 * un trajet pendant les essais. À retirer quand la validation par l'administrateur (module 07) existera.
 * Le bean n'existe pas hors du profil dev : l'adresse répond alors 404.
 */
@Slf4j
@Profile("dev")
@RestController
@RequiredArgsConstructor
public class DevValidationController {

    private final JdbcTemplate jdbc;

    @PostMapping("/api/dev/moi/valider-conducteur")
    @Transactional
    public Map<String, Object> validerConducteur() {
        Long id = SecurityUtils.utilisateurCourantId();
        int vehicules = jdbc.update("update vehicule set statut_validation = 'VALIDE' where id_proprietaire = ? and actif", id);
        int documents = jdbc.update("update document set statut_validation = 'VALIDE' where id_utilisateur = ?", id);
        jdbc.update("update utilisateur set conducteur_valide = true where id_utilisateur = ?", id);
        log.warn("[DEV] Conducteur {} validé sans contrôle : {} véhicule(s), {} document(s)", id, vehicules, documents);
        return Map.of("conducteurValide", true, "vehiculesValides", vehicules, "documentsValides", documents);
    }
}
