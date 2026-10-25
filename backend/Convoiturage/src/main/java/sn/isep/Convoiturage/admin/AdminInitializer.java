package sn.isep.Convoiturage.admin;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.boot.ApplicationArguments;
import org.springframework.boot.ApplicationRunner;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;
import sn.isep.Convoiturage.common.AppProperties;
import sn.isep.Convoiturage.utilisateur.Role;
import sn.isep.Convoiturage.utilisateur.StatutCompte;
import sn.isep.Convoiturage.utilisateur.Utilisateur;
import sn.isep.Convoiturage.utilisateur.UtilisateurRepository;

/** Crée le premier compte administrateur au démarrage (ADMIN_EMAIL / ADMIN_PASSWORD) s'il n'en existe aucun. */
@Slf4j
@Component
@RequiredArgsConstructor
public class AdminInitializer implements ApplicationRunner {

    private final UtilisateurRepository utilisateurs;
    private final PasswordEncoder encoder;
    private final AppProperties props;

    @Override
    @Transactional
    public void run(ApplicationArguments args) {
        AppProperties.Admin conf = props.admin();
        if (conf == null || conf.email() == null || conf.email().isBlank() || utilisateurs.existsByRole(Role.ADMIN)) return;
        if (conf.motDePasse() == null || conf.motDePasse().length() < 12) {
            log.warn("ADMIN_PASSWORD absent ou trop court (12 caractères min.) : aucun administrateur créé");
            return;
        }
        Utilisateur admin = new Utilisateur();
        admin.setPrenom("Admin");
        admin.setNom("CoVoitIA");
        admin.setEmail(conf.email().toLowerCase());
        admin.setTelephone(conf.telephone());
        admin.setTelephoneVerifie(true);
        admin.setMotDePasse(encoder.encode(conf.motDePasse()));
        admin.setRole(Role.ADMIN);
        admin.setStatut(StatutCompte.ACTIF);
        utilisateurs.save(admin);
        log.info("Compte administrateur initial créé : {}", admin.getEmail());
    }
}
