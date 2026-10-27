package sn.isep.Convoiturage.trajet;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;
import org.locationtech.jts.geom.LineString;
import sn.isep.Convoiturage.tarification.Tarification;
import sn.isep.Convoiturage.utilisateur.Utilisateur;
import sn.isep.Convoiturage.vehicule.Vehicule;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;

@Entity
@Table(name = "trajet")
@Getter
@Setter
@NoArgsConstructor
public class Trajet {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "id_trajet")
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "id_conducteur", nullable = false)
    private Utilisateur conducteur;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "id_vehicule", nullable = false)
    private Vehicule vehicule;

    @Column(name = "lieu_depart", nullable = false, length = 200)
    private String lieuDepart;

    @Column(name = "latitude_depart", nullable = false)
    private Double latitudeDepart;

    @Column(name = "longitude_depart", nullable = false)
    private Double longitudeDepart;

    @Column(name = "lieu_arrivee", nullable = false, length = 200)
    private String lieuArrivee;

    @Column(name = "latitude_arrivee", nullable = false)
    private Double latitudeArrivee;

    @Column(name = "longitude_arrivee", nullable = false)
    private Double longitudeArrivee;

    @Column(name = "date_heure_depart", nullable = false)
    private LocalDateTime dateHeureDepart;

    /** Marge de ponctualité annoncée par le conducteur (15 à 30 min). */
    @Column(name = "flexibilite_minutes", nullable = false)
    private Integer flexibiliteMinutes;

    @Column(name = "nombre_places_total", nullable = false)
    private Integer nombrePlacesTotal;

    @Column(name = "nombre_places_disponibles", nullable = false)
    private Integer nombrePlacesDisponibles;

    @Enumerated(EnumType.STRING)
    @Column(name = "mode_reservation", nullable = false, length = 20)
    private ModeReservation modeReservation;

    @Enumerated(EnumType.STRING)
    @Column(name = "taille_bagage", nullable = false, length = 10)
    private TailleBagage tailleBagage;

    @Column(name = "femmes_uniquement", nullable = false)
    private boolean femmesUniquement;

    @Column(name = "distance_km", nullable = false, precision = 8, scale = 2)
    private BigDecimal distanceKm;

    @Column(name = "denivele_m", nullable = false)
    private Integer deniveleM = 0;

    @Enumerated(EnumType.STRING)
    @Column(name = "type_route", nullable = false, length = 20)
    private TypeRoute typeRoute;

    @Column(name = "montant_peages", nullable = false, precision = 10, scale = 2)
    private BigDecimal montantPeages = BigDecimal.ZERO;

    @Column(name = "duree_estimee_min", nullable = false)
    private Integer dureeEstimeeMin;

    /** Tracé complet (départ -> escales -> arrivée), SRID 4326. Sert à la recherche par proximité. */
    @Column(nullable = false, columnDefinition = "geometry(LineString,4326)")
    private LineString itineraire;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    private StatutTrajet statut = StatutTrajet.PUBLIE;

    @Column(name = "motif_annulation", length = 500)
    private String motifAnnulation;

    @Column(name = "date_creation", nullable = false, updatable = false)
    private LocalDateTime dateCreation;

    @Column(name = "date_modification", nullable = false)
    private LocalDateTime dateModification;

    @OneToMany(mappedBy = "trajet", cascade = CascadeType.ALL, orphanRemoval = true)
    @OrderBy("ordre ASC")
    private List<Escale> escales = new ArrayList<>();

    @OneToOne(mappedBy = "trajet", cascade = CascadeType.ALL, orphanRemoval = true)
    private Tarification tarification;

    @PrePersist
    void avantCreation() {
        dateCreation = dateModification = LocalDateTime.now();
    }

    @PreUpdate
    void avantModification() {
        dateModification = LocalDateTime.now();
    }

    public boolean estOuvertALaReservation() {
        return statut == StatutTrajet.PUBLIE && dateHeureDepart.isAfter(LocalDateTime.now());
    }

    public boolean estModifiable() {
        return (statut == StatutTrajet.PUBLIE || statut == StatutTrajet.COMPLET) && dateHeureDepart.isAfter(LocalDateTime.now());
    }

    /** Réserve (n > 0) ou libère (n < 0) des places et met à jour le statut PUBLIE/COMPLET. */
    public void reserverPlaces(int n) {
        int restantes = nombrePlacesDisponibles - n;
        if (restantes < 0 || restantes > nombrePlacesTotal) throw new IllegalStateException("Nombre de places incohérent");
        nombrePlacesDisponibles = restantes;
        if (statut == StatutTrajet.PUBLIE && restantes == 0) statut = StatutTrajet.COMPLET;
        else if (statut == StatutTrajet.COMPLET && restantes > 0) statut = StatutTrajet.PUBLIE;
    }

    public void ajouterEscale(Escale e) {
        e.setTrajet(this);
        escales.add(e);
    }
}
