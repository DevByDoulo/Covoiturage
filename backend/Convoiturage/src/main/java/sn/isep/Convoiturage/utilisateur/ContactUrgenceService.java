package sn.isep.Convoiturage.utilisateur;

import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import sn.isep.Convoiturage.common.ApiException;
import sn.isep.Convoiturage.common.Telephones;
import sn.isep.Convoiturage.utilisateur.UtilisateurDtos.ContactUrgenceDto;
import sn.isep.Convoiturage.utilisateur.UtilisateurDtos.ContactUrgenceRequete;

import java.util.List;

@Service
@RequiredArgsConstructor
public class ContactUrgenceService {

    static final int MAX_CONTACTS = 3;

    private final ContactUrgenceRepository contacts;
    private final UtilisateurRepository utilisateurs;

    @Transactional(readOnly = true)
    public List<ContactUrgenceDto> mesContacts(Long utilisateurId) {
        return contacts.findByUtilisateurIdOrderByDateCreationAsc(utilisateurId).stream().map(ContactUrgenceDto::de).toList();
    }

    @Transactional
    public ContactUrgenceDto ajouter(Long utilisateurId, ContactUrgenceRequete req) {
        Utilisateur u = utilisateurs.findById(utilisateurId).orElseThrow(() -> ApiException.notFound("Utilisateur introuvable"));
        if (contacts.countByUtilisateurId(utilisateurId) >= MAX_CONTACTS) {
            throw ApiException.conflict("Vous avez déjà " + MAX_CONTACTS + " contacts d'urgence. Supprimez-en un pour en ajouter un autre.");
        }
        String telephone;
        try {
            telephone = Telephones.normaliser(req.telephone());
        } catch (ApiException e) {
            throw e.surChamp("telephone");
        }
        if (telephone.equals(u.getTelephone())) {
            throw ApiException.badRequest("Indiquez le numéro d'un proche, pas le vôtre").surChamp("telephone");
        }
        if (contacts.existsByUtilisateurIdAndTelephone(utilisateurId, telephone)) {
            throw ApiException.conflict("Ce numéro fait déjà partie de vos contacts d'urgence").surChamp("telephone");
        }
        ContactUrgence c = new ContactUrgence();
        c.setUtilisateur(u);
        c.setNom(req.nom().trim());
        c.setTelephone(telephone);
        c.setLien(req.lien() == null || req.lien().isBlank() ? null : req.lien().trim());
        return ContactUrgenceDto.de(contacts.save(c));
    }

    @Transactional
    public void supprimer(Long utilisateurId, Long contactId) {
        contacts.delete(contacts.findByIdAndUtilisateurId(contactId, utilisateurId)
                .orElseThrow(() -> ApiException.notFound("Contact introuvable")));
    }
}
