package sn.isep.Convoiturage.admin;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;
import sn.isep.Convoiturage.utilisateur.Utilisateur;

import java.time.LocalDateTime;

/** Ligne du journal des décisions d'administration (qui, sur quel compte, quoi, pourquoi, quand). */
@Entity
@Table(name = "action_admin")
@Getter
@Setter
@NoArgsConstructor
public class ActionAdmin {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "id_action_admin")
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "id_admin", nullable = false)
    private Utilisateur admin;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "id_utilisateur", nullable = false)
    private Utilisateur utilisateur;

    @Enumerated(EnumType.STRING)
    @Column(name = "type_action", nullable = false, length = 30)
    private TypeActionAdmin type;

    /** Pièce concernée, motif du refus ou du blocage. */
    @Column(length = 500)
    private String detail;

    @Column(name = "date_action", nullable = false)
    private LocalDateTime date = LocalDateTime.now();
}
