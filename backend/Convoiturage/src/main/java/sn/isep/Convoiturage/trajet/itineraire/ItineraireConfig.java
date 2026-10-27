package sn.isep.Convoiturage.trajet.itineraire;

import lombok.extern.slf4j.Slf4j;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.client.RestClient;
import sn.isep.Convoiturage.common.AppProperties;

@Slf4j
@Configuration
public class ItineraireConfig {

    @Bean
    ItineraireService itineraireService(AppProperties props, RestClient.Builder builder) {
        String cle = props.google().mapsApiKey();
        ItineraireService estimation = new ItineraireVolOiseau();
        if (cle == null || cle.isBlank()) {
            log.warn("GOOGLE_MAPS_API_KEY absente : distances estimées à vol d'oiseau (×1,25)");
            return estimation;
        }
        return new ItineraireGoogle(builder, cle, estimation);
    }
}
