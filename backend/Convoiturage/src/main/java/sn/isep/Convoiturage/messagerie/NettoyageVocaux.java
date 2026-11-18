package sn.isep.Convoiturage.messagerie;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;
import org.springframework.transaction.support.TransactionTemplate;
import sn.isep.Convoiturage.common.stockage.StockageService;
import sn.isep.Convoiturage.common.stockage.StockageService.Dossier;
import sn.isep.Convoiturage.common.stockage.StockageService.FichierListe;

import java.time.Duration;
import java.time.Instant;
import java.time.LocalDateTime;
import java.util.HashSet;
import java.util.List;
import java.util.Set;

/**
 * Tous les jours à 3 h 30 (Dakar) :
 * <ul>
 *   <li>efface le fichier des vocaux dont le trajet est parti depuis plus que la durée de conservation
 *       ({@code app.messagerie.vocal.conservation}, 180 jours par défaut) ; le message reste (« vocal expiré ») ;</li>
 *   <li>supprime les fichiers orphelins du dossier « vocaux » (aucun message ne les cite), créés depuis plus d'une
 *       heure pour ne jamais toucher un envoi en cours.</li>
 * </ul>
 */
@Slf4j
@Component
@RequiredArgsConstructor
public class NettoyageVocaux {

    static final Duration AGE_MIN_ORPHELIN = Duration.ofHours(1);
    private static final int LOT = 500;

    private final MessageRepository messages;
    private final StockageService stockage;
    private final VocalProperties vocal;
    private final TransactionTemplate transaction;

    public record Bilan(int expires, int orphelins) {}

    @Scheduled(cron = "0 30 3 * * *", zone = "Africa/Dakar")
    public void executerChaqueNuit() {
        Bilan b = nettoyer(LocalDateTime.now(), Instant.now());
        if (b.expires() + b.orphelins() > 0) {
            log.info("Messages vocaux : {} fichier(s) expiré(s), {} fichier(s) orphelin(s) supprimé(s)", b.expires(), b.orphelins());
        }
    }

    public Bilan nettoyer(LocalDateTime maintenant, Instant instant) {
        return new Bilan(expirer(maintenant), supprimerOrphelins(instant));
    }

    /** Les fichiers ne sont effacés qu'une fois la base validée (sinon, la tâche des orphelins les rattrape). */
    int expirer(LocalDateTime maintenant) {
        List<String> noms = transaction.execute(statut -> {
            List<Message> echus = messages.vocauxEchus(maintenant.minus(vocal.conservation()));
            List<String> fichiers = echus.stream().map(Message::getFichierAudio).toList();
            echus.forEach(m -> {
                m.setFichierAudio(null);
                m.setFormeOnde(null);
            });
            return fichiers;
        });
        if (noms == null) return 0;
        noms.forEach(nom -> stockage.supprimer(nom, Dossier.VOCAUX));
        return noms.size();
    }

    int supprimerOrphelins(Instant maintenant) {
        List<String> candidats = stockage.lister(Dossier.VOCAUX).stream()
                .filter(f -> f.modifie().isBefore(maintenant.minus(AGE_MIN_ORPHELIN)))
                .map(FichierListe::nom).toList();
        int supprimes = 0;
        for (int i = 0; i < candidats.size(); i += LOT) {
            List<String> lot = candidats.subList(i, Math.min(i + LOT, candidats.size()));
            Set<String> cites = new HashSet<>(messages.fichiersAudioCites(lot));
            for (String nom : lot) {
                if (!cites.contains(nom)) {
                    stockage.supprimer(nom, Dossier.VOCAUX);
                    supprimes++;
                }
            }
        }
        return supprimes;
    }
}
