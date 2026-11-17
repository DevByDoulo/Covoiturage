package sn.isep.Convoiturage.notification;

import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import sn.isep.Convoiturage.common.ApiException;
import sn.isep.Convoiturage.utilisateur.Utilisateur;
import sn.isep.Convoiturage.utilisateur.UtilisateurRepository;

import java.time.LocalDateTime;
import java.util.List;

/** Jetons push des appareils : enregistrés à la connexion, retirés à la déconnexion ou quand FCM les rejette. */
@Service
@RequiredArgsConstructor
public class AppareilService {

    /** Au-delà, les appareils les plus anciens sont oubliés. */
    static final int MAX_APPAREILS = 10;

    private final AppareilRepository appareils;
    private final UtilisateurRepository utilisateurs;

    /**
     * Idempotent. Un jeton déjà connu pour un autre compte (téléphone partagé, changement de compte) passe à
     * l'utilisateur courant : un appareil ne reçoit que les notifications de la personne connectée.
     */
    @Transactional
    public void enregistrer(Long utilisateurId, String jeton, PlateformeAppareil plateforme) {
        Utilisateur u = utilisateurs.findById(utilisateurId).orElseThrow(() -> ApiException.notFound("Utilisateur introuvable"));
        Appareil a = appareils.findByJeton(jeton).orElseGet(Appareil::new);
        a.setUtilisateur(u);
        a.setJeton(jeton);
        a.setPlateforme(plateforme);
        a.setDerniereUtilisation(LocalDateTime.now());
        appareils.save(a);

        List<Appareil> siens = appareils.findByUtilisateurIdOrderByDerniereUtilisationDesc(utilisateurId);
        if (siens.size() > MAX_APPAREILS) appareils.deleteAll(siens.subList(MAX_APPAREILS, siens.size()));
    }

    @Transactional
    public void supprimer(Long utilisateurId, String jeton) {
        appareils.supprimerDeLUtilisateur(jeton, utilisateurId);
    }

    @Transactional(readOnly = true)
    public List<Appareil> appareilsDe(Long utilisateurId) {
        return appareils.findByUtilisateurIdOrderByDerniereUtilisationDesc(utilisateurId);
    }

    public void supprimerJetonInvalide(String jeton) {
        appareils.supprimerJeton(jeton);
    }
}
