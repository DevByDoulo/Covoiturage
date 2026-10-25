package sn.isep.Convoiturage.tarification;

import java.math.BigDecimal;

/** Clés des coefficients de tarification, avec une valeur de repli si la ligne est absente ou inactive. */
public enum CleParametre {
    PRIX_ESSENCE("990"),
    PRIX_GASOIL("755"),
    PRIX_ELECTRICITE("120"),
    AMORTISSEMENT_KM_DEFAUT("25"),
    MAJORATION_HEURE_POINTE("0.08"),
    MARGE_AJUSTEMENT("0.10"),
    ARRONDI("50"),
    PRIX_MINIMUM("500");

    private final BigDecimal defaut;

    CleParametre(String defaut) {
        this.defaut = new BigDecimal(defaut);
    }

    public BigDecimal defaut() {
        return defaut;
    }
}
