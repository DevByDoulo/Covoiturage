package sn.isep.Convoiturage.utilisateur;

import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.core.io.Resource;
import org.springframework.http.CacheControl;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;
import sn.isep.Convoiturage.common.SecurityUtils;
import sn.isep.Convoiturage.common.stockage.StockageService;
import sn.isep.Convoiturage.utilisateur.UtilisateurDtos.*;

import java.time.Duration;
import java.util.List;

@RestController
@RequestMapping("/api")
@RequiredArgsConstructor
public class ProfilController {

    private final ProfilService profils;
    private final ContactUrgenceService contactsUrgence;
    private final StockageService stockage;

    @GetMapping("/moi")
    public ProfilDto monProfil() {
        return profils.monProfil(SecurityUtils.utilisateurCourantId());
    }

    @PutMapping("/moi")
    public ProfilDto modifier(@Valid @RequestBody ModificationProfilRequete req) {
        return profils.modifier(SecurityUtils.utilisateurCourantId(), req);
    }

    @PutMapping("/moi/preferences")
    public ProfilDto modifierPreferences(@RequestBody PreferenceDto req) {
        return profils.modifierPreferences(SecurityUtils.utilisateurCourantId(), req);
    }

    @PostMapping(value = "/moi/photo", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    public ProfilDto changerPhoto(@RequestParam("fichier") MultipartFile fichier) {
        return profils.changerPhoto(SecurityUtils.utilisateurCourantId(), fichier);
    }

    /** Jeton Firebase Cloud Messaging de l'appareil, envoyé par l'application après connexion. */
    @PutMapping("/moi/fcm-token")
    public ResponseEntity<Void> enregistrerFcmToken(@Valid @RequestBody FcmTokenRequete req) {
        profils.enregistrerFcmToken(SecurityUtils.utilisateurCourantId(), req.token());
        return ResponseEntity.noContent().build();
    }

    @GetMapping("/moi/contacts-urgence")
    public List<ContactUrgenceDto> mesContactsUrgence() {
        return contactsUrgence.mesContacts(SecurityUtils.utilisateurCourantId());
    }

    @PostMapping("/moi/contacts-urgence")
    @ResponseStatus(HttpStatus.CREATED)
    public ContactUrgenceDto ajouterContactUrgence(@Valid @RequestBody ContactUrgenceRequete req) {
        return contactsUrgence.ajouter(SecurityUtils.utilisateurCourantId(), req);
    }

    @DeleteMapping("/moi/contacts-urgence/{id}")
    public ResponseEntity<Void> supprimerContactUrgence(@PathVariable Long id) {
        contactsUrgence.supprimer(SecurityUtils.utilisateurCourantId(), id);
        return ResponseEntity.noContent().build();
    }

    @GetMapping("/utilisateurs/{id}")
    public ProfilPublicDto profilPublic(@PathVariable Long id) {
        return profils.profilPublic(id);
    }

    @GetMapping("/fichiers/photos/{nom}")
    public ResponseEntity<Resource> photo(@PathVariable String nom) {
        return ResponseEntity.ok()
                .contentType(MediaType.parseMediaType(StockageService.typeMime(nom)))
                .cacheControl(CacheControl.maxAge(Duration.ofDays(7)))
                .body(stockage.charger(nom, StockageService.Dossier.PHOTOS));
    }
}
