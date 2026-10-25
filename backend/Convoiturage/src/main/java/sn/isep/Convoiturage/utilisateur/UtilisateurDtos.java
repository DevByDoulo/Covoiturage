package sn.isep.Convoiturage.utilisateur;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

import java.math.BigDecimal;
import java.time.LocalDateTime;

public final class UtilisateurDtos {

    private UtilisateurDtos() {}

    public static String urlPhoto(String nomFichier) {
        return nomFichier == null ? null : "/api/fichiers/photos/" + nomFichier;
    }

    public record PreferenceDto(boolean fumeurAccepte, boolean musiqueAcceptee,
                                boolean animauxAcceptes, boolean discussionAcceptee) {
        public static PreferenceDto de(Preference p) {
            if (p == null) return new PreferenceDto(false, true, false, true);
            return new PreferenceDto(p.isFumeurAccepte(), p.isMusiqueAcceptee(), p.isAnimauxAcceptes(), p.isDiscussionAcceptee());
        }
    }

    /** Profil complet, visible uniquement par son propriétaire (et l'administrateur). */
    public record ProfilDto(Long id, String prenom, String nom, String email, String telephone, boolean telephoneVerifie,
                            Sexe sexe, String photoProfil, String bio, Role role, StatutCompte statut,
                            boolean conducteurValide, BigDecimal noteMoyenne, PreferenceDto preferences,
                            LocalDateTime dateCreation) {
        public static ProfilDto de(Utilisateur u) {
            return new ProfilDto(u.getId(), u.getPrenom(), u.getNom(), u.getEmail(), u.getTelephone(), u.isTelephoneVerifie(),
                    u.getSexe(), urlPhoto(u.getPhotoProfil()), u.getBio(), u.getRole(), u.getStatut(),
                    u.isConducteurValide(), u.getNoteMoyenne(), PreferenceDto.de(u.getPreference()), u.getDateCreation());
        }
    }

    /** Profil public : ni email ni téléphone. */
    public record ProfilPublicDto(Long id, String prenom, String nomInitiale, String photoProfil, String bio,
                                  BigDecimal noteMoyenne, boolean conducteurValide, PreferenceDto preferences,
                                  LocalDateTime membreDepuis) {
        public static ProfilPublicDto de(Utilisateur u) {
            return new ProfilPublicDto(u.getId(), u.getPrenom(), u.getNom().substring(0, 1) + ".", urlPhoto(u.getPhotoProfil()),
                    u.getBio(), u.getNoteMoyenne(), u.isConducteurValide(), PreferenceDto.de(u.getPreference()), u.getDateCreation());
        }
    }

    /** Résumé affiché dans les listes (résultats de recherche, réservations). */
    public record UtilisateurResume(Long id, String prenom, String nomInitiale, String photoProfil, BigDecimal noteMoyenne) {
        public static UtilisateurResume de(Utilisateur u) {
            return new UtilisateurResume(u.getId(), u.getPrenom(), u.getNom().substring(0, 1) + ".",
                    urlPhoto(u.getPhotoProfil()), u.getNoteMoyenne());
        }
    }

    public record ModificationProfilRequete(
            @NotBlank @Size(max = 80) String prenom,
            @NotBlank @Size(max = 80) String nom,
            @Size(max = 500) String bio,
            Sexe sexe) {}

    public record FcmTokenRequete(@NotNull @Size(max = 255) String token) {}
}
