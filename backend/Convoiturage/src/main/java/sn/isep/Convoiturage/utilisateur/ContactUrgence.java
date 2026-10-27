package sn.isep.Convoiturage.utilisateur;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.time.LocalDateTime;

/** Proche prévenu en cas d'alerte pendant un trajet (3 au plus par utilisateur). */
@Entity
@Table(name = "contact_urgence")
@Getter
@Setter
@NoArgsConstructor
public class ContactUrgence {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "id_contact_urgence")
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "id_utilisateur", nullable = false)
    private Utilisateur utilisateur;

    @Column(nullable = false, length = 120)
    private String nom;

    /** Format E.164 (+221…). */
    @Column(nullable = false, length = 20)
    private String telephone;

    /** Lien avec l'utilisateur, libre : « Frère », « Mère », « Amie »… */
    @Column(length = 40)
    private String lien;

    @Column(name = "date_creation", nullable = false, updatable = false)
    private LocalDateTime dateCreation = LocalDateTime.now();
}
