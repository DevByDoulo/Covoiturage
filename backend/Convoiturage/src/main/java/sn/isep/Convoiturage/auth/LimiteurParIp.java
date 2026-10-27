package sn.isep.Convoiturage.auth;

import org.springframework.stereotype.Component;
import sn.isep.Convoiturage.common.ApiException;

import java.time.Duration;
import java.time.Instant;
import java.util.ArrayDeque;
import java.util.Deque;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

/**
 * Nombre maximal de demandes par adresse IP et par heure, pour les appels publics sensibles (mot de passe
 * oublié) : empêche de passer en revue de nombreux comptes depuis une même machine. Les plafonds restent
 * larges, car beaucoup d'abonnés mobiles partagent une même IP chez leur opérateur.
 * <p>
 * Mémoire locale, comme {@link LimiteurConnexion}. Derrière un proxy (Nginx...), activer
 * {@code server.forward-headers-strategy: framework} pour obtenir l'IP réelle du client.
 */
@Component
class LimiteurParIp {

    enum Action {
        DEMANDE_CODE(20), VERIFICATION_CODE(30);

        final int maxParHeure;

        Action(int maxParHeure) {
            this.maxParHeure = maxParHeure;
        }
    }

    private static final Duration FENETRE = Duration.ofHours(1);

    private final Map<String, Deque<Instant>> demandes = new ConcurrentHashMap<>();

    /** Enregistre la demande, ou la refuse (429) si le plafond est atteint pour cette IP. */
    void consommer(Action action, String ip) {
        Deque<Instant> liste = demandes.computeIfAbsent(action + "|" + ip, k -> new ArrayDeque<>());
        synchronized (liste) {
            Instant maintenant = Instant.now();
            while (!liste.isEmpty() && liste.peekFirst().isBefore(maintenant.minus(FENETRE))) liste.removeFirst();
            if (liste.size() >= action.maxParHeure) {
                long secondes = Math.max(1, Duration.between(maintenant, liste.peekFirst().plus(FENETRE)).toSeconds());
                long minutes = (secondes + 59) / 60;
                throw ApiException.tooManyRequests("Trop de demandes depuis cette connexion. Réessayez dans "
                                + minutes + " minute" + (minutes > 1 ? "s" : "") + ".")
                        .avec("reessayerDansSecondes", secondes).avec("motif", "LIMITE_IP");
            }
            liste.addLast(maintenant);
        }
    }
}
