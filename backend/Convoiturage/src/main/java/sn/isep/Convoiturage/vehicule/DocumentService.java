package sn.isep.Convoiturage.vehicule;

import lombok.RequiredArgsConstructor;
import org.springframework.core.io.Resource;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;
import sn.isep.Convoiturage.common.ApiException;
import sn.isep.Convoiturage.common.stockage.StockageService;
import sn.isep.Convoiturage.utilisateur.Role;
import sn.isep.Convoiturage.utilisateur.Utilisateur;
import sn.isep.Convoiturage.utilisateur.UtilisateurRepository;
import sn.isep.Convoiturage.vehicule.VehiculeDtos.DocumentDto;

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

    /** Le fichier n'est accessible qu'à son propriétaire et aux administrateurs. */
    @Transactional(readOnly = true)
    public FichierDocument fichier(Long documentId, Long demandeurId, boolean estAdmin) {
        Document d = documents.findById(documentId).orElseThrow(() -> ApiException.notFound("Document introuvable"));
        if (!estAdmin && !d.getUtilisateur().getId().equals(demandeurId)) throw ApiException.notFound("Document introuvable");
        return new FichierDocument(stockage.charger(d.getFichier(), StockageService.Dossier.DOCUMENTS), d.getTypeMime(), d.getNomOriginal());
    }
}
