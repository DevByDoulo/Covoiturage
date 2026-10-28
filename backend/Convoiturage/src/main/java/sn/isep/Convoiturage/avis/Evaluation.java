package sn.isep.Convoiturage.avis;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;
import sn.isep.Convoiturage.reservation.Reservation;
import sn.isep.Convoiturage.trajet.Trajet;
import sn.isep.Convoiturage.utilisateur.Utilisateur;

import java.time.LocalDateTime;

/** Note (1 à 5) et commentaire laissés après un trajet, du passager au conducteur ou l'inverse. */
@Entity
@Table(name = "evaluation")
@Getter
@Setter
@NoArgsConstructor
public class Evaluation {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "id_evaluation")
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "id_reservation", nullable = false)
    private Reservation reservation;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "id_trajet", nullable = false)
    private Trajet trajet;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "id_evaluateur", nullable = false)
    private Utilisateur evaluateur;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "id_evalue", nullable = false)
    private Utilisateur evalue;

    @Column(nullable = false)
    private Short note;

    @Column(length = 500)
    private String commentaire;

    @Column(name = "date_evaluation", nullable = false)
    private LocalDateTime dateEvaluation = LocalDateTime.now();

    /** Vrai si l'auteur était le conducteur du trajet (il notait donc un passager). */
    public boolean parConducteur() {
        return trajet.getConducteur().getId().equals(evaluateur.getId());
    }
}
