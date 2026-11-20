package sn.isep.Convoiturage.common;

/**
 * Règle des prénoms et noms de personnes : des lettres (accents compris), avec espaces, tirets et apostrophes pour les
 * noms composés (« Marie-Claire », « N'Diaye », « Ba Fall »). Pas de chiffres ni de symboles ; commence par une lettre
 * (les espaces autour sont retirés par le service). Même règle que le site et l'appli mobile.
 */
public final class Noms {

    private Noms() {}

    public static final String REGLE = "^\\s*\\p{L}[\\p{L}\\s'’-]*$";
    public static final String MESSAGE = "Lettres uniquement (les espaces, tirets et apostrophes sont admis)";
}
