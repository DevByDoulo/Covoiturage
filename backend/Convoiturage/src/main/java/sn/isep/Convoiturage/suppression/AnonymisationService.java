package sn.isep.Convoiturage.suppression;

import jakarta.persistence.EntityManager;
import jakarta.persistence.PersistenceContext;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.transaction.support.TransactionSynchronization;
import org.springframework.transaction.support.TransactionSynchronizationManager;
import sn.isep.Convoiturage.auth.AlertesSecurite;
import sn.isep.Convoiturage.common.stockage.StockageService;
import sn.isep.Convoiturage.common.stockage.StockageService.Dossier;
import sn.isep.Convoiturage.utilisateur.StatutCompte;
import sn.isep.Convoiturage.utilisateur.Utilisateur;
import sn.isep.Convoiturage.utilisateur.UtilisateurRepository;

import java.util.ArrayList;
import java.util.List;

/**
 * Efface les données personnelles d'un compte dont le délai de grâce est écoulé.
 *
 * <p><b>Effacé</b> : identité (prénom, nom, email, téléphone, identifiant Google, mot de passe, sexe, présentation, photo),
 * documents (permis, carte grise, pièce d'identité) et photos de véhicules avec leurs fichiers, contacts d'urgence,
 * préférences, alertes de recherche, jetons d'appareil (push), notifications, sessions, codes de vérification,
 * position partagée, numéros de téléphone de paiement, texte des messages envoyés.
 *
 * <p><b>Conservé</b> (obligation légale ou intégrité des données, sans lien avec l'identité) : paiements et réservations,
 * trajets, véhicules (désactivés, immatriculation effacée), avis (note et commentaire, auteur « Utilisateur S. »),
 * signalements et journal d'administration.
 */
@Service
@RequiredArgsConstructor
public class AnonymisationService {

    static final String PRENOM_ANONYME = "Utilisateur";
    static final String NOM_ANONYME = "Supprimé";
    static final String MESSAGE_SUPPRIME = "[message supprimé]";

    private final UtilisateurRepository utilisateurs;
    private final StockageService stockage;
    private final AlertesSecurite alertes;

    @PersistenceContext
    private EntityManager em;

    /** @return vrai si le compte a été anonymisé (faux s'il n'était plus en attente de suppression). */
    @Transactional
    public boolean anonymiser(Long id) {
        Utilisateur u = utilisateurs.findById(id).filter(x -> x.getStatut() == StatutCompte.SUPPRESSION_DEMANDEE).orElse(null);
        if (u == null) return false;
        String prenom = u.getPrenom();
        String email = u.getEmail();
        String telephone = u.getTelephone();

        List<String> photos = new ArrayList<>(colonne("select photo from vehicule where id_proprietaire = :id and photo is not null", id));
        if (u.getPhotoProfil() != null) photos.add(u.getPhotoProfil());
        List<String> documents = colonne("select fichier from document where id_utilisateur = :id", id);

        executer("delete from document where id_utilisateur = :id", id);
        executer("update vehicule set actif = false, photo = null, immatriculation = concat('SUPPR-', id_vehicule) "
                + "where id_proprietaire = :id", id);
        executer("delete from contact_urgence where id_utilisateur = :id", id);
        executer("delete from preference where id_utilisateur = :id", id);
        executer("delete from alerte_recherche where id_utilisateur = :id", id);
        executer("delete from appareil where id_utilisateur = :id", id);
        executer("delete from notification where id_utilisateur = :id", id);
        executer("delete from refresh_token where id_utilisateur = :id", id);
        executer("delete from position_conducteur where id_trajet in (select id_trajet from trajet where id_conducteur = :id)", id);
        executer("update paiement set numero_telephone = null where id_reservation in "
                + "(select id_reservation from reservation where id_passager = :id)", id);
        em.createNativeQuery("update message set contenu = :texte where id_expediteur = :id")
                .setParameter("texte", MESSAGE_SUPPRIME).setParameter("id", id).executeUpdate();
        if (telephone != null) {
            em.createNativeQuery("delete from otp_code where telephone = :tel").setParameter("tel", telephone).executeUpdate();
        }
        em.createNativeQuery("""
                update utilisateur set prenom = :prenom, nom = :nom, email = null, telephone = null,
                    telephone_verifie = false, email_verifie = false, mot_de_passe = null, google_id = null,
                    sexe = null, photo_profil = null, bio = null, note_moyenne = null, conducteur_valide = false,
                    derniere_connexion = null, push_active = false, statut = 'SUPPRIME', date_anonymisation = now()
                where id_utilisateur = :id
                """)
                .setParameter("prenom", PRENOM_ANONYME).setParameter("nom", NOM_ANONYME).setParameter("id", id)
                .executeUpdate();
        em.clear();

        alertes.compteSupprime(prenom, email, telephone);
        supprimerFichiersApresValidation(photos, documents);
        return true;
    }

    /** Les fichiers ne sont effacés qu'une fois la base validée : un échec de la transaction ne doit rien perdre. */
    private void supprimerFichiersApresValidation(List<String> photos, List<String> documents) {
        Runnable suppression = () -> {
            photos.forEach(nom -> stockage.supprimer(nom, Dossier.PHOTOS));
            documents.forEach(nom -> stockage.supprimer(nom, Dossier.DOCUMENTS));
        };
        if (TransactionSynchronizationManager.isSynchronizationActive()) {
            TransactionSynchronizationManager.registerSynchronization(new TransactionSynchronization() {
                @Override
                public void afterCommit() {
                    suppression.run();
                }
            });
        } else {
            suppression.run();
        }
    }

    @SuppressWarnings("unchecked")
    private List<String> colonne(String sql, Long id) {
        return em.createNativeQuery(sql).setParameter("id", id).getResultList();
    }

    private void executer(String sql, Long id) {
        em.createNativeQuery(sql).setParameter("id", id).executeUpdate();
    }
}
