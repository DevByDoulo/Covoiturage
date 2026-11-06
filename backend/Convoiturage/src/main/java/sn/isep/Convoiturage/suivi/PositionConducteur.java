package sn.isep.Convoiturage.suivi;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.time.LocalDateTime;

/** Dernière position partagée par le conducteur d'un trajet (une ligne par trajet). */
@Entity
@Table(name = "position_conducteur")
@Getter
@Setter
@NoArgsConstructor
public class PositionConducteur {

    @Id
    @Column(name = "id_trajet")
    private Long idTrajet;

    @Column(nullable = false)
    private double latitude;

    @Column(nullable = false)
    private double longitude;

    @Column(name = "precision_m")
    private Integer precisionM;

    /** Direction en degrés (0 = nord), si l'appareil la donne. */
    private Double cap;

    /** Vitesse en m/s, si l'appareil la donne. */
    private Double vitesse;

    /** Début du partage (sert à ne notifier les passagers qu'une fois). */
    @Column(name = "date_debut", nullable = false)
    private LocalDateTime dateDebut;

    @Column(name = "date_maj", nullable = false)
    private LocalDateTime dateMaj;

    public PositionConducteur(Long idTrajet) {
        this.idTrajet = idTrajet;
    }
}
