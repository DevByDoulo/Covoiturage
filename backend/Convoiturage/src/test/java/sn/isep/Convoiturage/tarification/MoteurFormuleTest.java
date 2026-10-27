package sn.isep.Convoiturage.tarification;

import org.junit.jupiter.api.Test;
import sn.isep.Convoiturage.tarification.MoteurTarification.DemandeEstimation;
import sn.isep.Convoiturage.tarification.MoteurTarification.EstimationPrix;
import sn.isep.Convoiturage.trajet.TypeRoute;
import sn.isep.Convoiturage.vehicule.TypeEnergie;

import java.math.BigDecimal;
import java.time.LocalDateTime;

import static org.assertj.core.api.Assertions.assertThat;

class MoteurFormuleTest {

    private final MoteurFormule moteur = new MoteurFormule(CleParametre::defaut);

    /** Samedi 10h : pas d'heure de pointe. */
    private static final LocalDateTime SAMEDI_MATIN = LocalDateTime.of(2026, 11, 7, 10, 0);

    static final double DAKAR_LAT = 14.6928, DAKAR_LNG = -17.4467;

    static DemandeEstimation dakarThies(int places, LocalDateTime depart) {
        // ~70 km, essence, 7 L/100 réels, 25 FCFA/km d'usure, nationale.
        return new DemandeEstimation("Toyota", TypeEnergie.ESSENCE, 7, 2018, null, new BigDecimal("7.0"), new BigDecimal("25"),
                70, 0, TypeRoute.NATIONALE, BigDecimal.ZERO, places, depart, DAKAR_LAT, DAKAR_LNG);
    }

    @Test
    void calculLeCoutPartageEntreLesOccupants() {
        EstimationPrix e = moteur.estimer(dakarThies(3, SAMEDI_MATIN));

        // carburant : 70 × 7/100 × 990 = 4851 ; usure : 70 × 25 = 1750 ; total 6601 ; / 4 occupants = 1650,25 -> 1650
        assertThat(e.coutCarburant()).isEqualByComparingTo("4851.00");
        assertThat(e.coutUsure()).isEqualByComparingTo("1750.00");
        assertThat(e.coutTotal()).isEqualByComparingTo("6601.00");
        assertThat(e.nombreOccupants()).isEqualTo(4);
        assertThat(e.prixRecommande()).isEqualByComparingTo("1650");
        assertThat(e.prixMin()).isEqualByComparingTo("1500");   // ceil50(1485)
        assertThat(e.prixMax()).isEqualByComparingTo("1800");   // floor50(1815)
        assertThat(e.heureDePointe()).isFalse();
        assertThat(e.consommationEstimee()).isFalse();
    }

    @Test
    void appliqueLaMajorationAuxHeuresDePointe() {
        LocalDateTime lundi18h = LocalDateTime.of(2026, 11, 9, 18, 0);
        EstimationPrix pointe = moteur.estimer(dakarThies(3, lundi18h));
        EstimationPrix creuse = moteur.estimer(dakarThies(3, SAMEDI_MATIN));

        assertThat(pointe.heureDePointe()).isTrue();
        assertThat(pointe.coutCarburant()).isGreaterThan(creuse.coutCarburant());
    }

    @Test
    void respecteLePrixPlancher() {
        DemandeEstimation courte = new DemandeEstimation("Toyota", TypeEnergie.DIESEL, 5, 2020, new BigDecimal("5"), null, null,
                3, 0, TypeRoute.VILLE, BigDecimal.ZERO, 4, SAMEDI_MATIN, DAKAR_LAT, DAKAR_LNG);
        EstimationPrix e = moteur.estimer(courte);

        assertThat(e.prixRecommande()).isEqualByComparingTo("500");
        assertThat(e.prixMin()).isEqualByComparingTo("500");
        assertThat(e.prixMax()).isGreaterThanOrEqualTo(e.prixRecommande());
    }

    @Test
    void estimeLaConsommationQuandElleNestPasDeclaree() {
        DemandeEstimation d = new DemandeEstimation("Toyota", TypeEnergie.ESSENCE, 7, 2018, null, null, null,
                100, 0, TypeRoute.AUTOROUTE, new BigDecimal("1500"), 2, SAMEDI_MATIN, DAKAR_LAT, DAKAR_LNG);
        EstimationPrix e = moteur.estimer(d);

        assertThat(e.consommationEstimee()).isTrue();
        assertThat(e.sourceConsommation()).isEqualTo(MoteurTarification.SourceConsommation.FORMULE);
        assertThat(e.consommationUtilisee().doubleValue()).isBetween(6.0, 9.0);
        assertThat(e.coutPeages()).isEqualByComparingTo("1500");
        assertThat(e.facteurMeteo()).isEqualByComparingTo("1");
        assertThat(e.versionModele()).isEqualTo("FORMULE-1.0");
    }

    @Test
    void utiliseLaConsommationPrediteParLIaQuandRienNestDeclare() {
        DemandeEstimation d = new DemandeEstimation("Toyota", TypeEnergie.ESSENCE, 7, 2018, null, null, new BigDecimal("25"),
                70, 0, TypeRoute.NATIONALE, BigDecimal.ZERO, 3, SAMEDI_MATIN, DAKAR_LAT, DAKAR_LNG);
        EstimationPrix e = moteur.estimer(d, new MoteurFormule.ApportIA(new BigDecimal("7.0"), 1.0, "xgb-ademe-test"));

        assertThat(e.sourceConsommation()).isEqualTo(MoteurTarification.SourceConsommation.IA);
        assertThat(e.consommationEstimee()).isTrue();
        assertThat(e.coutCarburant()).isEqualByComparingTo("4851.00"); // même calcul qu'avec 7 L/100 déclarés
        assertThat(e.versionModele()).isEqualTo("xgb-ademe-test+FORMULE-1.0");
    }

    @Test
    void laConsommationDeclareePrimeMaisLaMeteoSApplique() {
        EstimationPrix e = moteur.estimer(dakarThies(3, SAMEDI_MATIN),
                new MoteurFormule.ApportIA(new BigDecimal("12.0"), 1.064, "xgb-ademe-test"));

        assertThat(e.sourceConsommation()).isEqualTo(MoteurTarification.SourceConsommation.REELLE);
        assertThat(e.consommationUtilisee()).isEqualByComparingTo("7.00");
        assertThat(e.facteurMeteo()).isEqualByComparingTo("1.064");
        assertThat(e.coutCarburant()).isEqualByComparingTo("5161.46"); // 4851 × 1,064
    }
}
