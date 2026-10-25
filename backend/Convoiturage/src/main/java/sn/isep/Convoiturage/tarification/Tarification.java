package sn.isep.Convoiturage.tarification;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;
import sn.isep.Convoiturage.common.ApiException;
import sn.isep.Convoiturage.trajet.Trajet;

import java.math.BigDecimal;
import java.time.LocalDateTime;

/** Prix proposé par le moteur pour un trajet, et prix final retenu par le conducteur dans la fourchette. */
@Entity
@Table(name = "tarification")
@Getter
@Setter
@NoArgsConstructor
public class Tarification {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "id_tarification")
    private Long id;

    @OneToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "id_trajet", nullable = false, unique = true)
    private Trajet trajet;

    @Column(name = "prix_ia", nullable = false, precision = 10, scale = 2)
    private BigDecimal prixIa;

    @Column(name = "prix_min", nullable = false, precision = 10, scale = 2)
    private BigDecimal prixMin;

    @Column(name = "prix_max", nullable = false, precision = 10, scale = 2)
    private BigDecimal prixMax;

    @Column(name = "prix_final", nullable = false, precision = 10, scale = 2)
    private BigDecimal prixFinal;

    @Column(name = "prix_carburant_utilise", nullable = false, precision = 10, scale = 2)
    private BigDecimal prixCarburantUtilise;

    @Column(length = 40)
    private String meteo;

    @Column(name = "heure_de_pointe", nullable = false)
    private boolean heureDePointe;

    @Column(name = "version_modele", nullable = false, length = 40)
    private String versionModele;

    @Column(name = "date_prediction", nullable = false)
    private LocalDateTime datePrediction = LocalDateTime.now();

    /** Le conducteur ajuste le prix dans la fourchette [prixMin ; prixMax] (+/- 10 % par défaut). */
    public void ajusterPrix(BigDecimal prix) {
        if (prix.compareTo(prixMin) < 0 || prix.compareTo(prixMax) > 0) {
            throw ApiException.badRequest(
                    "Le prix doit être compris entre " + prixMin.toBigInteger() + " et " + prixMax.toBigInteger() + " FCFA");
        }
        this.prixFinal = prix;
    }
}
