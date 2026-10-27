package sn.isep.Convoiturage.common.geo;

import org.locationtech.jts.geom.Coordinate;
import org.locationtech.jts.geom.GeometryFactory;
import org.locationtech.jts.geom.LineString;
import org.locationtech.jts.geom.PrecisionModel;

import java.util.Arrays;
import java.util.List;

/** Conversions JTS <-> coordonnées. Attention : JTS/PostGIS utilisent l'ordre (x=longitude, y=latitude). */
public final class GeoUtils {

    public static final int SRID_WGS84 = 4326;
    private static final GeometryFactory FACTORY = new GeometryFactory(new PrecisionModel(), SRID_WGS84);
    private static final double RAYON_TERRE_KM = 6371.0088;

    private GeoUtils() {}

    public static LineString lineString(List<Coordonnee> points) {
        if (points.size() < 2) throw new IllegalArgumentException("Un itinéraire nécessite au moins deux points");
        Coordinate[] coords = points.stream()
                .map(p -> new Coordinate(p.longitude(), p.latitude()))
                .toArray(Coordinate[]::new);
        return FACTORY.createLineString(coords);
    }

    public static List<Coordonnee> coordonnees(LineString line) {
        return Arrays.stream(line.getCoordinates()).map(c -> new Coordonnee(c.y, c.x)).toList();
    }

    /** Distance orthodromique (formule de haversine), en km. */
    public static double distanceKm(Coordonnee a, Coordonnee b) {
        double dLat = Math.toRadians(b.latitude() - a.latitude());
        double dLon = Math.toRadians(b.longitude() - a.longitude());
        double h = Math.pow(Math.sin(dLat / 2), 2)
                + Math.cos(Math.toRadians(a.latitude())) * Math.cos(Math.toRadians(b.latitude())) * Math.pow(Math.sin(dLon / 2), 2);
        return 2 * RAYON_TERRE_KM * Math.asin(Math.sqrt(h));
    }
}
