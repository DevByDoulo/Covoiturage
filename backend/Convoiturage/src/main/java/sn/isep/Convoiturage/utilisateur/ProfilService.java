package sn.isep.Convoiturage.utilisateur;

import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;
import sn.isep.Convoiturage.common.ApiException;
import sn.isep.Convoiturage.common.stockage.StockageService;
import sn.isep.Convoiturage.utilisateur.UtilisateurDtos.*;

@Service
@RequiredArgsConstructor
public class ProfilService {

    private final UtilisateurRepository utilisateurs;
    private final StockageService stockage;

    @Transactional(readOnly = true)
    public Utilisateur charger(Long id) {
        return utilisateurs.findById(id).orElseThrow(() -> ApiException.notFound("Utilisateur introuvable"));
    }

    @Transactional(readOnly = true)
    public ProfilDto monProfil(Long id) {
        return ProfilDto.de(charger(id));
    }

    @Transactional(readOnly = true)
    public ProfilPublicDto profilPublic(Long id) {
        Utilisateur u = charger(id);
        if (u.getRole() == Role.ADMIN || u.getStatut() == StatutCompte.BANNI) throw ApiException.notFound("Utilisateur introuvable");
        return ProfilPublicDto.de(u);
    }

    @Transactional
    public ProfilDto modifier(Long id, ModificationProfilRequete req) {
        Utilisateur u = charger(id);
        u.setPrenom(req.prenom().trim());
        u.setNom(req.nom().trim());
        u.setBio(req.bio());
        if (req.sexe() != null) u.setSexe(req.sexe());
        return ProfilDto.de(u);
    }

    @Transactional
    public ProfilDto modifierPreferences(Long id, PreferenceDto req) {
        Utilisateur u = charger(id);
        Preference p = u.getPreference();
        if (p == null) {
            p = new Preference();
            p.setUtilisateur(u);
            u.setPreference(p);
        }
        p.setFumeurAccepte(req.fumeurAccepte());
        p.setMusiqueAcceptee(req.musiqueAcceptee());
        p.setAnimauxAcceptes(req.animauxAcceptes());
        p.setDiscussionAcceptee(req.discussionAcceptee());
        return ProfilDto.de(u);
    }

    @Transactional
    public ProfilDto changerPhoto(Long id, MultipartFile fichier) {
        Utilisateur u = charger(id);
        u.setPhotoProfil(stockage.enregistrer(fichier, StockageService.Dossier.PHOTOS).nom());
        return ProfilDto.de(u);
    }

    @Transactional
    public void enregistrerFcmToken(Long id, String token) {
        charger(id).setFcmToken(token.isBlank() ? null : token);
    }
}
