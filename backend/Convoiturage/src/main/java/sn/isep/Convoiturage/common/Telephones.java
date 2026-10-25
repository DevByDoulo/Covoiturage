package sn.isep.Convoiturage.common;

import java.util.regex.Pattern;

/** Normalisation des numéros au format international E.164 (+221 par défaut). */
public final class Telephones {

    private static final Pattern E164 = Pattern.compile("^\\+[1-9]\\d{7,14}$");
    private static final Pattern LOCAL_SN = Pattern.compile("^(7[05678]|33)\\d{7}$");

    private Telephones() {}

    public static String normaliser(String brut) {
        if (brut == null) return null;
        String t = brut.replaceAll("[\\s.\\-()]", "");
        if (t.startsWith("00")) t = "+" + t.substring(2);
        if (LOCAL_SN.matcher(t).matches()) t = "+221" + t;
        if (!E164.matcher(t).matches()) {
            throw ApiException.badRequest("Numéro de téléphone invalide (ex. : 77 123 45 67 ou +221771234567)");
        }
        return t;
    }

    /** +221771234567 -> +221 77 *** ** 67 */
    public static String masquer(String telephone) {
        if (telephone == null || telephone.length() < 9) return telephone;
        String fin = telephone.substring(telephone.length() - 2);
        if (telephone.startsWith("+221") && telephone.length() == 13) {
            return "+221 " + telephone.substring(4, 6) + " *** ** " + fin;
        }
        return telephone.substring(0, telephone.length() - 7) + " *** ** " + fin;
    }
}
