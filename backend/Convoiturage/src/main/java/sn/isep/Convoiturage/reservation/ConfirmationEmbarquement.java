package sn.isep.Convoiturage.reservation;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.time.LocalDateTime;

/** Code PIN (6 chiffres) et jeton QR remis au passager, saisis/scannés par le conducteur à l'embarquement. */
@Entity
@Table(name = "confirmation_embarquement")
@Getter
@Setter
@NoArgsConstructor
public class ConfirmationEmbarquement {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "id_confirmation")
    private Long id;

    @OneToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "id_reservation", nullable = false, unique = true)
    private Reservation reservation;

    @Column(name = "code_pin", nullable = false, length = 6)
    private String codePin;

    @Column(name = "qr_token", nullable = false, unique = true, length = 64)
    private String qrToken;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    private StatutConfirmation statut = StatutConfirmation.EN_ATTENTE;

    @Column(name = "date_expiration", nullable = false)
    private LocalDateTime dateExpiration;

    @Column(name = "date_confirmation")
    private LocalDateTime dateConfirmation;
}
