package sn.isep.Convoiturage.trajet;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

/** Arrêt intermédiaire d'un trajet ; peut servir de point de ramassage pour une réservation. */
@Entity
@Table(name = "escale")
@Getter
@Setter
@NoArgsConstructor
public class Escale {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "id_escale")
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "id_trajet", nullable = false)
    private Trajet trajet;

    @Column(nullable = false)
    private Integer ordre;

    @Column(nullable = false, length = 200)
    private String lieu;

    @Column(nullable = false)
    private Double latitude;

    @Column(nullable = false)
    private Double longitude;
}
