package sn.isep.Convoiturage.admin;

import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import sn.isep.Convoiturage.admin.AdminDtos.*;
import sn.isep.Convoiturage.auth.TokenService;
import sn.isep.Convoiturage.common.ApiException;
import sn.isep.Convoiturage.notification.TypeNotification;
import sn.isep.Convoiturage.utilisateur.Role;
import sn.isep.Convoiturage.utilisateur.StatutCompte;
import sn.isep.Convoiturage.utilisateur.Utilisateur;
import sn.isep.Convoiturage.utilisateur.UtilisateurRepository;
import sn.isep.Convoiturage.vehicule.*;
import sn.isep.Convoiturage.vehicule.VehiculeDtos.DocumentDto;
import sn.isep.Convoiturage.vehicule.VehiculeDtos.VehiculeDto;

import java.util.List;
import java.util.Objects;
import java.util.Set;

/**
 * Back-office (module 07) : statistiques, utilisateurs, validation manuelle des documents (RG-U12) et blocage des
 * comptes. Chaque décision est enregistrée dans le journal {@link ActionAdmin} et communiquée à l'utilisateur.
 */
@Service
@RequiredArgsConstructor
public class AdminService {

    private final UtilisateurRepository utilisateurs;
    private final VehiculeRepository vehicules;
    private final DocumentRepository documents;
    private final DocumentService documentService;
    private final ActionAdminRepository journal;
    private final TokenService tokens;
    private final AvisUtilisateurs avis;

    @Transactional(readOnly = true)
    public StatistiquesDto statistiques() {
        return new StatistiquesDto(
                utilisateurs.count() - utilisateurs.countByRole(Role.ADMIN),
                utilisateurs.countByStatut(StatutCompte.ACTIF),
                utilisateurs.countByRole(Role.CONDUCTEUR),
                utilisateurs.countByConducteurValideTrue(),
                utilisateurs.countByStatut(StatutCompte.BLOQUE) + utilisateurs.countByStatut(StatutCompte.BANNI),
                documents.countByStatutValidation(StatutValidation.EN_ATTENTE));
    }

    // ------------------------------------------------------------------ Utilisateurs

    @Transactional(readOnly = true)
    public Page<UtilisateurLigneDto> utilisateurs(String recherche, StatutCompte statut, int page, int taille) {
        String motif = recherche == null || recherche.isBlank() ? null : "%" + recherche.trim().toLowerCase() + "%";
        return utilisateurs.rechercher(motif, statut, PageRequest.of(page, Math.min(taille, 100))).map(UtilisateurLigneDto::de);
    }

    @Transactional(readOnly = true)
    public FicheUtilisateurDto fiche(Long id) {
        Utilisateur u = charger(id);
        return new FicheUtilisateurDto(UtilisateurLigneDto.de(u), u.isTelephoneVerifie(), u.isEmailVerifie(), u.getSexe(),
                u.getBio(), u.getNoteMoyenne(),
                vehicules.findByProprietaireIdAndActifTrueOrderByDateCreationDesc(id).stream().map(VehiculeDto::de).toList(),
                documents.findByUtilisateurIdOrderByDateSoumissionDesc(id).stream().map(DocumentDto::de).toList(),
                journal.findTop50ByUtilisateurIdOrderByDateDesc(id).stream().map(ActionDto::de).toList());
    }

    /** Blocage temporaire : plus de connexion possible, sessions fermées. Motif obligatoire, communiqué à l'utilisateur. */
    @Transactional
    public FicheUtilisateurDto bloquer(Long adminId, Long id, String motif) {
        Utilisateur u = chargerModifiable(adminId, id);
        if (u.getStatut() == StatutCompte.BLOQUE || u.getStatut() == StatutCompte.BANNI) {
            throw ApiException.conflict("Ce compte est déjà bloqué ou banni");
        }
        suspendre(adminId, u, StatutCompte.BLOQUE, TypeActionAdmin.COMPTE_BLOQUE, motif,
                "Votre compte a été temporairement bloqué par l'équipe YOBALEMAsn pour le motif suivant : « " + motif.trim()
                        + " ». Pour toute question, répondez à ce message.");
        return fiche(id);
    }

    /** Bannissement définitif (réversible uniquement par un administrateur). */
    @Transactional
    public FicheUtilisateurDto bannir(Long adminId, Long id, String motif) {
        Utilisateur u = chargerModifiable(adminId, id);
        if (u.getStatut() == StatutCompte.BANNI) throw ApiException.conflict("Ce compte est déjà banni");
        suspendre(adminId, u, StatutCompte.BANNI, TypeActionAdmin.COMPTE_BANNI, motif,
                "Votre compte a été banni de YOBALEMAsn pour le motif suivant : « " + motif.trim() + " ».");
        return fiche(id);
    }

    /** Lève un blocage ou un bannissement. */
    @Transactional
    public FicheUtilisateurDto reactiver(Long adminId, Long id) {
        Utilisateur u = chargerModifiable(adminId, id);
        if (u.getStatut() != StatutCompte.BLOQUE && u.getStatut() != StatutCompte.BANNI) {
            throw ApiException.conflict("Seul un compte bloqué ou banni peut être débloqué");
        }
        u.setStatut(StatutCompte.ACTIF);
        tracer(adminId, u, TypeActionAdmin.COMPTE_REACTIVE, null);
        avis.envoyer(u, TypeNotification.COMPTE_REACTIVE, "Votre compte est de nouveau actif",
                "Votre compte a été débloqué : vous pouvez de nouveau vous connecter.", "/accueil");
        return fiche(id);
    }

    // ------------------------------------------------------------------ Validation des documents (RG-U12)

    @Transactional(readOnly = true)
    public Page<DocumentAValiderDto> fileDeValidation(TypeDocument type, String recherche, boolean plusAnciensDabord,
                                                      int page, int taille) {
        return documentService.fileDeValidation(StatutValidation.EN_ATTENTE, type, recherche, plusAnciensDabord, page, taille)
                .map(this::aValider);
    }

    @Transactional
    public DocumentDto validerDocument(Long adminId, Long documentId) {
        Document d = documentService.valider(documentId, adminId);
        Utilisateur u = d.getUtilisateur();
        String libelle = DocumentService.libelle(d);
        tracer(adminId, u, TypeActionAdmin.DOCUMENT_VALIDE, majuscule(libelle));
        avis.envoyer(u, TypeNotification.DOCUMENT_VALIDE, "Document validé", u.isConducteurValide()
                ? "Votre " + libelle + " a été validé(e). Tous vos documents sont validés : vous pouvez publier des trajets !"
                : "Votre " + libelle + " a été validé(e).", "/vehicules");
        return DocumentDto.de(d);
    }

    @Transactional
    public DocumentDto refuserDocument(Long adminId, Long documentId, String motif) {
        Document d = documentService.refuser(documentId, adminId, motif);
        Utilisateur u = d.getUtilisateur();
        String libelle = DocumentService.libelle(d);
        tracer(adminId, u, TypeActionAdmin.DOCUMENT_REFUSE, majuscule(libelle) + " : " + motif.trim());
        avis.envoyer(u, TypeNotification.DOCUMENT_REFUSE, "Document à renvoyer", "Votre " + libelle
                + " a été refusé(e) pour le motif suivant : « " + motif.trim()
                + " ». Vous pouvez en envoyer un nouveau depuis « Mes véhicules et documents ».", "/vehicules");
        return DocumentDto.de(d);
    }

    // ------------------------------------------------------------------ Interne

    private DocumentAValiderDto aValider(Document d) {
        Utilisateur u = d.getUtilisateur();
        List<DocumentDto> autres = documents.findByUtilisateurIdOrderByDateSoumissionDesc(u.getId()).stream()
                .filter(x -> !x.getId().equals(d.getId()))
                .filter(dernierParEmplacement())
                .map(DocumentDto::de).toList();
        return new DocumentAValiderDto(DocumentDto.de(d), UtilisateurLigneDto.de(u), u.isTelephoneVerifie(), u.isEmailVerifie(),
                d.getVehicule() == null ? null : VehiculeDto.de(d.getVehicule()), autres);
    }

    /** Ne garde que la pièce la plus récente de chaque emplacement (type + véhicule) ; la liste arrive triée du plus récent. */
    private static java.util.function.Predicate<Document> dernierParEmplacement() {
        Set<String> vus = new java.util.HashSet<>();
        return d -> vus.add(d.getTypeDocument() + "|" + (d.getVehicule() == null ? "" : d.getVehicule().getId()));
    }

    private void suspendre(Long adminId, Utilisateur u, StatutCompte statut, TypeActionAdmin type, String motif, String message) {
        if (motif == null || motif.isBlank()) throw ApiException.badRequest("Indiquez le motif").surChamp("motif");
        u.setStatut(statut);
        tokens.revoquerTous(u.getId());
        tracer(adminId, u, type, motif.trim());
        avis.envoyer(u, TypeNotification.COMPTE_SUSPENDU, statut == StatutCompte.BANNI ? "Compte banni" : "Compte bloqué",
                message, null);
    }

    private void tracer(Long adminId, Utilisateur u, TypeActionAdmin type, String detail) {
        ActionAdmin a = new ActionAdmin();
        a.setAdmin(utilisateurs.getReferenceById(adminId));
        a.setUtilisateur(u);
        a.setType(type);
        a.setDetail(detail);
        journal.save(a);
    }

    private Utilisateur chargerModifiable(Long adminId, Long id) {
        if (Objects.equals(adminId, id)) throw ApiException.badRequest("Vous ne pouvez pas modifier votre propre compte");
        Utilisateur u = charger(id);
        if (u.getRole() == Role.ADMIN) throw ApiException.forbidden("Le compte d'un administrateur ne peut pas être modifié ici");
        return u;
    }

    private Utilisateur charger(Long id) {
        return utilisateurs.findById(id).orElseThrow(() -> ApiException.notFound("Utilisateur introuvable"));
    }

    private static String majuscule(String s) {
        return s.isEmpty() ? s : Character.toUpperCase(s.charAt(0)) + s.substring(1);
    }
}
