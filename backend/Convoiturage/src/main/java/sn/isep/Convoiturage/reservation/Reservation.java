package sn.isep.Convoiturage.reservation;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;
import sn.isep.Convoiturage.trajet.Escale;
import sn.isep.Convoiturage.trajet.Trajet;
import sn.isep.Convoiturage.utilisateur.Utilisateur;

import java.math.BigDecimal;
import java.time.LocalDateTime;

@Entity
@Table(name = "reservation")
@Getter
@Setter
@NoArgsConstructor
public class Reservation {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "id_reservation")
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "id_passager", nullable = false)
    private Utilisateur passager;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "id_trajet", nullable = false)
    private Trajet trajet;

    /** Escale choisie comme point de ramassage (sinon : départ du trajet). */
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "id_escale_ramassage")
    private Escale escaleRamassage;

    @Column(name = "nombre_places", nullable = false)
    private Integer nombrePlaces;

    /** Prix par place figé au moment de la demande. */
    @Column(name = "prix_unitaire", nullable = false, precision = 10, scale = 2)
    private BigDecimal prixUnitaire;

    @Column(name = "montant_total", nullable = false, precision = 10, scale = 2)
    private BigDecimal montantTotal;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    private StatutReservation statut = StatutReservation.EN_ATTENTE;

    @Column(name = "motif_annulation", length = 500)
    private String motifAnnulation;

    @Column(name = "date_demande", nullable = false)
    private LocalDateTime dateDemande = LocalDateTime.now();

    @Column(name = "date_reponse")
    private LocalDateTime dateReponse;

    @Column(name = "date_annulation")
    private LocalDateTime dateAnnulation;

    public boolean estActive() {
        return statut == StatutReservation.EN_ATTENTE || statut == StatutReservation.ACCEPTEE;
    }
}
