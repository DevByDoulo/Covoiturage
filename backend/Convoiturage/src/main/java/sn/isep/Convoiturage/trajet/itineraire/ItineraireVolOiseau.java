package sn.isep.Convoiturage.trajet.itineraire;

import sn.isep.Convoiturage.common.geo.Coordonnee;
import sn.isep.Convoiturage.common.geo.GeoUtils;
import sn.isep.Convoiturage.trajet.TypeRoute;

import java.math.BigDecimal;
import java.util.List;

/**
 * Estimation hors ligne (sans clé Google ou en cas de panne) : distance à vol d'oiseau
 * corrigée d'un coefficient de sinuosité, vitesse moyenne selon la longueur du trajet.
 */
public class ItineraireVolOiseau implements ItineraireService {

    private static final double SINUOSITE = 1.25;

    @Override
    public Itineraire calculer(List<Coordonnee> points) {
        double km = 0;
        for (int i = 1; i < points.size(); i++) km += GeoUtils.distanceKm(points.get(i - 1), points.get(i));
        km = Math.max(0.5, km * SINUOSITE);
        TypeRoute type = km < 25 ? TypeRoute.VILLE : km < 60 ? TypeRoute.MIXTE : TypeRoute.NATIONALE;
        double vitesse = switch (type) {
            case VILLE -> 25;
            case MIXTE -> 45;
            default -> 65;
        };
        int duree = (int) Math.ceil(km / vitesse * 60) + 5 * (points.size() - 2);
        return new Itineraire(Math.round(km * 100) / 100.0, duree, BigDecimal.ZERO, type, 0, points, "ESTIMATION");
    }
}
