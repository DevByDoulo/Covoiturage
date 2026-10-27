package sn.isep.Convoiturage.vehicule;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;
import sn.isep.Convoiturage.utilisateur.Utilisateur;

import java.time.LocalDateTime;

/** Pièce justificative (permis, carte grise) soumise par un conducteur et validée par un administrateur. */
@Entity
@Table(name = "document")
@Getter
@Setter
@NoArgsConstructor
public class Document {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "id_document")
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "id_utilisateur", nullable = false)
    private Utilisateur utilisateur;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "id_vehicule")
    private Vehicule vehicule;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "id_admin_validateur")
    private Utilisateur adminValidateur;

    @Enumerated(EnumType.STRING)
    @Column(name = "type_document", nullable = false, length = 30)
    private TypeDocument typeDocument;

    /** Nom du fichier sur le stockage (généré, jamais celui du client). */
    @Column(nullable = false)
    private String fichier;

    @Column(name = "nom_original")
    private String nomOriginal;

    @Column(name = "type_mime", nullable = false, length = 100)
    private String typeMime;

    @Enumerated(EnumType.STRING)
    @Column(name = "statut_validation", nullable = false, length = 20)
    private StatutValidation statutValidation = StatutValidation.EN_ATTENTE;

    @Column(name = "commentaire_admin", length = 500)
    private String commentaireAdmin;

    @Column(name = "date_soumission", nullable = false)
    private LocalDateTime dateSoumission = LocalDateTime.now();

    @Column(name = "date_validation")
    private LocalDateTime dateValidation;
}
