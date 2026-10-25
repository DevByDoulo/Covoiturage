package sn.isep.Convoiturage.vehicule;

import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import sn.isep.Convoiturage.common.ApiException;
import sn.isep.Convoiturage.utilisateur.Role;
import sn.isep.Convoiturage.utilisateur.Utilisateur;
import sn.isep.Convoiturage.utilisateur.UtilisateurRepository;
import sn.isep.Convoiturage.vehicule.VehiculeDtos.*;

import java.util.List;

@Service
@RequiredArgsConstructor
public class VehiculeService {

    private final VehiculeRepository vehicules;
    private final DocumentRepository documents;
    private final UtilisateurRepository utilisateurs;

    /** Déclarer un véhicule fait passer le compte en rôle CONDUCTEUR (non validé tant que les documents ne le sont pas). */
    @Transactional
    public VehiculeDto declarer(Long utilisateurId, DeclarationVehiculeRequete req) {
        Utilisateur u = utilisateurs.findById(utilisateurId).orElseThrow(() -> ApiException.notFound("Utilisateur introuvable"));
        if (u.getRole() == Role.ADMIN) throw ApiException.forbidden("Un administrateur ne peut pas déclarer de véhicule");
        String immat = normaliserImmatriculation(req.immatriculation());
        if (vehicules.existsByImmatriculationIgnoreCase(immat)) {
            throw ApiException.conflict("Un véhicule avec cette immatriculation est déjà enregistré");
        }
        Vehicule v = new Vehicule();
        v.setProprietaire(u);
        v.setImmatriculation(immat);
        v.setMarque(req.marque().trim());
        v.setModele(req.modele().trim());
        v.setAnnee(req.annee());
        v.setPuissanceFiscale(req.puissanceFiscale());
        v.setNombrePlaces(req.nombrePlaces());
        v.setTypeEnergie(req.typeEnergie());
        v.setConsommationTheorique(req.consommationTheorique());
        v.setConsommationReelle(req.consommationReelle());
        v.setAmortissementParKm(req.amortissementParKm());
        vehicules.save(v);
        if (u.getRole() == Role.PASSAGER) u.setRole(Role.CONDUCTEUR);
        return VehiculeDto.de(v);
    }

    @Transactional(readOnly = true)
    public List<VehiculeDto> mesVehicules(Long utilisateurId) {
        return vehicules.findByProprietaireIdAndActifTrueOrderByDateCreationDesc(utilisateurId).stream()
                .map(VehiculeDto::de).toList();
    }

    @Transactional
    public VehiculeDto modifier(Long utilisateurId, Long vehiculeId, ModificationVehiculeRequete req) {
        Vehicule v = chargerMien(utilisateurId, vehiculeId);
        v.setConsommationTheorique(req.consommationTheorique());
        v.setConsommationReelle(req.consommationReelle());
        v.setAmortissementParKm(req.amortissementParKm());
        return VehiculeDto.de(v);
    }

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

    /** Conducteur validé = permis validé ET au moins un véhicule actif dont la carte grise est validée. */
    @Transactional
    public void recalculerStatutConducteur(Utilisateur u) {
        boolean permisValide = documents.existsByUtilisateurIdAndTypeDocumentAndStatutValidation(
                u.getId(), TypeDocument.PERMIS_CONDUIRE, StatutValidation.VALIDE);
        boolean vehiculeValide = vehicules.existsByProprietaireIdAndStatutValidationAndActifTrue(u.getId(), StatutValidation.VALIDE);
        u.setConducteurValide(permisValide && vehiculeValide);
    }

    static String normaliserImmatriculation(String brut) {
        return brut.trim().toUpperCase().replaceAll("\\s+", "-");
    }
}
