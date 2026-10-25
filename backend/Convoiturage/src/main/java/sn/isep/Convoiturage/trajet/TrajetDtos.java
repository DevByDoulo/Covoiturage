package sn.isep.Convoiturage.trajet;

import com.fasterxml.jackson.annotation.JsonInclude;
import jakarta.validation.Valid;
import jakarta.validation.constraints.*;
import sn.isep.Convoiturage.common.geo.Coordonnee;
import sn.isep.Convoiturage.common.geo.GeoUtils;
import sn.isep.Convoiturage.common.geo.PolylineCodec;
import sn.isep.Convoiturage.tarification.MoteurTarification.EstimationPrix;
import sn.isep.Convoiturage.tarification.Tarification;
import sn.isep.Convoiturage.trajet.itineraire.ItineraireService.Itineraire;
import sn.isep.Convoiturage.utilisateur.UtilisateurDtos.PreferenceDto;
import sn.isep.Convoiturage.utilisateur.UtilisateurDtos.UtilisateurResume;
import sn.isep.Convoiturage.vehicule.VehiculeDtos.VehiculeResume;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;

public final class TrajetDtos {

    private TrajetDtos() {}

    public record PointDto(
            @NotBlank @Size(max = 200) String lieu,
            @NotNull @DecimalMin("-90") @DecimalMax("90") Double latitude,
            @NotNull @DecimalMin("-180") @DecimalMax("180") Double longitude) {
        Coordonnee coordonnee() { return new Coordonnee(latitude, longitude); }
    }

    public record EstimationRequete(
            @NotNull Long idVehicule,
            @NotNull @Valid PointDto depart,
            @NotNull @Valid PointDto arrivee,
            @Size(max = 5) List<@Valid PointDto> escales,
            @NotNull @Future LocalDateTime dateHeureDepart,
            @NotNull @Min(1) @Max(8) Integer nombrePlaces) {}

    public record EstimationReponse(double distanceKm, int dureeEstimeeMin, TypeRoute typeRoute,
                                    BigDecimal montantPeages, String sourceItineraire, String itinerairePolyline,
                                    EstimationPrix tarif) {
        static EstimationReponse de(Itineraire it, EstimationPrix tarif) {
            return new EstimationReponse(it.distanceKm(), it.dureeMin(), it.typeRoute(), it.montantPeages(), it.source(),
                    PolylineCodec.encoder(it.trace()), tarif);
        }
    }

    public record PublicationRequete(
            @NotNull Long idVehicule,
            @NotNull @Valid PointDto depart,
            @NotNull @Valid PointDto arrivee,
            @Size(max = 5) List<@Valid PointDto> escales,
            @NotNull @Future LocalDateTime dateHeureDepart,
            @NotNull @Min(15) @Max(30) Integer flexibiliteMinutes,
            @NotNull @Min(1) @Max(8) Integer nombrePlaces,
            @NotNull ModeReservation modeReservation,
            @NotNull TailleBagage tailleBagage,
            boolean femmesUniquement,
            /* Facultatif : prix choisi dans la fourchette proposée ; par défaut le prix recommandé. */
            @DecimalMin("0") BigDecimal prixParPlace) {}

    /** Tous les champs sont facultatifs : seuls ceux fournis sont modifiés. L'itinéraire ne se modifie pas. */
    public record ModificationTrajetRequete(
            @Future LocalDateTime dateHeureDepart,
            @Min(15) @Max(30) Integer flexibiliteMinutes,
            @Min(1) @Max(8) Integer nombrePlaces,
            ModeReservation modeReservation,
            TailleBagage tailleBagage,
            @DecimalMin("0") BigDecimal prixParPlace) {}

    public record AnnulationRequete(@Size(max = 500) String motif) {}

    public record EscaleDto(Long id, int ordre, String lieu, double latitude, double longitude) {
        static EscaleDto de(Escale e) {
            return new EscaleDto(e.getId(), e.getOrdre(), e.getLieu(), e.getLatitude(), e.getLongitude());
        }
    }

    public record TarificationDto(BigDecimal prixIa, BigDecimal prixMin, BigDecimal prixMax, BigDecimal prixFinal,
                                  BigDecimal prixCarburantUtilise, boolean heureDePointe, String versionModele,
                                  LocalDateTime datePrediction) {
        static TarificationDto de(Tarification t) {
            return new TarificationDto(t.getPrixIa(), t.getPrixMin(), t.getPrixMax(), t.getPrixFinal(),
                    t.getPrixCarburantUtilise(), t.isHeureDePointe(), t.getVersionModele(), t.getDatePrediction());
        }
    }

    /** Informations propres à un résultat de recherche (où le passager rejoint et quitte le tracé). */
    public record CorrespondanceDto(int distanceRamassageM, int distanceDeposeM,
                                    double latitudeRamassage, double longitudeRamassage,
                                    double latitudeDepose, double longitudeDepose) {}

    @JsonInclude(JsonInclude.Include.NON_NULL)
    public record TrajetDto(Long id, UtilisateurResume conducteur, PreferenceDto preferencesConducteur,
                            VehiculeResume vehicule, PointDto depart, PointDto arrivee, List<EscaleDto> escales,
                            LocalDateTime dateHeureDepart, int flexibiliteMinutes, int nombrePlacesTotal,
                            int nombrePlacesDisponibles, ModeReservation modeReservation, TailleBagage tailleBagage,
                            boolean femmesUniquement, BigDecimal distanceKm, int dureeEstimeeMin, TypeRoute typeRoute,
                            BigDecimal prixParPlace, StatutTrajet statut, String motifAnnulation,
                            String itinerairePolyline,
                            /* Uniquement pour le conducteur du trajet. */
                            TarificationDto tarification,
                            /* Uniquement dans les résultats de recherche. */
                            CorrespondanceDto correspondance) {

        static TrajetDto de(Trajet t, boolean vueConducteur, CorrespondanceDto correspondance) {
            return new TrajetDto(t.getId(), UtilisateurResume.de(t.getConducteur()),
                    PreferenceDto.de(t.getConducteur().getPreference()), VehiculeResume.de(t.getVehicule()),
                    new PointDto(t.getLieuDepart(), t.getLatitudeDepart(), t.getLongitudeDepart()),
                    new PointDto(t.getLieuArrivee(), t.getLatitudeArrivee(), t.getLongitudeArrivee()),
                    t.getEscales().stream().map(EscaleDto::de).toList(),
                    t.getDateHeureDepart(), t.getFlexibiliteMinutes(), t.getNombrePlacesTotal(),
                    t.getNombrePlacesDisponibles(), t.getModeReservation(), t.getTailleBagage(), t.isFemmesUniquement(),
                    t.getDistanceKm(), t.getDureeEstimeeMin(), t.getTypeRoute(), t.getTarification().getPrixFinal(),
                    t.getStatut(), t.getMotifAnnulation(),
                    PolylineCodec.encoder(GeoUtils.coordonnees(t.getItineraire())),
                    vueConducteur ? TarificationDto.de(t.getTarification()) : null,
                    correspondance);
        }
    }
}
