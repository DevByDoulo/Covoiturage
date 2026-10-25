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
 * Protection contre la force brute sur la connexion : après 5 échecs en 15 minutes pour un même
 * identifiant, les tentatives sont refusées jusqu'à l'expiration de la fenêtre.
 * Mémoire locale : suffisant pour une instance ; à déplacer dans Redis en cas de déploiement multi-instances.
 */
@Component
public class LimiteurConnexion {

    static final int ECHECS_MAX = 5;
    static final Duration FENETRE = Duration.ofMinutes(15);

    private final Map<String, Deque<Instant>> echecs = new ConcurrentHashMap<>();

    public void verifierAutorise(String identifiant) {
        Deque<Instant> liste = echecs.get(cle(identifiant));
        if (liste == null) return;
        synchronized (liste) {
            purger(liste);
            if (liste.size() >= ECHECS_MAX) {
                long secondes = Math.max(1, Duration.between(Instant.now(), liste.peekFirst().plus(FENETRE)).toSeconds());
                long minutes = (secondes + 59) / 60;
                throw ApiException.tooManyRequests("Trop de tentatives. Réessayez dans " + minutes + " minute" + (minutes > 1 ? "s" : "") + ".")
                        .avec("reessayerDansSecondes", secondes);
            }
        }
    }

    public void enregistrerEchec(String identifiant) {
        Deque<Instant> liste = echecs.computeIfAbsent(cle(identifiant), k -> new ArrayDeque<>());
        synchronized (liste) {
            purger(liste);
            liste.addLast(Instant.now());
        }
    }

    public void reinitialiser(String identifiant) {
        echecs.remove(cle(identifiant));
    }

    private static void purger(Deque<Instant> liste) {
        Instant limite = Instant.now().minus(FENETRE);
        while (!liste.isEmpty() && liste.peekFirst().isBefore(limite)) liste.removeFirst();
    }

    private static String cle(String identifiant) {
        return identifiant.trim().toLowerCase().replaceAll("[\\s.\\-()]", "");
    }
}
