package sn.isep.Convoiturage.signalement;

import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import sn.isep.Convoiturage.admin.AdminDtos.UtilisateurLigneDto;
import sn.isep.Convoiturage.trajet.Trajet;
import sn.isep.Convoiturage.utilisateur.UtilisateurDtos.UtilisateurResume;

import java.time.LocalDateTime;

public final class SignalementDtos {

    private SignalementDtos() {}

    /** Décision d'un administrateur sur un signalement. */
    public enum Decision { PRENDRE_EN_CHARGE, CLASSER_SANS_SUITE, AVERTIR, BLOQUER, BANNIR }

    public record SignalementRequete(@NotNull(message = "Indiquez la personne à signaler") Long idUtilisateur,
                                     Long idTrajet,
                                     @NotNull(message = "Choisissez un motif") MotifSignalement motif,
                                     @Size(max = 500) String description) {}

    public record DecisionRequete(@NotNull(message = "Choisissez une décision") Decision decision,
                                  @Size(max = 500) String message) {}

    /** Vue du signaleur : il ne voit que l'avancement, jamais le détail de la décision prise. */
    public record SignalementDto(Long id, UtilisateurResume signale, MotifSignalement motif, String description,
                                 StatutSignalement statut, String trajet, LocalDateTime dateSignalement,
                                 LocalDateTime dateTraitement) {
        static SignalementDto de(Signalement s) {
            return new SignalementDto(s.getId(), UtilisateurResume.de(s.getSignale()), s.getMotif(), s.getDescription(),
                    s.getStatut(), libelleTrajet(s.getTrajet()), s.getDateSignalement(), s.getDateTraitement());
        }
    }

    /** Vue du back-office : les deux personnes, le contexte et le nombre de signalements reçus par la personne visée. */
    public record SignalementAdminDto(Long id, UtilisateurLigneDto signaleur, UtilisateurLigneDto signale,
                                      MotifSignalement motif, String description, StatutSignalement statut,
                                      String decisionAdmin, String admin, Long idTrajet, String trajet,
                                      long totalContreSignale, LocalDateTime dateSignalement,
                                      LocalDateTime dateTraitement) {
        static SignalementAdminDto de(Signalement s, long totalContreSignale) {
            return new SignalementAdminDto(s.getId(), UtilisateurLigneDto.de(s.getSignaleur()),
                    UtilisateurLigneDto.de(s.getSignale()), s.getMotif(), s.getDescription(), s.getStatut(),
                    s.getDecisionAdmin(), s.getAdmin() == null ? null : s.getAdmin().nomComplet(),
                    s.getTrajet() == null ? null : s.getTrajet().getId(), libelleTrajet(s.getTrajet()),
                    totalContreSignale, s.getDateSignalement(), s.getDateTraitement());
        }
    }

    private static String libelleTrajet(Trajet t) {
        return t == null ? null : t.getLieuDepart() + " → " + t.getLieuArrivee();
    }
}
