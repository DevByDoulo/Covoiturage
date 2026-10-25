package sn.isep.Convoiturage.reservation;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.math.BigDecimal;
import java.time.LocalDateTime;

/**
 * Règlement d'une réservation. Lot 1 : espèces uniquement (encaissé à l'embarquement, confirmé par PIN/QR).
 * Wave / Orange Money (via PayDunya ou CinetPay) réutiliseront cette table : reference_externe, numero_telephone.
 */
@Entity
@Table(name = "paiement")
@Getter
@Setter
@NoArgsConstructor
public class Paiement {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "id_paiement")
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "id_reservation", nullable = false)
    private Reservation reservation;

    @Column(nullable = false, precision = 10, scale = 2)
    private BigDecimal montant;

    @Enumerated(EnumType.STRING)
    @Column(name = "moyen_paiement", nullable = false, length = 20)
    private MoyenPaiement moyenPaiement;

    @Column(length = 30)
    private String fournisseur;

    @Column(name = "reference_transaction", nullable = false, unique = true, length = 40)
    private String referenceTransaction;

    @Column(name = "reference_externe", length = 100)
    private String referenceExterne;

    @Column(name = "numero_telephone", length = 20)
    private String numeroTelephone;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 30)
    private StatutPaiement statut = StatutPaiement.EN_ATTENTE;

    @Column(name = "date_initiation", nullable = false)
    private LocalDateTime dateInitiation = LocalDateTime.now();

    @Column(name = "date_confirmation")
    private LocalDateTime dateConfirmation;

    @Column(name = "date_remboursement")
    private LocalDateTime dateRemboursement;
}
