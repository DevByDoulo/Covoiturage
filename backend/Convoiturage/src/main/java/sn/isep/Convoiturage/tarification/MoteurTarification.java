package sn.isep.Convoiturage.tarification;

import sn.isep.Convoiturage.trajet.TypeRoute;
import sn.isep.Convoiturage.vehicule.TypeEnergie;

import java.math.BigDecimal;
import java.time.LocalDateTime;

/**
 * Contrat du moteur de prix : {@link MoteurFormule} (formule de coût) et {@link MoteurIA}
 * (consommation prédite par le service FastAPI/XGBoost + facteur météo, avec repli sur la formule).
 */
public interface MoteurTarification {

    EstimationPrix estimer(DemandeEstimation demande);

    /** Paramètres d'entrée : véhicule + trajet + contexte. */
    record DemandeEstimation(
            // Véhicule
            String marque, TypeEnergie typeEnergie, int puissanceFiscale, int anneeVehicule,
            BigDecimal consommationTheorique, BigDecimal consommationReelle, BigDecimal amortissementParKm,
            // Trajet
            double distanceKm, int deniveleM, TypeRoute typeRoute, BigDecimal montantPeages,
            int nombrePlacesProposees, LocalDateTime dateHeureDepart, double latitudeDepart, double longitudeDepart) {}

    /** D'où vient la consommation utilisée : déclarée par le conducteur, prédite par l'IA ou estimée par la formule. */
    enum SourceConsommation { REELLE, THEORIQUE, IA, FORMULE }

    /** Prix par passager (FCFA) et détail du calcul, affiché au conducteur pour la transparence. */
    record EstimationPrix(
            BigDecimal prixRecommande, BigDecimal prixMin, BigDecimal prixMax,
            BigDecimal prixCarburantUtilise, BigDecimal consommationUtilisee, boolean consommationEstimee,
            SourceConsommation sourceConsommation, BigDecimal facteurMeteo,
            boolean heureDePointe, String versionModele,
            BigDecimal coutCarburant, BigDecimal coutUsure, BigDecimal coutPeages, BigDecimal coutTotal,
            int nombreOccupants) {}
}
