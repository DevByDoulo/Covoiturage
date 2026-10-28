package sn.isep.Convoiturage.avis;

import com.fasterxml.jackson.annotation.JsonInclude;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import sn.isep.Convoiturage.reservation.Reservation;
import sn.isep.Convoiturage.trajet.Trajet;
import sn.isep.Convoiturage.utilisateur.UtilisateurDtos.UtilisateurResume;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;

public final class AvisDtos {

    private AvisDtos() {}

    /** Rôle de la personne notée sur ce trajet. */
    public enum RoleEvalue { CONDUCTEUR, PASSAGER }

    public record EvaluationRequete(
            @NotNull @Min(1) @Max(5) Integer note,
            @Size(max = 500) String commentaire) {}

    /** Voyage terminé que l'utilisateur peut encore noter (avant {@code dateLimite}). */
    public record AvisADonnerDto(Long idReservation, Long idTrajet, String trajet, LocalDateTime dateHeureDepart,
                                 UtilisateurResume aNoter, RoleEvalue role, LocalDateTime dateLimite) {

        static AvisADonnerDto de(Reservation r, boolean jeSuisConducteur, LocalDateTime dateLimite) {
            Trajet t = r.getTrajet();
            return new AvisADonnerDto(r.getId(), t.getId(), t.getLieuDepart() + " → " + t.getLieuArrivee(),
                    t.getDateHeureDepart(),
                    UtilisateurResume.de(jeSuisConducteur ? r.getPassager() : t.getConducteur()),
                    jeSuisConducteur ? RoleEvalue.PASSAGER : RoleEvalue.CONDUCTEUR, dateLimite);
        }
    }

    /** Avis public : l'auteur est réduit à son prénom et à l'initiale de son nom. */
    @JsonInclude(JsonInclude.Include.NON_NULL)
    public record AvisDto(Long id, int note, String commentaire, LocalDateTime dateEvaluation,
                          UtilisateurResume auteur, RoleEvalue roleEvalue, String trajet) {

        static AvisDto de(Evaluation e) {
            Trajet t = e.getTrajet();
            return new AvisDto(e.getId(), e.getNote(), e.getCommentaire(), e.getDateEvaluation(),
                    UtilisateurResume.de(e.getEvaluateur()),
                    e.parConducteur() ? RoleEvalue.PASSAGER : RoleEvalue.CONDUCTEUR,
                    t.getLieuDepart() + " → " + t.getLieuArrivee());
        }
    }

    /**
     * Réputation d'une personne : moyenne, nombre d'avis, nombre d'avis par note
     * ({@code repartition[0]} = avis à 1 étoile … {@code repartition[4]} = avis à 5 étoiles) et derniers avis.
     */
    public record ReputationDto(Long idUtilisateur, BigDecimal noteMoyenne, long nombreAvis, long[] repartition,
                                List<AvisDto> avis) {}
}
