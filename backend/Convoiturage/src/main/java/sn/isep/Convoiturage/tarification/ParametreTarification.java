package sn.isep.Convoiturage.tarification;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;
import sn.isep.Convoiturage.utilisateur.Utilisateur;

import java.math.BigDecimal;
import java.time.LocalDateTime;

/** Coefficient du moteur de prix, modifiable depuis le back-office sans redéploiement. */
@Entity
@Table(name = "parametre_tarification")
@Getter
@Setter
@NoArgsConstructor
public class ParametreTarification {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "id_parametre")
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "id_admin")
    private Utilisateur admin;

    @Column(nullable = false, unique = true, length = 60)
    private String cle;

    @Column(nullable = false, precision = 12, scale = 4)
    private BigDecimal valeur;

    @Column(length = 30)
    private String unite;

    private String description;

    @Column(nullable = false)
    private boolean actif = true;

    @Column(name = "date_modification", nullable = false)
    private LocalDateTime dateModification = LocalDateTime.now();
}
