package sn.isep.Convoiturage.trajet.itineraire;

import lombok.extern.slf4j.Slf4j;
import org.springframework.http.MediaType;
import org.springframework.web.client.RestClient;
import sn.isep.Convoiturage.common.geo.Coordonnee;
import sn.isep.Convoiturage.common.geo.PolylineCodec;

import java.math.BigDecimal;
import java.util.List;
import java.util.Map;

/**
 * Google Maps Routes API (computeRoutes) : distance, durée, tracé et péages.
 * En cas d'erreur, repli sur l'estimation à vol d'oiseau pour ne pas bloquer la publication.
 */
@Slf4j
public class ItineraireGoogle implements ItineraireService {

    private static final String FIELD_MASK =
            "routes.distanceMeters,routes.duration,routes.polyline.encodedPolyline,routes.travelAdvisory.tollInfo";

    private final RestClient client;
    private final ItineraireService repli;

    public ItineraireGoogle(RestClient.Builder builder, String apiKey, ItineraireService repli) {
        this.client = builder.baseUrl("https://routes.googleapis.com")
                .defaultHeader("X-Goog-Api-Key", apiKey)
                .defaultHeader("X-Goog-FieldMask", FIELD_MASK)
                .build();
        this.repli = repli;
    }

    record LatLng(double latitude, double longitude) {}
    record Location(LatLng latLng) {}
    record Waypoint(Location location) {
        static Waypoint de(Coordonnee c) { return new Waypoint(new Location(new LatLng(c.latitude(), c.longitude()))); }
    }
    record Money(String currencyCode, String units, Integer nanos) {}
    record TollInfo(List<Money> estimatedPrice) {}
    record TravelAdvisory(TollInfo tollInfo) {}
    record Polyline(String encodedPolyline) {}
    record Route(Integer distanceMeters, String duration, Polyline polyline, TravelAdvisory travelAdvisory) {}
    record RoutesResponse(List<Route> routes) {}

    @Override
    public Itineraire calculer(List<Coordonnee> points) {
        try {
            Map<String, Object> corps = Map.of(
                    "origin", Waypoint.de(points.getFirst()),
                    "destination", Waypoint.de(points.getLast()),
                    "intermediates", points.subList(1, points.size() - 1).stream().map(Waypoint::de).toList(),
                    "travelMode", "DRIVE",
                    "routingPreference", "TRAFFIC_AWARE",
                    "extraComputations", List.of("TOLLS"),
                    "languageCode", "fr",
                    "units", "METRIC");
            RoutesResponse rep = client.post().uri("/directions/v2:computeRoutes")
                    .contentType(MediaType.APPLICATION_JSON)
                    .body(corps)
                    .retrieve()
                    .body(RoutesResponse.class);
            if (rep == null || rep.routes() == null || rep.routes().isEmpty()) {
                log.warn("Routes API : aucun itinéraire trouvé, repli sur l'estimation");
                return repli.calculer(points);
            }
            Route r = rep.routes().getFirst();
            double km = r.distanceMeters() / 1000.0;
            int minutes = (int) Math.ceil(Double.parseDouble(r.duration().replace("s", "")) / 60.0);
            List<Coordonnee> trace = PolylineCodec.decoder(r.polyline().encodedPolyline());
            if (trace.size() < 2) trace = points;
            return new Itineraire(Math.round(km * 100) / 100.0, minutes, peagesEnFcfa(r.travelAdvisory()),
                    ItineraireService.typeRouteDepuisVitesse(km, minutes), 0, trace, "GOOGLE");
        } catch (RuntimeException e) {
            log.warn("Routes API indisponible ({}), repli sur l'estimation", e.getMessage());
            return repli.calculer(points);
        }
    }

    private static BigDecimal peagesEnFcfa(TravelAdvisory advisory) {
        if (advisory == null || advisory.tollInfo() == null || advisory.tollInfo().estimatedPrice() == null) return BigDecimal.ZERO;
        return advisory.tollInfo().estimatedPrice().stream()
                .filter(m -> "XOF".equals(m.currencyCode()) && m.units() != null)
                .map(m -> new BigDecimal(m.units()))
                .findFirst()
                .orElse(BigDecimal.ZERO);
    }
}
