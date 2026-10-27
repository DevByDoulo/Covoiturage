package sn.isep.Convoiturage.admin;

import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.web.bind.annotation.*;
import sn.isep.Convoiturage.admin.AdminDtos.*;
import sn.isep.Convoiturage.common.SecurityUtils;
import sn.isep.Convoiturage.utilisateur.StatutCompte;
import sn.isep.Convoiturage.vehicule.TypeDocument;
import sn.isep.Convoiturage.vehicule.VehiculeDtos.DocumentDto;

/** Back-office (module 07). Le rôle ADMIN est exigé par SecurityConfig pour /api/admin/**. */
@RestController
@RequestMapping("/api/admin")
@RequiredArgsConstructor
public class AdminController {

    private final AdminService admin;

    @GetMapping("/statistiques")
    public StatistiquesDto statistiques() {
        return admin.statistiques();
    }

    // ---- Utilisateurs

    @GetMapping("/utilisateurs")
    public Page<UtilisateurLigneDto> utilisateurs(@RequestParam(required = false) String recherche,
                                                  @RequestParam(required = false) StatutCompte statut,
                                                  @RequestParam(defaultValue = "0") int page,
                                                  @RequestParam(defaultValue = "20") int taille) {
        return admin.utilisateurs(recherche, statut, page, taille);
    }

    @GetMapping("/utilisateurs/{id}")
    public FicheUtilisateurDto fiche(@PathVariable Long id) {
        return admin.fiche(id);
    }

    @PostMapping("/utilisateurs/{id}/bloquer")
    public FicheUtilisateurDto bloquer(@PathVariable Long id, @Valid @RequestBody MotifRequete req) {
        return admin.bloquer(SecurityUtils.utilisateurCourantId(), id, req.motif());
    }

    @PostMapping("/utilisateurs/{id}/bannir")
    public FicheUtilisateurDto bannir(@PathVariable Long id, @Valid @RequestBody MotifRequete req) {
        return admin.bannir(SecurityUtils.utilisateurCourantId(), id, req.motif());
    }

    @PostMapping("/utilisateurs/{id}/reactiver")
    public FicheUtilisateurDto reactiver(@PathVariable Long id) {
        return admin.reactiver(SecurityUtils.utilisateurCourantId(), id);
    }

    // ---- File de validation des documents

    /** Documents en attente ; tri par date de soumission (plus anciens d'abord par défaut). */
    @GetMapping("/documents")
    public Page<DocumentAValiderDto> fileDeValidation(@RequestParam(required = false) TypeDocument type,
                                                      @RequestParam(required = false) String recherche,
                                                      @RequestParam(defaultValue = "true") boolean plusAnciensDabord,
                                                      @RequestParam(defaultValue = "0") int page,
                                                      @RequestParam(defaultValue = "20") int taille) {
        return admin.fileDeValidation(type, recherche, plusAnciensDabord, page, taille);
    }

    @PostMapping("/documents/{id}/valider")
    public DocumentDto valider(@PathVariable Long id) {
        return admin.validerDocument(SecurityUtils.utilisateurCourantId(), id);
    }

    @PostMapping("/documents/{id}/refuser")
    public DocumentDto refuser(@PathVariable Long id, @Valid @RequestBody MotifRequete req) {
        return admin.refuserDocument(SecurityUtils.utilisateurCourantId(), id, req.motif());
    }
}
