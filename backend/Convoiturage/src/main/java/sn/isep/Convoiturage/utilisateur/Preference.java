package sn.isep.Convoiturage.utilisateur;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Entity
@Table(name = "preference")
@Getter
@Setter
@NoArgsConstructor
public class Preference {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "id_preference")
    private Long id;

    @OneToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "id_utilisateur", nullable = false, unique = true)
    private Utilisateur utilisateur;

    @Column(name = "fumeur_accepte", nullable = false)
    private boolean fumeurAccepte;

    @Column(name = "musique_acceptee", nullable = false)
    private boolean musiqueAcceptee = true;

    @Column(name = "animaux_acceptes", nullable = false)
    private boolean animauxAcceptes;

    @Column(name = "discussion_acceptee", nullable = false)
    private boolean discussionAcceptee = true;
}
