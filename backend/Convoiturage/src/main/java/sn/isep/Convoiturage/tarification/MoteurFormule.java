package sn.isep.Convoiturage.tarification;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Component;
import sn.isep.Convoiturage.vehicule.TypeEnergie;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.DayOfWeek;
import java.time.LocalDateTime;
import java.time.Year;
import java.util.function.Function;

/**
 * Tarification de base par partage des frais réels :
 * <pre>
 *   coût carburant = distance × conso/100 × facteurs(route, dénivelé, trafic, météo) × prix énergie
 *   coût usure     = distance × amortissement/km
 *   coût total     = carburant + usure + péages
 *   prix/place     = coût total / (places proposées + conducteur), arrondi, borné par le prix plancher
 *   fourchette     = prix ± MARGE_AJUSTEMENT (10 %)
 * </pre>
 * Les coefficients sont lus dans parametre_tarification (modifiables par l'administrateur).
 * {@link MoteurIA} y ajoute une consommation prédite et un facteur météo ({@link ApportIA}).
 */
@Component
public class MoteurFormule implements MoteurTarification {

    public static final String VERSION = "FORMULE-1.0";

    /** Apport du service IA : consommation prédite (utilisée si le conducteur n'en a déclaré aucune) et météo. */
    public record ApportIA(BigDecimal consommationPredite, double facteurMeteo, String versionModele) {}

    private final Function<CleParametre, BigDecimal> parametres;

    @Autowired
    public MoteurFormule(ParametresTarification parametres) {
        this(parametres::valeur);
    }

    MoteurFormule(Function<CleParametre, BigDecimal> parametres) {
        this.parametres = parametres;
    }

    @Override
    public EstimationPrix estimer(DemandeEstimation d) {
        return estimer(d, null);
    }

    /** @param ia apport du service IA, ou null pour la formule seule. */
    public EstimationPrix estimer(DemandeEstimation d, ApportIA ia) {
        if (d.distanceKm() <= 0) throw new IllegalArgumentException("Distance invalide");
        if (d.nombrePlacesProposees() < 1) throw new IllegalArgumentException("Au moins une place doit être proposée");

        // 1. Consommation (L ou kWh / 100 km) : réelle > théorique > prédite par l'IA > estimée par la formule.
        SourceConsommation source = d.consommationReelle() != null ? SourceConsommation.REELLE
                : d.consommationTheorique() != null ? SourceConsommation.THEORIQUE
                : ia != null && ia.consommationPredite() != null ? SourceConsommation.IA
                : SourceConsommation.FORMULE;
        double conso = switch (source) {
            case REELLE -> d.consommationReelle().doubleValue();
            case THEORIQUE -> d.consommationTheorique().doubleValue();
            case IA -> ia.consommationPredite().doubleValue();
            case FORMULE -> estimerConsommation(d.typeEnergie(), d.puissanceFiscale(), d.anneeVehicule());
        };
        boolean estimee = source == SourceConsommation.IA || source == SourceConsommation.FORMULE;

        // 2. Facteurs de contexte.
        double facteurRoute = switch (d.typeRoute()) {
            case VILLE -> 1.20;
            case MIXTE -> 1.08;
            case NATIONALE -> 1.00;
            case AUTOROUTE -> 0.95;
        };
        double penteMoyenne = d.deniveleM() / Math.max(d.distanceKm(), 1.0); // m de dénivelé positif par km
        double facteurDenivele = 1 + Math.min(0.15, penteMoyenne * 0.005);
        boolean pointe = estHeureDePointe(d.dateHeureDepart());
        double facteurTrafic = pointe ? 1 + p(CleParametre.MAJORATION_HEURE_POINTE).doubleValue() : 1.0;
        double facteurMeteo = ia != null ? ia.facteurMeteo() : 1.0;

        // 3. Coûts.
        BigDecimal prixEnergie = switch (d.typeEnergie()) {
            case ESSENCE, HYBRIDE -> p(CleParametre.PRIX_ESSENCE);
            case DIESEL -> p(CleParametre.PRIX_GASOIL);
            case ELECTRIQUE -> p(CleParametre.PRIX_ELECTRICITE);
        };
        double quantite = d.distanceKm() * conso / 100.0 * facteurRoute * facteurDenivele * facteurTrafic * facteurMeteo;
        BigDecimal coutCarburant = bd(quantite * prixEnergie.doubleValue());
        BigDecimal amortissement = d.amortissementParKm() != null ? d.amortissementParKm() : p(CleParametre.AMORTISSEMENT_KM_DEFAUT);
        BigDecimal coutUsure = bd(d.distanceKm() * amortissement.doubleValue());
        BigDecimal coutPeages = d.montantPeages() == null ? BigDecimal.ZERO : d.montantPeages();
        BigDecimal coutTotal = coutCarburant.add(coutUsure).add(coutPeages);

        // 4. Partage entre les occupants (passagers + conducteur), arrondi et fourchette.
        int occupants = d.nombrePlacesProposees() + 1;
        BigDecimal arrondi = p(CleParametre.ARRONDI);
        BigDecimal plancher = p(CleParametre.PRIX_MINIMUM);
        BigDecimal marge = p(CleParametre.MARGE_AJUSTEMENT);

        BigDecimal prix = arrondir(coutTotal.divide(BigDecimal.valueOf(occupants), 2, RoundingMode.HALF_UP), arrondi, RoundingMode.HALF_UP)
                .max(plancher);
        BigDecimal min = arrondir(prix.multiply(BigDecimal.ONE.subtract(marge)), arrondi, RoundingMode.CEILING).max(plancher).min(prix);
        BigDecimal max = arrondir(prix.multiply(BigDecimal.ONE.add(marge)), arrondi, RoundingMode.FLOOR).max(prix);

        String version = ia != null ? ia.versionModele() + "+" + VERSION : VERSION;
        return new EstimationPrix(prix, min, max, prixEnergie, bd(conso), estimee, source,
                BigDecimal.valueOf(facteurMeteo).setScale(3, RoundingMode.HALF_UP), pointe, version,
                coutCarburant, coutUsure, coutPeages, coutTotal, occupants);
    }

    /**
     * Repli lorsque le conducteur n'a déclaré aucune consommation : approximation linéaire selon la
     * puissance fiscale, majorée de 1 %/an au-delà de 10 ans (plafond +20 %).
     */
    static double estimerConsommation(TypeEnergie energie, int puissanceFiscale, int annee) {
        double base = switch (energie) {
            case ESSENCE -> 4.5 + 0.45 * puissanceFiscale;
            case DIESEL -> 3.8 + 0.38 * puissanceFiscale;
            case HYBRIDE -> 3.5 + 0.25 * puissanceFiscale;
            case ELECTRIQUE -> 13.0 + 0.60 * puissanceFiscale; // kWh/100 km
        };
        int age = Math.max(0, Year.now().getValue() - annee);
        double usure = 1 + Math.min(0.20, Math.max(0, age - 10) * 0.01);
        return base * usure;
    }

    /** Heures de pointe en semaine : 7h-9h et 17h-20h. */
    static boolean estHeureDePointe(LocalDateTime t) {
        if (t.getDayOfWeek() == DayOfWeek.SATURDAY || t.getDayOfWeek() == DayOfWeek.SUNDAY) return false;
        int h = t.getHour();
        return (h >= 7 && h < 9) || (h >= 17 && h < 20);
    }

    private BigDecimal p(CleParametre cle) {
        return parametres.apply(cle);
    }

    private static BigDecimal bd(double v) {
        return BigDecimal.valueOf(v).setScale(2, RoundingMode.HALF_UP);
    }

    private static BigDecimal arrondir(BigDecimal valeur, BigDecimal pas, RoundingMode mode) {
        if (pas.signum() <= 0) return valeur.setScale(0, mode);
        return valeur.divide(pas, 0, mode).multiply(pas).setScale(2, RoundingMode.UNNECESSARY);
    }
}
