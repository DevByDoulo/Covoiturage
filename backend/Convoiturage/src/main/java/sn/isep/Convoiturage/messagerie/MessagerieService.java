package sn.isep.Convoiturage.messagerie;

import lombok.RequiredArgsConstructor;
import org.springframework.context.ApplicationEventPublisher;
import org.springframework.data.domain.PageRequest;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import sn.isep.Convoiturage.common.ApiException;
import sn.isep.Convoiturage.messagerie.MessagerieDtos.*;
import sn.isep.Convoiturage.messagerie.MessagerieEvenements.MessageEnvoye;
import sn.isep.Convoiturage.reservation.ReservationRepository;
import sn.isep.Convoiturage.reservation.StatutReservation;
import sn.isep.Convoiturage.trajet.StatutTrajet;
import sn.isep.Convoiturage.trajet.Trajet;
import sn.isep.Convoiturage.trajet.TrajetRepository;
import sn.isep.Convoiturage.utilisateur.Utilisateur;
import sn.isep.Convoiturage.utilisateur.UtilisateurDtos.UtilisateurResume;
import sn.isep.Convoiturage.utilisateur.UtilisateurRepository;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.EnumSet;
import java.util.List;

/**
 * 09 — Messagerie entre le conducteur d'un trajet et un passager. Un passager peut écrire au conducteur d'un trajet
 * à venir (pour poser une question avant de réserver) ou d'un trajet qu'il a réservé ; le conducteur écrit aux
 * passagers qui ont réservé. On peut écrire jusqu'à {@link #JOURS_APRES_DEPART} jours après le départ ; ensuite la
 * conversation reste lisible.
 */
@Service
@RequiredArgsConstructor
public class MessagerieService {

    static final int JOURS_APRES_DEPART = 7;
    static final int MESSAGES_AFFICHES = 200;
    static final int CONVERSATIONS_AFFICHEES = 50;
    /** Anti-abus : au plus 30 messages par tranche de 10 minutes et par expéditeur. */
    static final int MESSAGES_MAX_PAR_10_MIN = 30;

    private static final EnumSet<StatutReservation> TOUS_STATUTS = EnumSet.allOf(StatutReservation.class);

    private final ConversationRepository conversations;
    private final MessageRepository messages;
    private final TrajetRepository trajets;
    private final ReservationRepository reservations;
    private final UtilisateurRepository utilisateurs;
    private final ApplicationEventPublisher evenements;

    /** Retrouve (ou crée) la conversation d'un trajet avec un passager, et renvoie son identifiant. */
    @Transactional
    public Long ouvrir(Long utilisateurId, Long trajetId, OuvertureRequete req) {
        Trajet t = trajets.findById(trajetId).orElseThrow(() -> ApiException.notFound("Trajet introuvable"));
        boolean conducteur = t.getConducteur().getId().equals(utilisateurId);
        Long passagerId;
        if (conducteur) {
            passagerId = req == null ? null : req.idPassager();
            if (passagerId == null) throw ApiException.badRequest("Indiquez le passager à qui écrire").surChamp("idPassager");
            if (!reservations.existsByTrajetIdAndPassagerIdAndStatutIn(trajetId, passagerId, TOUS_STATUTS)) {
                throw ApiException.notFound("Ce passager n'a pas réservé ce trajet");
            }
        } else {
            passagerId = utilisateurId;
            boolean aReserve = reservations.existsByTrajetIdAndPassagerIdAndStatutIn(trajetId, passagerId, TOUS_STATUTS);
            boolean aVenir = t.getStatut() == StatutTrajet.PUBLIE || t.getStatut() == StatutTrajet.COMPLET;
            if (!aReserve && !aVenir) {
                throw ApiException.conflict("Ce trajet n'est plus ouvert : vous ne pouvez écrire qu'au conducteur d'un trajet à venir ou que vous avez réservé");
            }
        }
        return conversations.findByTrajetIdAndPassagerId(trajetId, passagerId).map(Conversation::getId).orElseGet(() -> {
            Utilisateur passager = utilisateurs.findById(passagerId).orElseThrow(() -> ApiException.notFound("Utilisateur introuvable"));
            Conversation c = new Conversation();
            c.setTrajet(t);
            c.setPassager(passager);
            return conversations.save(c).getId();
        });
    }

    @Transactional(readOnly = true)
    public List<ConversationResume> mesConversations(Long utilisateurId) {
        List<ConversationResume> liste = new ArrayList<>();
        for (Conversation c : conversations.deUtilisateur(utilisateurId, PageRequest.of(0, CONVERSATIONS_AFFICHEES))) {
            Message dernier = messages.findFirstByConversationIdOrderByDateEnvoiDescIdDesc(c.getId()).orElse(null);
            liste.add(new ConversationResume(c.getId(), TrajetResume.de(c.getTrajet()),
                    UtilisateurResume.de(c.interlocuteurDe(utilisateurId)), c.conducteur().getId().equals(utilisateurId),
                    dernier == null ? null : apercu(dernier.getContenu()),
                    dernier != null && dernier.getExpediteur().getId().equals(utilisateurId),
                    c.getDateDernierMessage(),
                    messages.countByConversationIdAndExpediteurIdNotAndDateLectureIsNull(c.getId(), utilisateurId)));
        }
        return liste;
    }

    /** Ouvre une conversation : les messages reçus deviennent lus. */
    @Transactional
    public ConversationDetail consulter(Long utilisateurId, Long conversationId) {
        Conversation c = charger(utilisateurId, conversationId);
        messages.marquerLus(c.getId(), utilisateurId, LocalDateTime.now());
        List<MessageDto> fil = new ArrayList<>(messages
                .findByConversationIdOrderByDateEnvoiDescIdDesc(c.getId(), PageRequest.of(0, MESSAGES_AFFICHES))
                .stream().map(m -> MessageDto.de(m, utilisateurId)).toList());
        java.util.Collections.reverse(fil);
        return new ConversationDetail(c.getId(), TrajetResume.de(c.getTrajet()),
                UtilisateurResume.de(c.interlocuteurDe(utilisateurId)), c.conducteur().getId().equals(utilisateurId),
                fermeture(c), fil);
    }

    @Transactional
    public MessageDto envoyer(Long utilisateurId, Long conversationId, EnvoiRequete req) {
        Conversation c = charger(utilisateurId, conversationId);
        Utilisateur expediteur = utilisateurs.findById(utilisateurId).orElseThrow(() -> ApiException.notFound("Utilisateur introuvable"));
        if (!expediteur.estActif()) throw ApiException.forbidden("Votre compte ne permet pas d'envoyer de message");
        String raison = fermeture(c);
        if (raison != null) throw ApiException.conflict(raison);
        String contenu = req.contenu().strip();
        if (contenu.isEmpty()) throw ApiException.badRequest("Le message est vide").surChamp("contenu");
        if (messages.countByExpediteurIdAndDateEnvoiAfter(utilisateurId, LocalDateTime.now().minusMinutes(10)) >= MESSAGES_MAX_PAR_10_MIN) {
            throw ApiException.tooManyRequests("Vous envoyez trop de messages : patientez quelques minutes");
        }

        Message m = new Message();
        m.setConversation(c);
        m.setExpediteur(expediteur);
        m.setContenu(contenu);
        messages.save(m);
        c.setDateDernierMessage(m.getDateEnvoi());
        evenements.publishEvent(new MessageEnvoye(m.getId()));
        return MessageDto.de(m, utilisateurId);
    }

    @Transactional(readOnly = true)
    public long nonLus(Long utilisateurId) {
        return messages.nonLus(utilisateurId);
    }

    // ------------------------------------------------------------------ utilitaires

    /** Seuls les deux participants voient la conversation ; pour les autres, elle n'existe pas. */
    private Conversation charger(Long utilisateurId, Long conversationId) {
        return conversations.findById(conversationId)
                .filter(c -> c.participe(utilisateurId))
                .orElseThrow(() -> ApiException.notFound("Conversation introuvable"));
    }

    /** Raison pour laquelle on ne peut plus écrire, ou null si la conversation est ouverte. */
    private static String fermeture(Conversation c) {
        if (c.getTrajet().getDateHeureDepart().plusDays(JOURS_APRES_DEPART).isBefore(LocalDateTime.now())) {
            return "Cette conversation est fermée : le trajet date de plus de " + JOURS_APRES_DEPART + " jours";
        }
        return null;
    }

    private static String apercu(String contenu) {
        return contenu.length() > 120 ? contenu.substring(0, 117) + "..." : contenu;
    }
}
