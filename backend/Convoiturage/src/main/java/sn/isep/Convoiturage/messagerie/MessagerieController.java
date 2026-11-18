package sn.isep.Convoiturage.messagerie;

import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.core.io.Resource;
import org.springframework.http.CacheControl;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;
import sn.isep.Convoiturage.common.SecurityUtils;
import sn.isep.Convoiturage.messagerie.MessagerieDtos.*;

import java.time.Duration;
import java.util.List;
import java.util.Map;

@RestController
@RequiredArgsConstructor
public class MessagerieController {

    private final MessagerieService service;

    /** Passager : sans corps. Conducteur : {@code {"idPassager": …}}. Renvoie l'identifiant de la conversation. */
    @PostMapping("/api/trajets/{id}/conversation")
    public Map<String, Long> ouvrir(@PathVariable Long id, @RequestBody(required = false) OuvertureRequete req) {
        return Map.of("id", service.ouvrir(SecurityUtils.utilisateurCourantId(), id, req));
    }

    @GetMapping("/api/moi/conversations")
    public List<ConversationResume> mesConversations() {
        return service.mesConversations(SecurityUtils.utilisateurCourantId());
    }

    @GetMapping("/api/moi/conversations/non-lus")
    public NombreDto nonLus() {
        return new NombreDto(service.nonLus(SecurityUtils.utilisateurCourantId()));
    }

    @GetMapping("/api/moi/conversations/{id}")
    public ConversationDetail consulter(@PathVariable Long id) {
        return service.consulter(SecurityUtils.utilisateurCourantId(), id);
    }

    @PostMapping("/api/moi/conversations/{id}/messages")
    @ResponseStatus(HttpStatus.CREATED)
    public MessageDto envoyer(@PathVariable Long id, @Valid @RequestBody EnvoiRequete req) {
        return service.envoyer(SecurityUtils.utilisateurCourantId(), id, req);
    }

    /** Message vocal (multipart) : {@code fichier} (WebM, Ogg, MP4/M4A ou AAC) et {@code formeOnde} facultative. */
    @PostMapping(path = "/api/moi/conversations/{id}/vocaux", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    @ResponseStatus(HttpStatus.CREATED)
    public MessageDto envoyerVocal(@PathVariable Long id, @RequestPart(name = "fichier", required = false) MultipartFile fichier,
                                   @RequestParam(required = false) String formeOnde) {
        return service.envoyerVocal(SecurityUtils.utilisateurCourantId(), id, fichier, formeOnde);
    }

    /**
     * Fichier d'un vocal, réservé aux deux participants. Les requêtes Range (lecture et avance rapide des lecteurs
     * audio) sont prises en charge par Spring pour une {@link Resource} : réponse 206 avec la plage demandée.
     */
    @GetMapping("/api/moi/conversations/{id}/messages/{idMessage}/audio")
    public ResponseEntity<Resource> audio(@PathVariable Long id, @PathVariable Long idMessage) {
        MessagerieService.FichierAudio f = service.audio(SecurityUtils.utilisateurCourantId(), id, idMessage);
        return ResponseEntity.ok()
                .contentType(MediaType.parseMediaType(f.typeMime()))
                .cacheControl(CacheControl.maxAge(Duration.ofHours(1)).cachePrivate())
                .body(f.ressource());
    }

    /** Le destinataire a écouté le vocal. */
    @PostMapping("/api/moi/conversations/{id}/messages/{idMessage}/ecoute")
    public MessageDto ecoute(@PathVariable Long id, @PathVariable Long idMessage) {
        return service.marquerEcoute(SecurityUtils.utilisateurCourantId(), id, idMessage);
    }
}
