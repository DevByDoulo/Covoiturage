package sn.isep.Convoiturage.messagerie;

import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.*;
import sn.isep.Convoiturage.common.SecurityUtils;
import sn.isep.Convoiturage.messagerie.MessagerieDtos.*;

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
}
