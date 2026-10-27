package sn.isep.Convoiturage.common.geo;

import java.util.ArrayList;
import java.util.List;

/**
 * Encoded Polyline Algorithm Format de Google (précision 1e-5).
 * Utilisé pour décoder l'itinéraire renvoyé par la Routes API et pour envoyer
 * un tracé compact aux applications (Flutter : google_polyline_algorithm).
 */
public final class PolylineCodec {

    private PolylineCodec() {}

    public static List<Coordonnee> decoder(String encoded) {
        List<Coordonnee> points = new ArrayList<>();
        int index = 0, lat = 0, lng = 0;
        while (index < encoded.length()) {
            int[] res = lireValeur(encoded, index);
            lat += res[0];
            index = res[1];
            res = lireValeur(encoded, index);
            lng += res[0];
            index = res[1];
            points.add(new Coordonnee(lat / 1e5, lng / 1e5));
        }
        return points;
    }

    public static String encoder(List<Coordonnee> points) {
        StringBuilder sb = new StringBuilder();
        long prevLat = 0, prevLng = 0;
        for (Coordonnee p : points) {
            long lat = Math.round(p.latitude() * 1e5);
            long lng = Math.round(p.longitude() * 1e5);
            ecrireValeur(lat - prevLat, sb);
            ecrireValeur(lng - prevLng, sb);
            prevLat = lat;
            prevLng = lng;
        }
        return sb.toString();
    }

    private static int[] lireValeur(String s, int index) {
        int result = 0, shift = 0, b;
        do {
            b = s.charAt(index++) - 63;
            result |= (b & 0x1f) << shift;
            shift += 5;
        } while (b >= 0x20);
        int valeur = (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
        return new int[]{valeur, index};
    }

    private static void ecrireValeur(long v, StringBuilder sb) {
        v = v < 0 ? ~(v << 1) : (v << 1);
        while (v >= 0x20) {
            sb.append((char) ((0x20 | (v & 0x1f)) + 63));
            v >>= 5;
        }
        sb.append((char) (v + 63));
    }
}
