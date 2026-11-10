package sn.isep.Convoiturage.signalement;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;
import sn.isep.Convoiturage.trajet.Trajet;
import sn.isep.Convoiturage.utilisateur.Utilisateur;

import java.time.LocalDateTime;

/** Signalement d'une personne rencontrée lors d'un trajet, traité ensuite par un administrateur. */
@Entity
@Table(name = "signalement")
@Getter
@Setter
@NoArgsConstructor
public class Signalement {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "id_signalement")
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "id_signaleur", nullable = false)
    private Utilisateur signaleur;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "id_signale", nullable = false)
    private Utilisateur signale;

    /** Trajet concerné (facultatif ; vidé si le trajet est supprimé). */
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "id_trajet")
    private Trajet trajet;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 30)
    private MotifSignalement motif;

    @Column(length = 500)
    private String description;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    private StatutSignalement statut = StatutSignalement.EN_ATTENTE;

    @Column(name = "decision_admin", length = 500)
    private String decisionAdmin;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "id_admin")
    private Utilisateur admin;

    @Column(name = "date_signalement", nullable = false)
    private LocalDateTime dateSignalement = LocalDateTime.now();

    @Column(name = "date_traitement")
    private LocalDateTime dateTraitement;
}
