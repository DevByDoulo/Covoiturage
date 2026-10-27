package sn.isep.Convoiturage.vehicule;

import jakarta.validation.constraints.*;

import java.math.BigDecimal;
import java.time.LocalDateTime;

import static sn.isep.Convoiturage.utilisateur.UtilisateurDtos.urlPhoto;

public final class VehiculeDtos {

    private VehiculeDtos() {}

    /**
     * Déclaration ou modification d'un véhicule. Une fois le véhicule validé (carte grise acceptée), seules la
     * consommation et l'usure peuvent changer : le reste figure sur la carte grise.
     */
    public record VehiculeRequete(
            @NotBlank @Pattern(regexp = "^[A-Za-z0-9 \\-]{4,20}$", message = "Immatriculation invalide (ex. DK-1234-AB)") String immatriculation,
            @NotBlank @Size(max = 60) String marque,
            @NotBlank @Size(max = 60) String modele,
            @NotNull @Min(1980) @Max(2100) Integer annee,
            @NotNull @Min(1) @Max(60) Integer puissanceFiscale,
            @NotNull @Min(2) @Max(9) Integer nombrePlaces,
            @NotNull TypeEnergie typeEnergie,
            @DecimalMin("1.0") @DecimalMax("40.0") BigDecimal consommationTheorique,
            @DecimalMin("1.0") @DecimalMax("40.0") BigDecimal consommationReelle,
            @DecimalMin("0") @DecimalMax("1000") BigDecimal amortissementParKm) {}

    public record VehiculeDto(Long id, String immatriculation, String marque, String modele, Integer annee,
                              Integer puissanceFiscale, Integer nombrePlaces, TypeEnergie typeEnergie,
                              BigDecimal consommationTheorique, BigDecimal consommationReelle,
                              BigDecimal amortissementParKm, StatutValidation statutValidation, String photo,
                              LocalDateTime dateCreation) {
        public static VehiculeDto de(Vehicule v) {
            return new VehiculeDto(v.getId(), v.getImmatriculation(), v.getMarque(), v.getModele(), v.getAnnee(),
                    v.getPuissanceFiscale(), v.getNombrePlaces(), v.getTypeEnergie(), v.getConsommationTheorique(),
                    v.getConsommationReelle(), v.getAmortissementParKm(), v.getStatutValidation(), urlPhoto(v.getPhoto()),
                    v.getDateCreation());
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
}
