package sn.isep.Convoiturage.vehicule;

import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;
import sn.isep.Convoiturage.common.ApiException;
import sn.isep.Convoiturage.common.stockage.StockageService;
import sn.isep.Convoiturage.utilisateur.Role;
import sn.isep.Convoiturage.utilisateur.Utilisateur;
import sn.isep.Convoiturage.utilisateur.UtilisateurRepository;
import sn.isep.Convoiturage.vehicule.VehiculeDtos.VehiculeDto;
import sn.isep.Convoiturage.vehicule.VehiculeDtos.VehiculeRequete;

import java.util.List;
import java.util.Objects;

@Service
@RequiredArgsConstructor
public class VehiculeService {

    private final VehiculeRepository vehicules;
    private final DocumentRepository documents;
    private final UtilisateurRepository utilisateurs;
    private final StockageService stockage;

    /**
     * Déclarer un véhicule fait passer le compte en rôle CONDUCTEUR (non validé tant que les documents ne le sont pas).
     * Un véhicule que l'utilisateur avait retiré est simplement réactivé.
     */
    @Transactional
    public VehiculeDto declarer(Long utilisateurId, VehiculeRequete req) {
        Utilisateur u = utilisateurs.findById(utilisateurId).orElseThrow(() -> ApiException.notFound("Utilisateur introuvable"));
        if (u.getRole() == Role.ADMIN) throw ApiException.forbidden("Un administrateur ne peut pas déclarer de véhicule");
        String immat = normaliserImmatriculation(req.immatriculation());
        Vehicule v = vehicules.findByImmatriculationIgnoreCase(immat).map(existant -> {
            if (!existant.getProprietaire().getId().equals(utilisateurId) || existant.isActif()) {
                throw ApiException.conflict("Un véhicule avec cette immatriculation est déjà enregistré").surChamp("immatriculation");
            }
            existant.setActif(true);
            return existant;
        }).orElseGet(() -> {
            Vehicule nouveau = new Vehicule();
            nouveau.setProprietaire(u);
            nouveau.setImmatriculation(immat);
            return nouveau;
        });
        if (v.getStatutValidation() != StatutValidation.VALIDE) appliquerIdentite(v, req);
        appliquerUsage(v, req);
        vehicules.save(v);
        if (u.getRole() == Role.PASSAGER) u.setRole(Role.CONDUCTEUR);
        recalculerStatutConducteur(u);
        return VehiculeDto.de(v);
    }

    @Transactional(readOnly = true)
    public List<VehiculeDto> mesVehicules(Long utilisateurId) {
        return vehicules.findByProprietaireIdAndActifTrueOrderByDateCreationDesc(utilisateurId).stream()
                .map(VehiculeDto::de).toList();
    }

    /** Avant validation, tout est modifiable ; après, seulement la consommation et l'usure. */
    @Transactional
    public VehiculeDto modifier(Long utilisateurId, Long vehiculeId, VehiculeRequete req) {
        Vehicule v = chargerMien(utilisateurId, vehiculeId);
        if (v.getStatutValidation() == StatutValidation.VALIDE) {
            boolean identiteModifiee = !normaliserImmatriculation(req.immatriculation()).equals(v.getImmatriculation())
                    || !req.marque().trim().equals(v.getMarque()) || !req.modele().trim().equals(v.getModele())
                    || !Objects.equals(req.annee(), v.getAnnee()) || !Objects.equals(req.puissanceFiscale(), v.getPuissanceFiscale())
                    || !Objects.equals(req.nombrePlaces(), v.getNombrePlaces()) || req.typeEnergie() != v.getTypeEnergie();
            if (identiteModifiee) {
                throw ApiException.conflict("Ce véhicule a été validé : seules la consommation et l'usure peuvent changer. "
                        + "Pour une autre voiture, ajoutez un nouveau véhicule.");
            }
        } else {
            String immat = normaliserImmatriculation(req.immatriculation());
            vehicules.findByImmatriculationIgnoreCase(immat).filter(autre -> !autre.getId().equals(v.getId())).ifPresent(autre -> {
                throw ApiException.conflict("Un véhicule avec cette immatriculation est déjà enregistré").surChamp("immatriculation");
            });
            v.setImmatriculation(immat);
            appliquerIdentite(v, req);
        }
        appliquerUsage(v, req);
        return VehiculeDto.de(v);
    }

    @Transactional
    public VehiculeDto changerPhoto(Long utilisateurId, Long vehiculeId, MultipartFile fichier) {
        Vehicule v = chargerMien(utilisateurId, vehiculeId);
        v.setPhoto(stockage.enregistrer(fichier, StockageService.Dossier.PHOTOS).nom());
        return VehiculeDto.de(v);
    }

    /** Retire le véhicule de la liste (il reste en base pour l'historique des trajets). */
    @Transactional
    public void desactiver(Long utilisateurId, Long vehiculeId) {
        Vehicule v = chargerMien(utilisateurId, vehiculeId);
        v.setActif(false);
        recalculerStatutConducteur(v.getProprietaire());
    }

    Vehicule chargerMien(Long utilisateurId, Long vehiculeId) {
        return vehicules.findByIdAndProprietaireId(vehiculeId, utilisateurId)
                .filter(Vehicule::isActif)
                .orElseThrow(() -> ApiException.notFound("Véhicule introuvable"));
    }

    /**
     * Conducteur validé = permis ET pièce d'identité validés ET au moins un véhicule actif dont la carte grise est
     * validée. À rappeler après chaque décision de l'administrateur (module 07).
     */
    @Transactional
    public void recalculerStatutConducteur(Utilisateur u) {
        boolean permis = documents.existsByUtilisateurIdAndTypeDocumentAndStatutValidation(
                u.getId(), TypeDocument.PERMIS_CONDUIRE, StatutValidation.VALIDE);
        boolean identite = documents.existsByUtilisateurIdAndTypeDocumentAndStatutValidation(
                u.getId(), TypeDocument.PIECE_IDENTITE, StatutValidation.VALIDE);
        boolean vehicule = vehicules.existsByProprietaireIdAndStatutValidationAndActifTrue(u.getId(), StatutValidation.VALIDE);
        u.setConducteurValide(permis && identite && vehicule);
    }

    static String normaliserImmatriculation(String brut) {
        return brut.trim().toUpperCase().replaceAll("\\s+", "-");
    }

    private static void appliquerIdentite(Vehicule v, VehiculeRequete req) {
        v.setMarque(req.marque().trim());
        v.setModele(req.modele().trim());
        v.setAnnee(req.annee());
        v.setPuissanceFiscale(req.puissanceFiscale());
        v.setNombrePlaces(req.nombrePlaces());
        v.setTypeEnergie(req.typeEnergie());
    }

    private static void appliquerUsage(Vehicule v, VehiculeRequete req) {
        v.setConsommationTheorique(req.consommationTheorique());
        v.setConsommationReelle(req.consommationReelle());
        v.setAmortissementParKm(req.amortissementParKm());
    }
}
