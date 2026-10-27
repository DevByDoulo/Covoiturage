package sn.isep.Convoiturage.utilisateur;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;

@Entity
@Table(name = "utilisateur")
@Getter
@Setter
@NoArgsConstructor
public class Utilisateur {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "id_utilisateur")
    private Long id;

    @Column(nullable = false, length = 80)
    private String prenom;

    @Column(nullable = false, length = 80)
    private String nom;

    @Column(unique = true, length = 160)
    private String email;

    @Column(unique = true, length = 20)
    private String telephone;

    /** Vrai après saisie d'un code reçu par SMS sur ce numéro. */
    @Column(name = "telephone_verifie", nullable = false)
    private boolean telephoneVerifie;

    /** Vrai après saisie d'un code reçu par email à cette adresse. */
    @Column(name = "email_verifie", nullable = false)
    private boolean emailVerifie;

    /** Hash BCrypt ; null pour un compte créé uniquement via Google. */
    @Column(name = "mot_de_passe", length = 100)
    private String motDePasse;

    @Column(name = "google_id", unique = true, length = 64)
    private String googleId;

    @Enumerated(EnumType.STRING)
    @Column(length = 10)
    private Sexe sexe;

    @Column(name = "photo_profil")
    private String photoProfil;

    @Column(length = 500)
    private String bio;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    private Role role = Role.PASSAGER;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    private StatutCompte statut = StatutCompte.EN_ATTENTE_OTP;

    /** Vrai lorsque le permis et au moins une carte grise ont été validés par un administrateur. */
    @Column(name = "conducteur_valide", nullable = false)
    private boolean conducteurValide;

    @Column(name = "note_moyenne", precision = 3, scale = 2)
    private BigDecimal noteMoyenne;

    @Column(name = "fcm_token")
    private String fcmToken;

    @Column(name = "date_creation", nullable = false, updatable = false)
    private LocalDateTime dateCreation;

    @OneToOne(mappedBy = "utilisateur", cascade = CascadeType.ALL, orphanRemoval = true)
    private Preference preference;

    @PrePersist
    void avantCreation() {
        if (dateCreation == null) dateCreation = LocalDateTime.now();
        if (preference == null) {
            preference = new Preference();
            preference.setUtilisateur(this);
        }
    }

    public String nomComplet() {
        return prenom + " " + nom;
    }

    /** Le compte a prouvé au moins un moyen de contact (code reçu par SMS ou par email). */
    public boolean estVerifie() {
        return telephoneVerifie || emailVerifie;
    }

    public boolean estActif() {
        return statut == StatutCompte.ACTIF;
    }

    /** Rôles placés dans le JWT. Un conducteur est aussi passager. */
    public List<String> autorites() {
        return switch (role) {
            case ADMIN -> List.of(Role.ADMIN.name());
            case CONDUCTEUR -> List.of(Role.PASSAGER.name(), Role.CONDUCTEUR.name());
            case PASSAGER -> List.of(Role.PASSAGER.name());
        };
    }
}
