package sn.isep.Convoiturage.recherche;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;
import sn.isep.Convoiturage.utilisateur.Utilisateur;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;

/** Recherche sauvegardée : le passager est prévenu quand un trajet correspondant est publié. */
@Entity
@Table(name = "alerte_recherche")
@Getter
@Setter
@NoArgsConstructor
public class AlerteRecherche {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "id_alerte")
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "id_utilisateur", nullable = false)
    private Utilisateur utilisateur;

    @Column(name = "ville_depart", nullable = false, length = 200)
    private String villeDepart;

    @Column(name = "latitude_depart", nullable = false)
    private Double latitudeDepart;

    @Column(name = "longitude_depart", nullable = false)
    private Double longitudeDepart;

    @Column(name = "ville_arrivee", nullable = false, length = 200)
    private String villeArrivee;

    @Column(name = "latitude_arrivee", nullable = false)
    private Double latitudeArrivee;

    @Column(name = "longitude_arrivee", nullable = false)
    private Double longitudeArrivee;

    @Column(name = "rayon_km", nullable = false, precision = 5, scale = 2)
    private BigDecimal rayonKm = BigDecimal.valueOf(5);

    @Column(name = "date_depart", nullable = false)
    private LocalDate dateDepart;

    @Column(name = "prix_max", precision = 10, scale = 2)
    private BigDecimal prixMax;

    @Column(nullable = false)
    private boolean actif = true;

    @Column(name = "date_creation", nullable = false, updatable = false)
    private LocalDateTime dateCreation = LocalDateTime.now();
}
