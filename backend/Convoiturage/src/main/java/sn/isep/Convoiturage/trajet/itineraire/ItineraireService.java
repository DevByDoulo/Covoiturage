package sn.isep.Convoiturage.trajet.itineraire;

import sn.isep.Convoiturage.common.geo.Coordonnee;
import sn.isep.Convoiturage.trajet.TypeRoute;

import java.math.BigDecimal;
import java.util.List;

/** Calcul d'itinéraire routier entre un départ, des escales et une arrivée. */
public interface ItineraireService {

    /** @param points départ, escales dans l'ordre, arrivée (au moins 2 points) */
    Itineraire calculer(List<Coordonnee> points);

    record Itineraire(double distanceKm, int dureeMin, BigDecimal montantPeages, TypeRoute typeRoute,
                      int deniveleM, List<Coordonnee> trace, String source) {}

    /** Type de route déduit de la vitesse moyenne prévue. */
    static TypeRoute typeRouteDepuisVitesse(double distanceKm, int dureeMin) {
        double vitesse = distanceKm / Math.max(dureeMin, 1) * 60.0;
        if (vitesse >= 75) return TypeRoute.AUTOROUTE;
        if (vitesse >= 50) return TypeRoute.NATIONALE;
        if (vitesse < 30) return TypeRoute.VILLE;
        return TypeRoute.MIXTE;
    }
}
