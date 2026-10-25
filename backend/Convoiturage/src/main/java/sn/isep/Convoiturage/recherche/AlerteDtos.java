package sn.isep.Convoiturage.recherche;

import jakarta.validation.Valid;
import jakarta.validation.constraints.DecimalMax;
import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.FutureOrPresent;
import jakarta.validation.constraints.NotNull;
import sn.isep.Convoiturage.trajet.TrajetDtos.PointDto;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;

public final class AlerteDtos {

    private AlerteDtos() {}

    public record CreationAlerteRequete(
            @NotNull @Valid PointDto depart,
            @NotNull @Valid PointDto arrivee,
            @NotNull @FutureOrPresent LocalDate date,
            @DecimalMin("0.5") @DecimalMax("30") BigDecimal rayonKm,
            @DecimalMin("0") BigDecimal prixMax) {}

    public record AlerteDto(Long id, PointDto depart, PointDto arrivee, LocalDate date, BigDecimal rayonKm,
                            BigDecimal prixMax, LocalDateTime dateCreation) {
        static AlerteDto de(AlerteRecherche a) {
            return new AlerteDto(a.getId(),
                    new PointDto(a.getVilleDepart(), a.getLatitudeDepart(), a.getLongitudeDepart()),
                    new PointDto(a.getVilleArrivee(), a.getLatitudeArrivee(), a.getLongitudeArrivee()),
                    a.getDateDepart(), a.getRayonKm(), a.getPrixMax(), a.getDateCreation());
        }
    }
}
