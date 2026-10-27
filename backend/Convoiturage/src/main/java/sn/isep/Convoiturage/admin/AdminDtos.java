package sn.isep.Convoiturage.admin;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import sn.isep.Convoiturage.utilisateur.Role;
import sn.isep.Convoiturage.utilisateur.Sexe;
import sn.isep.Convoiturage.utilisateur.StatutCompte;
import sn.isep.Convoiturage.utilisateur.Utilisateur;
import sn.isep.Convoiturage.vehicule.VehiculeDtos.DocumentDto;
import sn.isep.Convoiturage.vehicule.VehiculeDtos.VehiculeDto;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;

import static sn.isep.Convoiturage.utilisateur.UtilisateurDtos.urlPhoto;

public final class AdminDtos {

    private AdminDtos() {}

    public record StatistiquesDto(long utilisateurs, long comptesActifs, long conducteurs, long conducteursValides,
                                  long comptesBloques, long documentsEnAttente) {}

    /** Ligne de la liste des utilisateurs (et en-tête de la fiche). */
    public record UtilisateurLigneDto(Long id, String prenom, String nom, String email, String telephone, Role role,
                                      StatutCompte statut, boolean conducteurValide, String photoProfil,
                                      LocalDateTime dateCreation, LocalDateTime derniereConnexion) {
        public static UtilisateurLigneDto de(Utilisateur u) {
            return new UtilisateurLigneDto(u.getId(), u.getPrenom(), u.getNom(), u.getEmail(), u.getTelephone(), u.getRole(),
                    u.getStatut(), u.isConducteurValide(), urlPhoto(u.getPhotoProfil()), u.getDateCreation(),
                    u.getDerniereConnexion());
        }
    }

    public record ActionDto(TypeActionAdmin type, String detail, String admin, LocalDateTime date) {
        public static ActionDto de(ActionAdmin a) {
            return new ActionDto(a.getType(), a.getDetail(), a.getAdmin().nomComplet(), a.getDate());
        }
    }

    /** Fiche utilisateur du back-office : compte, véhicules, documents et historique des décisions. */
    public record FicheUtilisateurDto(UtilisateurLigneDto utilisateur, boolean telephoneVerifie, boolean emailVerifie,
                                      Sexe sexe, String bio, BigDecimal noteMoyenne, List<VehiculeDto> vehicules,
                                      List<DocumentDto> documents, List<ActionDto> historique) {}

    /** Élément de la file de validation, avec ce qu'il faut pour décider sans changer d'écran. */
    public record DocumentAValiderDto(DocumentDto document, UtilisateurLigneDto titulaire, boolean telephoneVerifie,
                                      boolean emailVerifie, VehiculeDto vehicule, List<DocumentDto> autresDocuments) {}

    public record MotifRequete(@NotBlank(message = "Indiquez le motif") @Size(max = 500) String motif) {}
}
