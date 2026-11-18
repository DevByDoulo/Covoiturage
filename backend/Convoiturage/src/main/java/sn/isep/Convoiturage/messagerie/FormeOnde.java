package sn.isep.Convoiturage.messagerie;

import sn.isep.Convoiturage.common.ApiException;

import java.util.ArrayList;
import java.util.List;

/**
 * Forme d'onde d'un vocal : au plus {@link #MAX_BARRES} niveaux de 0 à 100, mesurés par l'application pendant
 * l'enregistrement et stockés sous la forme « 12,40,87,… ». Purement décorative : elle n'est jamais utilisée pour
 * contrôler le fichier.
 */
final class FormeOnde {

    static final int MAX_BARRES = 64;

    private FormeOnde() {}

    /** Valide et normalise la valeur envoyée par le client ; null ou vide => pas de forme d'onde. */
    static String valider(String brut) {
        if (brut == null || brut.isBlank()) return null;
        String[] parties = brut.split(",");
        if (parties.length > MAX_BARRES) throw invalide();
        List<String> niveaux = new ArrayList<>(parties.length);
        for (String p : parties) {
            int n;
            try {
                n = Integer.parseInt(p.strip());
            } catch (NumberFormatException e) {
                throw invalide();
            }
            if (n < 0 || n > 100) throw invalide();
            niveaux.add(Integer.toString(n));
        }
        return String.join(",", niveaux);
    }

    static List<Integer> lire(String stocke) {
        if (stocke == null || stocke.isEmpty()) return List.of();
        List<Integer> niveaux = new ArrayList<>();
        for (String p : stocke.split(",")) niveaux.add(Integer.parseInt(p));
        return niveaux;
    }

    private static ApiException invalide() {
        return ApiException.badRequest("Forme d'onde invalide : au plus " + MAX_BARRES + " niveaux entre 0 et 100")
                .surChamp("formeOnde");
    }
}
