package sn.isep.Convoiturage.vehicule;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;
import sn.isep.Convoiturage.utilisateur.Utilisateur;

import java.math.BigDecimal;
import java.time.LocalDateTime;

@Entity
@Table(name = "vehicule")
@Getter
@Setter
@NoArgsConstructor
public class Vehicule {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "id_vehicule")
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "id_proprietaire", nullable = false)
    private Utilisateur proprietaire;

    @Column(nullable = false, unique = true, length = 20)
    private String immatriculation;

    @Column(nullable = false, length = 60)
    private String marque;

    @Column(nullable = false, length = 60)
    private String modele;

    @Column(nullable = false)
    private Integer annee;

    @Column(name = "puissance_fiscale", nullable = false)
    private Integer puissanceFiscale;

    /** Places totales du véhicule, conducteur compris (carte grise). */
    @Column(name = "nombre_places", nullable = false)
    private Integer nombrePlaces;

    @Enumerated(EnumType.STRING)
    @Column(name = "type_energie", nullable = false, length = 20)
    private TypeEnergie typeEnergie;

    /** L/100 km (kWh/100 km pour l'électrique), donnée constructeur. */
    @Column(name = "consommation_theorique", precision = 5, scale = 2)
    private BigDecimal consommationTheorique;

    /** L/100 km constatée par le conducteur ; prioritaire sur la valeur théorique. */
    @Column(name = "consommation_reelle", precision = 5, scale = 2)
    private BigDecimal consommationReelle;

    /** FCFA/km : usure, entretien, pneus, assurance rapportés au km. */
    @Column(name = "amortissement_par_km", precision = 8, scale = 2)
    private BigDecimal amortissementParKm;

    /** Nom du fichier photo (dossier des photos, servi par /api/fichiers/photos/{nom}). */
    @Column
    private String photo;

    @Enumerated(EnumType.STRING)
    @Column(name = "statut_validation", nullable = false, length = 20)
    private StatutValidation statutValidation = StatutValidation.EN_ATTENTE;

    @Column(nullable = false)
    private boolean actif = true;

    @Column(name = "date_creation", nullable = false, updatable = false)
    private LocalDateTime dateCreation = LocalDateTime.now();

    public boolean estUtilisable() {
        return actif && statutValidation == StatutValidation.VALIDE;
    }
}
