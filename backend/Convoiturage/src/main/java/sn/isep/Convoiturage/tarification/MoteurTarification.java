package sn.isep.Convoiturage.tarification;

import sn.isep.Convoiturage.trajet.TypeRoute;
import sn.isep.Convoiturage.vehicule.TypeEnergie;

import java.math.BigDecimal;
import java.time.LocalDateTime;

/**
 * Contrat du moteur de prix. Lot 1 : {@link MoteurFormule} (formule de coût).
 * Lot 2 : une implémentation appellera le microservice FastAPI/XGBoost, avec repli sur la formule.
 */
public interface MoteurTarification {

    EstimationPrix estimer(DemandeEstimation demande);

    /** Paramètres d'entrée : véhicule + trajet + contexte. */
    record DemandeEstimation(
            // Véhicule
            TypeEnergie typeEnergie, int puissanceFiscale, int anneeVehicule,
            BigDecimal consommationTheorique, BigDecimal consommationReelle, BigDecimal amortissementParKm,
            // Trajet
            double distanceKm, int deniveleM, TypeRoute typeRoute, BigDecimal montantPeages,
            int nombrePlacesProposees, LocalDateTime dateHeureDepart) {}

    /** Prix par passager (FCFA) et détail du calcul, affiché au conducteur pour la transparence. */
    record EstimationPrix(
            BigDecimal prixRecommande, BigDecimal prixMin, BigDecimal prixMax,
            BigDecimal prixCarburantUtilise, BigDecimal consommationUtilisee, boolean consommationEstimee,
            boolean heureDePointe, String versionModele,
            BigDecimal coutCarburant, BigDecimal coutUsure, BigDecimal coutPeages, BigDecimal coutTotal,
            int nombreOccupants) {}
}
