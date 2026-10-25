package sn.isep.Convoiturage.vehicule;

import jakarta.validation.constraints.*;
import sn.isep.Convoiturage.utilisateur.Utilisateur;

import java.math.BigDecimal;
import java.time.LocalDateTime;

public final class VehiculeDtos {

    private VehiculeDtos() {}

    public record DeclarationVehiculeRequete(
            @NotBlank @Pattern(regexp = "^[A-Za-z0-9 \\-]{4,20}$", message = "Immatriculation invalide") String immatriculation,
            @NotBlank @Size(max = 60) String marque,
            @NotBlank @Size(max = 60) String modele,
            @NotNull @Min(1980) @Max(2100) Integer annee,
            @NotNull @Min(1) @Max(60) Integer puissanceFiscale,
            @NotNull @Min(2) @Max(9) Integer nombrePlaces,
            @NotNull TypeEnergie typeEnergie,
            @DecimalMin("1.0") @DecimalMax("40.0") BigDecimal consommationTheorique,
            @DecimalMin("1.0") @DecimalMax("40.0") BigDecimal consommationReelle,
            @DecimalMin("0") @DecimalMax("1000") BigDecimal amortissementParKm) {}

    /** Seules les données d'usage sont modifiables ; le reste figure sur la carte grise validée. */
    public record ModificationVehiculeRequete(
            @DecimalMin("1.0") @DecimalMax("40.0") BigDecimal consommationTheorique,
            @DecimalMin("1.0") @DecimalMax("40.0") BigDecimal consommationReelle,
            @DecimalMin("0") @DecimalMax("1000") BigDecimal amortissementParKm) {}

    public record VehiculeDto(Long id, String immatriculation, String marque, String modele, Integer annee,
                              Integer puissanceFiscale, Integer nombrePlaces, TypeEnergie typeEnergie,
                              BigDecimal consommationTheorique, BigDecimal consommationReelle,
                              BigDecimal amortissementParKm, StatutValidation statutValidation, boolean actif,
                              LocalDateTime dateCreation) {
        public static VehiculeDto de(Vehicule v) {
            return new VehiculeDto(v.getId(), v.getImmatriculation(), v.getMarque(), v.getModele(), v.getAnnee(),
                    v.getPuissanceFiscale(), v.getNombrePlaces(), v.getTypeEnergie(), v.getConsommationTheorique(),
                    v.getConsommationReelle(), v.getAmortissementParKm(), v.getStatutValidation(), v.isActif(),
                    v.getDateCreation());
        }
    }

    public record VehiculeResume(Long id, String marque, String modele, Integer annee, TypeEnergie typeEnergie) {
        public static VehiculeResume de(Vehicule v) {
            return new VehiculeResume(v.getId(), v.getMarque(), v.getModele(), v.getAnnee(), v.getTypeEnergie());
        }
    }

    public record DocumentDto(Long id, TypeDocument typeDocument, Long idVehicule, String immatriculation,
                              String nomOriginal, String typeMime, StatutValidation statutValidation,
                              String commentaireAdmin, LocalDateTime dateSoumission, LocalDateTime dateValidation,
                              String urlFichier) {
        public static DocumentDto de(Document d) {
            Vehicule v = d.getVehicule();
            return new DocumentDto(d.getId(), d.getTypeDocument(), v == null ? null : v.getId(),
                    v == null ? null : v.getImmatriculation(), d.getNomOriginal(), d.getTypeMime(),
                    d.getStatutValidation(), d.getCommentaireAdmin(), d.getDateSoumission(), d.getDateValidation(),
                    "/api/documents/" + d.getId() + "/fichier");
        }
    }

    /** Ligne de la file de validation du back-office. */
    public record DocumentAValiderDto(DocumentDto document, Long idUtilisateur, String nomComplet, String telephone,
                                      String email, VehiculeDto vehicule) {
        public static DocumentAValiderDto de(Document d) {
            Utilisateur u = d.getUtilisateur();
            return new DocumentAValiderDto(DocumentDto.de(d), u.getId(), u.nomComplet(), u.getTelephone(), u.getEmail(),
                    d.getVehicule() == null ? null : VehiculeDto.de(d.getVehicule()));
        }
    }

    public record RefusRequete(@NotBlank @Size(max = 500) String commentaire) {}
}
