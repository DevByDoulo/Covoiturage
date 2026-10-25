package sn.isep.Convoiturage.admin;

import jakarta.validation.Valid;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.web.bind.annotation.*;
import sn.isep.Convoiturage.common.SecurityUtils;
import sn.isep.Convoiturage.tarification.ParametresTarification;
import sn.isep.Convoiturage.tarification.ParametresTarification.ParametreDto;
import sn.isep.Convoiturage.utilisateur.StatutCompte;
import sn.isep.Convoiturage.utilisateur.UtilisateurDtos.ProfilDto;
import sn.isep.Convoiturage.utilisateur.UtilisateurRepository;
import sn.isep.Convoiturage.vehicule.DocumentService;
import sn.isep.Convoiturage.vehicule.StatutValidation;
import sn.isep.Convoiturage.vehicule.VehiculeDtos.DocumentAValiderDto;
import sn.isep.Convoiturage.vehicule.VehiculeDtos.DocumentDto;
import sn.isep.Convoiturage.vehicule.VehiculeDtos.RefusRequete;

import java.math.BigDecimal;
import java.util.List;

/** Back-office (rôle ADMIN exigé par SecurityConfig pour /api/admin/**). */
@RestController
@RequestMapping("/api/admin")
@RequiredArgsConstructor
public class AdminController {

    private final AdminService admin;
    private final DocumentService documents;
    private final ParametresTarification parametres;
    private final UtilisateurRepository utilisateurs;

    public record MotifRequete(@Size(max = 500) String motif) {}

    public record ValeurRequete(@NotNull BigDecimal valeur) {}

    @GetMapping("/statistiques")
    public AdminService.StatistiquesDto statistiques() {
        return admin.statistiques();
    }

    // ---- File de validation des documents

    @GetMapping("/documents")
    public Page<DocumentAValiderDto> fileDeValidation(@RequestParam(defaultValue = "EN_ATTENTE") StatutValidation statut,
                                                      @RequestParam(defaultValue = "0") int page,
                                                      @RequestParam(defaultValue = "20") int taille) {
        return documents.fileDeValidation(statut, page, taille);
    }

    @PostMapping("/documents/{id}/valider")
    public DocumentDto valider(@PathVariable Long id) {
        return documents.valider(id, SecurityUtils.utilisateurCourantId());
    }

    @PostMapping("/documents/{id}/refuser")
    public DocumentDto refuser(@PathVariable Long id, @Valid @RequestBody RefusRequete req) {
        return documents.refuser(id, SecurityUtils.utilisateurCourantId(), req.commentaire());
    }

    // ---- Comptes

    @GetMapping("/utilisateurs")
    public Page<ProfilDto> utilisateurs(@RequestParam(required = false) String recherche,
                                        @RequestParam(required = false) StatutCompte statut,
                                        @RequestParam(defaultValue = "0") int page,
                                        @RequestParam(defaultValue = "20") int taille) {
        return admin.utilisateurs(recherche, statut, page, taille);
    }

    @GetMapping("/utilisateurs/{id}")
    public ProfilDto utilisateur(@PathVariable Long id) {
        return admin.utilisateur(id);
    }

    @PostMapping("/utilisateurs/{id}/bloquer")
    public ProfilDto bloquer(@PathVariable Long id, @Valid @RequestBody(required = false) MotifRequete req) {
        return admin.changerStatut(SecurityUtils.utilisateurCourantId(), id, StatutCompte.BLOQUE, req == null ? null : req.motif());
    }

    @PostMapping("/utilisateurs/{id}/bannir")
    public ProfilDto bannir(@PathVariable Long id, @Valid @RequestBody(required = false) MotifRequete req) {
        return admin.changerStatut(SecurityUtils.utilisateurCourantId(), id, StatutCompte.BANNI, req == null ? null : req.motif());
    }

    @PostMapping("/utilisateurs/{id}/reactiver")
    public ProfilDto reactiver(@PathVariable Long id) {
        return admin.changerStatut(SecurityUtils.utilisateurCourantId(), id, StatutCompte.ACTIF, null);
    }

    // ---- Coefficients du moteur de prix

    @GetMapping("/parametres-tarification")
    public List<ParametreDto> parametres() {
        return parametres.lister();
    }

    @PutMapping("/parametres-tarification/{cle}")
    public ParametreDto modifierParametre(@PathVariable String cle, @Valid @RequestBody ValeurRequete req) {
        return parametres.modifier(cle, req.valeur(), utilisateurs.getReferenceById(SecurityUtils.utilisateurCourantId()));
    }
}
