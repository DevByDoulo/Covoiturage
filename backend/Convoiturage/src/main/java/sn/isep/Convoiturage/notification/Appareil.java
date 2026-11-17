package sn.isep.Convoiturage.notification;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;
import sn.isep.Convoiturage.utilisateur.Utilisateur;

import java.time.LocalDateTime;

/** Appareil (téléphone ou navigateur) d'un utilisateur, identifié par son jeton Firebase Cloud Messaging. */
@Entity
@Table(name = "appareil")
@Getter
@Setter
@NoArgsConstructor
public class Appareil {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "id_appareil")
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "id_utilisateur", nullable = false)
    private Utilisateur utilisateur;

    @Column(nullable = false, unique = true, length = 512)
    private String jeton;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 10)
    private PlateformeAppareil plateforme;

    @Column(name = "date_enregistrement", nullable = false, updatable = false)
    private LocalDateTime dateEnregistrement = LocalDateTime.now();

    /** Dernier enregistrement du jeton par l'application (à chaque connexion ou ouverture). */
    @Column(name = "derniere_utilisation", nullable = false)
    private LocalDateTime derniereUtilisation = LocalDateTime.now();
}
