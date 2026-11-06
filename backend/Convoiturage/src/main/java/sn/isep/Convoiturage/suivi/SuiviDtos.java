package sn.isep.Convoiturage.suivi;

import jakarta.validation.constraints.DecimalMax;
import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotNull;

import java.time.LocalDateTime;

public final class SuiviDtos {

    private SuiviDtos() {}

    /** Position envoyée par le téléphone du conducteur (précision, cap et vitesse facultatifs). */
    public record PositionRequete(
            @NotNull @DecimalMin("-90") @DecimalMax("90") Double latitude,
            @NotNull @DecimalMin("-180") @DecimalMax("180") Double longitude,
            @Min(0) @Max(100000) Integer precisionM,
            @DecimalMin("0") @DecimalMax("360") Double cap,
            @DecimalMin("0") @DecimalMax("100") Double vitesse) {}

    /** Position vue par les passagers ; [ageSecondes] : temps écoulé depuis le dernier envoi. */
    public record PositionDto(double latitude, double longitude, Integer precisionM, Double cap, Double vitesse,
                              LocalDateTime dateMaj, long ageSecondes) {
        static PositionDto de(PositionConducteur p, LocalDateTime maintenant) {
            return new PositionDto(p.getLatitude(), p.getLongitude(), p.getPrecisionM(), p.getCap(), p.getVitesse(),
                    p.getDateMaj(), Math.max(0, java.time.Duration.between(p.getDateMaj(), maintenant).toSeconds()));
        }
    }
}
