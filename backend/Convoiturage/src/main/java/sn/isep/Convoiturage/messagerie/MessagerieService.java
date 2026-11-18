package sn.isep.Convoiturage.messagerie;

import lombok.RequiredArgsConstructor;
import org.springframework.context.ApplicationEventPublisher;
import org.springframework.core.io.Resource;
import org.springframework.data.domain.PageRequest;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.transaction.support.TransactionSynchronization;
import org.springframework.transaction.support.TransactionSynchronizationManager;
import org.springframework.web.multipart.MultipartFile;
import sn.isep.Convoiturage.common.ApiException;
import sn.isep.Convoiturage.common.stockage.StockageService;
import sn.isep.Convoiturage.common.stockage.StockageService.Dossier;
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

import java.io.IOException;
import java.io.UncheckedIOException;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.EnumSet;
import java.util.List;
import java.util.Optional;

/**
 * 09 — Messagerie entre le conducteur d'un trajet et un passager. Un passager peut écrire au conducteur d'un trajet
 * à venir (pour poser une question avant de réserver) ou d'un trajet qu'il a réservé ; le conducteur écrit aux
 * passagers qui ont réservé. On peut écrire jusqu'à {@link #JOURS_APRES_DEPART} jours après le départ ; ensuite la
 * conversation reste lisible. Un message est un texte ou un vocal ; le fichier d'un vocal n'est servi qu'aux deux
 * participants (et à l'administrateur qui modère un signalement visant ce message).
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
    private final StockageService stockage;
    private final VocalProperties vocal;

    /** Fichier d'un message vocal, servi par l'API (jamais par une URL publique). */
    public record FichierAudio(Resource ressource, String typeMime) {}

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
                    dernier == null ? null : dernier.apercu(120),
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
        String contenu = req.contenu().strip();
        if (contenu.isEmpty()) throw ApiException.badRequest("Le message est vide").surChamp("contenu");
        Utilisateur expediteur = verifierEnvoi(utilisateurId, c);

        Message m = new Message();
        m.setContenu(contenu);
        return publier(c, expediteur, m);
    }

    /**
     * Message vocal : le format est reconnu aux octets du fichier et la durée lue dans le fichier (jamais celle
     * annoncée par le client). Le fichier est rangé sous un nom aléatoire ; il est effacé si l'enregistrement en base
     * échoue (la tâche de nettoyage rattrape les autres cas).
     */
    @Transactional
    public MessageDto envoyerVocal(Long utilisateurId, Long conversationId, MultipartFile fichier, String formeOnde) {
        Conversation c = charger(utilisateurId, conversationId);
        Utilisateur expediteur = verifierEnvoi(utilisateurId, c);
        if (fichier == null || fichier.isEmpty()) throw ApiException.badRequest("Message vocal manquant").surChamp("fichier");
        if (fichier.getSize() > vocal.tailleMax().toBytes()) {
            throw ApiException.badRequest("Le message vocal dépasse la taille maximale (" + vocal.tailleMax().toMegabytes() + " Mo)")
                    .surChamp("fichier");
        }
        String onde = FormeOnde.valider(formeOnde);
        byte[] octets;
        try {
            octets = fichier.getBytes();
        } catch (IOException e) {
            throw new UncheckedIOException("Lecture du message vocal impossible", e);
        }
        AnalyseAudio.Resultat audio = AnalyseAudio.analyser(octets).orElseThrow(() -> ApiException
                .badRequest("Format audio non accepté (formats acceptés : WebM, Ogg, MP4/M4A, AAC)").surChamp("fichier"));
        // Tolérances : la durée lue dans un WebM peut manquer d'une trame, et l'application coupe à la limite.
        if (audio.dureeMs() < vocal.dureeMin().toMillis() - 100) {
            throw ApiException.badRequest("Message vocal trop court").surChamp("fichier");
        }
        if (audio.dureeMs() > vocal.dureeMax().toMillis() + 1000) {
            throw ApiException.badRequest("Message vocal trop long : " + vocal.dureeMax().toMinutes() + " minutes au plus")
                    .surChamp("fichier");
        }

        String nom = stockage.enregistrer(octets, audio.extension(), Dossier.VOCAUX);
        effacerSiAnnule(nom);
        Message m = new Message();
        m.setType(TypeMessage.VOCAL);
        m.setFichierAudio(nom);
        m.setTypeMimeAudio(audio.typeMime());
        m.setDureeMs((int) Math.min(audio.dureeMs(), vocal.dureeMax().toMillis()));
        m.setFormeOnde(onde);
        return publier(c, expediteur, m);
    }

    /** Fichier d'un vocal, pour les deux participants seulement ; les autres reçoivent 404 comme si rien n'existait. */
    @Transactional(readOnly = true)
    public FichierAudio audio(Long utilisateurId, Long conversationId, Long messageId) {
        Conversation c = charger(utilisateurId, conversationId);
        return fichierDe(messages.findById(messageId).filter(m -> m.getConversation().getId().equals(c.getId())));
    }

    /** Le destinataire a écouté le vocal : « écouté » côté expéditeur (le message devient aussi lu). */
    @Transactional
    public MessageDto marquerEcoute(Long utilisateurId, Long conversationId, Long messageId) {
        Conversation c = charger(utilisateurId, conversationId);
        Message m = messages.findById(messageId).filter(x -> x.getConversation().getId().equals(c.getId()) && x.estVocal())
                .orElseThrow(() -> ApiException.notFound("Message vocal introuvable"));
        if (!m.getExpediteur().getId().equals(utilisateurId) && m.getDateEcoute() == null) {
            LocalDateTime maintenant = LocalDateTime.now();
            m.setDateEcoute(maintenant);
            if (m.getDateLecture() == null) m.setDateLecture(maintenant);
        }
        return MessageDto.de(m, utilisateurId);
    }

    // ------------------------------------------------------------------ Signalements et modération

    /**
     * Message qu'un utilisateur veut signaler : il doit participer à la conversation sans en être l'auteur.
     * Pour les autres, le message n'existe pas.
     */
    @Transactional(readOnly = true)
    public MessageSignale messageASignaler(Long signaleurId, Long messageId) {
        return messages.findById(messageId)
                .filter(m -> m.getConversation().participe(signaleurId) && !m.getExpediteur().getId().equals(signaleurId))
                .map(MessageSignale::de)
                .orElseThrow(() -> ApiException.notFound("Message introuvable"));
    }

    /** Message visé par un signalement, pour le back-office (vide s'il a disparu). */
    @Transactional(readOnly = true)
    public Optional<MessageSignale> messageSignale(Long messageId) {
        return messages.findById(messageId).map(MessageSignale::de);
    }

    /** Fichier d'un vocal signalé : l'appelant (module signalements, rôle ADMIN) a vérifié le signalement. */
    @Transactional(readOnly = true)
    public FichierAudio audioSignale(Long messageId) {
        return fichierDe(messages.findById(messageId));
    }

    @Transactional(readOnly = true)
    public long nonLus(Long utilisateurId) {
        return messages.nonLus(utilisateurId);
    }

    // ------------------------------------------------------------------ utilitaires

    /** Compte actif, conversation ouverte, limite anti-abus : commun au texte et au vocal. */
    private Utilisateur verifierEnvoi(Long utilisateurId, Conversation c) {
        Utilisateur expediteur = utilisateurs.findById(utilisateurId).orElseThrow(() -> ApiException.notFound("Utilisateur introuvable"));
        if (!expediteur.estActif()) throw ApiException.forbidden("Votre compte ne permet pas d'envoyer de message");
        String raison = fermeture(c);
        if (raison != null) throw ApiException.conflict(raison);
        if (messages.countByExpediteurIdAndDateEnvoiAfter(utilisateurId, LocalDateTime.now().minusMinutes(10)) >= MESSAGES_MAX_PAR_10_MIN) {
            throw ApiException.tooManyRequests("Vous envoyez trop de messages : patientez quelques minutes");
        }
        return expediteur;
    }

    private MessageDto publier(Conversation c, Utilisateur expediteur, Message m) {
        m.setConversation(c);
        m.setExpediteur(expediteur);
        messages.save(m);
        c.setDateDernierMessage(m.getDateEnvoi());
        evenements.publishEvent(new MessageEnvoye(m.getId()));
        return MessageDto.de(m, expediteur.getId());
    }

    private FichierAudio fichierDe(Optional<Message> message) {
        Message m = message.filter(x -> x.estVocal() && x.getFichierAudio() != null)
                .orElseThrow(() -> ApiException.notFound("Message vocal introuvable ou expiré"));
        return new FichierAudio(stockage.charger(m.getFichierAudio(), Dossier.VOCAUX), m.getTypeMimeAudio());
    }

    /** Si la transaction est annulée, le fichier déjà écrit est effacé tout de suite. */
    private void effacerSiAnnule(String nom) {
        if (!TransactionSynchronizationManager.isSynchronizationActive()) return;
        TransactionSynchronizationManager.registerSynchronization(new TransactionSynchronization() {
            @Override
            public void afterCompletion(int statut) {
                if (statut != STATUS_COMMITTED) stockage.supprimer(nom, Dossier.VOCAUX);
            }
        });
    }

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
}
