package sn.isep.Convoiturage.vehicule;

import lombok.RequiredArgsConstructor;
import org.springframework.core.io.Resource;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;
import sn.isep.Convoiturage.common.ApiException;
import sn.isep.Convoiturage.common.stockage.StockageService;
import sn.isep.Convoiturage.notification.NotificationService;
import sn.isep.Convoiturage.notification.TypeNotification;
import sn.isep.Convoiturage.utilisateur.Utilisateur;
import sn.isep.Convoiturage.utilisateur.UtilisateurRepository;
import sn.isep.Convoiturage.vehicule.VehiculeDtos.DocumentAValiderDto;
import sn.isep.Convoiturage.vehicule.VehiculeDtos.DocumentDto;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Map;

/**
 * Cycle de vie des pièces justificatives : soumission par le conducteur, puis validation
 * ou refus manuel par un administrateur (aucune auto-validation).
 */
@Service
@RequiredArgsConstructor
public class DocumentService {

    private final DocumentRepository documents;
    private final VehiculeService vehiculeService;
    private final UtilisateurRepository utilisateurs;
    private final StockageService stockage;
    private final NotificationService notifications;

    public record FichierDocument(Resource ressource, String typeMime, String nomOriginal) {}

    @Transactional
    public DocumentDto soumettre(Long utilisateurId, TypeDocument type, Long vehiculeId, MultipartFile fichier) {
        Utilisateur u = utilisateurs.findById(utilisateurId).orElseThrow(() -> ApiException.notFound("Utilisateur introuvable"));
        Vehicule vehicule = null;
        if (type == TypeDocument.CARTE_GRISE) {
            if (vehiculeId == null) throw ApiException.badRequest("La carte grise doit être rattachée à un véhicule (idVehicule)");
            vehicule = vehiculeService.chargerMien(utilisateurId, vehiculeId);
            if (vehicule.getStatutValidation() == StatutValidation.REFUSE) vehicule.setStatutValidation(StatutValidation.EN_ATTENTE);
        }
        StockageService.FichierStocke stocke = stockage.enregistrer(fichier, StockageService.Dossier.DOCUMENTS);
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

    /** Le fichier n'est accessible qu'à son propriétaire et aux administrateurs. */
    @Transactional(readOnly = true)
    public FichierDocument fichier(Long documentId, Long demandeurId, boolean estAdmin) {
        Document d = documents.findById(documentId).orElseThrow(() -> ApiException.notFound("Document introuvable"));
        if (!estAdmin && !d.getUtilisateur().getId().equals(demandeurId)) throw ApiException.notFound("Document introuvable");
        return new FichierDocument(stockage.charger(d.getFichier(), StockageService.Dossier.DOCUMENTS), d.getTypeMime(), d.getNomOriginal());
    }

    @Transactional(readOnly = true)
    public Page<DocumentAValiderDto> fileDeValidation(StatutValidation statut, int page, int taille) {
        return documents.findByStatutValidationOrderByDateSoumissionAsc(statut, PageRequest.of(page, Math.min(taille, 100)))
                .map(DocumentAValiderDto::de);
    }

    @Transactional
    public DocumentDto valider(Long documentId, Long adminId) {
        Document d = chargerEnAttente(documentId);
        d.setStatutValidation(StatutValidation.VALIDE);
        d.setCommentaireAdmin(null);
        tracer(d, adminId);
        if (d.getTypeDocument() == TypeDocument.CARTE_GRISE) d.getVehicule().setStatutValidation(StatutValidation.VALIDE);
        Utilisateur u = d.getUtilisateur();
        boolean etaitValide = u.isConducteurValide();
        vehiculeService.recalculerStatutConducteur(u);

        String libelle = libelle(d);
        String message = u.isConducteurValide() && !etaitValide
                ? "Votre " + libelle + " a été validé(e). Vous pouvez maintenant publier des trajets !"
                : "Votre " + libelle + " a été validé(e).";
        notifications.notifier(u, TypeNotification.DOCUMENT_VALIDE, "Document validé", message,
                Map.of("idDocument", d.getId().toString()));
        return DocumentDto.de(d);
    }

    @Transactional
    public DocumentDto refuser(Long documentId, Long adminId, String commentaire) {
        Document d = chargerEnAttente(documentId);
        d.setStatutValidation(StatutValidation.REFUSE);
        d.setCommentaireAdmin(commentaire);
        tracer(d, adminId);
        if (d.getTypeDocument() == TypeDocument.CARTE_GRISE) d.getVehicule().setStatutValidation(StatutValidation.REFUSE);
        vehiculeService.recalculerStatutConducteur(d.getUtilisateur());
        notifications.notifier(d.getUtilisateur(), TypeNotification.DOCUMENT_REFUSE, "Document refusé",
                "Votre " + libelle(d) + " a été refusé(e) : " + commentaire + ". Vous pouvez soumettre un nouveau document.",
                Map.of("idDocument", d.getId().toString()));
        return DocumentDto.de(d);
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

    private static String libelle(Document d) {
        return d.getTypeDocument() == TypeDocument.PERMIS_CONDUIRE
                ? "permis de conduire"
                : "carte grise (" + d.getVehicule().getImmatriculation() + ")";
    }
}
