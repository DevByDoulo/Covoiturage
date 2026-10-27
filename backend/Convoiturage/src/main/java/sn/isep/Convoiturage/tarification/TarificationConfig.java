package sn.isep.Convoiturage.tarification;

import lombok.extern.slf4j.Slf4j;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.context.annotation.Primary;
import org.springframework.http.client.SimpleClientHttpRequestFactory;
import org.springframework.web.client.RestClient;
import sn.isep.Convoiturage.common.AppProperties;

import java.time.Clock;
import java.time.Duration;

/** Moteur de prix utilisé par les trajets : IA si le service ia-tarification est configuré, sinon formule seule. */
@Slf4j
@Configuration
public class TarificationConfig {

    @Bean
    @Primary
    MoteurTarification moteurTarification(AppProperties props, RestClient.Builder builder, MoteurFormule formule) {
        AppProperties.Ia ia = props.ia();
        if (ia == null || ia.url() == null || ia.url().isBlank()) {
            log.warn("IA_TARIFICATION_URL absente : prix calculés par la formule seule");
            return formule;
        }
        Duration delai = ia.delai() != null ? ia.delai() : Duration.ofSeconds(2);
        SimpleClientHttpRequestFactory http = new SimpleClientHttpRequestFactory();
        http.setConnectTimeout(delai);
        http.setReadTimeout(delai);
        log.info("Tarification assistée par l'IA : {} (délai {} ms, repli sur la formule)", ia.url(), delai.toMillis());
        return new MoteurIA(builder.baseUrl(ia.url()).requestFactory(http).build(), formule, Clock.systemUTC());
    }
}
