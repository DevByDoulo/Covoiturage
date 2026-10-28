package sn.isep.Convoiturage.vehicule;

import lombok.RequiredArgsConstructor;
import org.springframework.core.io.Resource;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Sort;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;
import sn.isep.Convoiturage.common.ApiException;
import sn.isep.Convoiturage.common.stockage.StockageService;
import sn.isep.Convoiturage.utilisateur.Role;
import sn.isep.Convoiturage.utilisateur.Utilisateur;
import sn.isep.Convoiturage.utilisateur.UtilisateurRepository;
import sn.isep.Convoiturage.vehicule.VehiculeDtos.DocumentDto;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Objects;

/**
 * Pièces justificatives : permis, pièce d'identité, et carte grise (par véhicule). Elles sont validées ou refusées
 * manuellement par un administrateur (module 07 Administration) ; aucune validation automatique.
 */
@Service
@RequiredArgsConstructor
public class DocumentService {

    private final DocumentRepository documents;
    private final VehiculeService vehiculeService;
    private final UtilisateurRepository utilisateurs;
    private final StockageService stockage;

    public record FichierDocument(Resource ressource, String typeMime, String nomOriginal) {}

    /**
     * Nouvelle pièce, en attente de validation. Une pièce du même type (et du même véhicule) encore en attente est
     * remplacée : l'administrateur n'examine que la dernière envoyée.
     */
    @Transactional
    public DocumentDto soumettre(Long utilisateurId, TypeDocument type, Long vehiculeId, MultipartFile fichier) {
        Utilisateur u = utilisateurs.findById(utilisateurId).orElseThrow(() -> ApiException.notFound("Utilisateur introuvable"));
        if (u.getRole() == Role.ADMIN) throw ApiException.forbidden("Un administrateur n'a pas de documents à fournir");
        Vehicule vehicule = null;
        if (type == TypeDocument.CARTE_GRISE) {
            if (vehiculeId == null) throw ApiException.badRequest("La carte grise doit être rattachée à un véhicule (idVehicule)");
            vehicule = vehiculeService.chargerMien(utilisateurId, vehiculeId);
            if (vehicule.getStatutValidation() == StatutValidation.REFUSE) vehicule.setStatutValidation(StatutValidation.EN_ATTENTE);
        }
        StockageService.FichierStocke stocke = stockage.enregistrer(fichier, StockageService.Dossier.DOCUMENTS);

        Long idVehicule = vehicule == null ? null : vehicule.getId();
        documents.findByUtilisateurIdAndTypeDocumentAndStatutValidation(utilisateurId, type, StatutValidation.EN_ATTENTE).stream()
                .filter(d -> Objects.equals(d.getVehicule() == null ? null : d.getVehicule().getId(), idVehicule))
                .forEach(documents::delete);

        Document d = new Document();
        d.setUtilisateur(u);
        d.setVehicule(vehicule);
        d.setTypeDocument(type);
        d.setFichier(stocke.nom());
        d.setTypeMime(stocke.typeMime());
        String nomOriginal = fichier.getOriginalFilename();
        d.setNomOriginal(nomOriginal == null ? null : nomOriginal.substring(0, Math.min(255, nomOriginal.length())));
        return DocumentDto.de(documents.save(d));
    }

    @Transactional(readOnly = true)
    public List<DocumentDto> mesDocuments(Long utilisateurId) {
        return documents.findByUtilisateurIdOrderByDateSoumissionDesc(utilisateurId).stream().map(DocumentDto::de).toList();
    }

    // ------------------------------------------------------------------ Décisions de l'administrateur (module 07)

    @Transactional(readOnly = true)
    public Page<Document> fileDeValidation(StatutValidation statut, TypeDocument type, String recherche,
                                           boolean plusAnciensDabord, int page, int taille) {
        String motif = recherche == null || recherche.isBlank() ? null : "%" + recherche.trim().toLowerCase() + "%";
        Sort tri = Sort.by(plusAnciensDabord ? Sort.Direction.ASC : Sort.Direction.DESC, "dateSoumission");
        return documents.fileDeValidation(statut, type, motif, PageRequest.of(page, Math.min(taille, 100), tri));
    }

    /** Valide une pièce en attente et recalcule le statut conducteur de son titulaire. */
    @Transactional
    public Document valider(Long documentId, Long adminId) {
        Document d = chargerEnAttente(documentId);
        d.setStatutValidation(StatutValidation.VALIDE);
        d.setCommentaireAdmin(null);
        tracer(d, adminId);
        if (d.getTypeDocument() == TypeDocument.CARTE_GRISE) d.getVehicule().setStatutValidation(StatutValidation.VALIDE);
        vehiculeService.recalculerStatutConducteur(d.getUtilisateur());
        return d;
    }

    /** Refuse une pièce en attente ; le motif est montré au titulaire, qui peut en envoyer une nouvelle. */
    @Transactional
    public Document refuser(Long documentId, Long adminId, String motif) {
        if (motif == null || motif.isBlank()) throw ApiException.badRequest("Indiquez le motif du refus").surChamp("motif");
        Document d = chargerEnAttente(documentId);
        d.setStatutValidation(StatutValidation.REFUSE);
        d.setCommentaireAdmin(motif.trim());
        tracer(d, adminId);
        if (d.getTypeDocument() == TypeDocument.CARTE_GRISE) d.getVehicule().setStatutValidation(StatutValidation.REFUSE);
        vehiculeService.recalculerStatutConducteur(d.getUtilisateur());
        return d;
    }

    private Document chargerEnAttente(Long documentId) {
        Document d = documents.findById(documentId).orElseThrow(() -> ApiException.notFound("Document introuvable"));
        if (d.getStatutValidation() != StatutValidation.EN_ATTENTE) throw ApiException.conflict("Ce document a déjà été traité");
        return d;
    }

    private void tracer(Document d, Long adminId) {
        d.setAdminValidateur(utilisateurs.getReferenceById(adminId));
        d.setDateValidation(LocalDateTime.now());
    }

    /** Libellé lisible d'une pièce, pour les messages : « permis de conduire », « carte grise (DK-1234-AB) »… */
    public static String libelle(Document d) {
        return switch (d.getTypeDocument()) {
            case PERMIS_CONDUIRE -> "permis de conduire";
            case PIECE_IDENTITE -> "pièce d'identité";
            case CARTE_GRISE -> "carte grise (" + d.getVehicule().getImmatriculation() + ")";
        };
    }

    /** Le fichier n'est accessible qu'à son propriétaire et aux administrateurs. */
    @Transactional(readOnly = true)
    public FichierDocument fichier(Long documentId, Long demandeurId, boolean estAdmin) {
        Document d = documents.findById(documentId).orElseThrow(() -> ApiException.notFound("Document introuvable"));
        if (!estAdmin && !d.getUtilisateur().getId().equals(demandeurId)) throw ApiException.notFound("Document introuvable");
        return new FichierDocument(stockage.charger(d.getFichier(), StockageService.Dossier.DOCUMENTS), d.getTypeMime(), d.getNomOriginal());
    }
}
