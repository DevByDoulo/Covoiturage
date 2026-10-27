package sn.isep.Convoiturage.tarification;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.MediaType;
import org.springframework.web.client.RestClient;
import sn.isep.Convoiturage.tarification.MoteurFormule.ApportIA;

import java.math.BigDecimal;
import java.time.Clock;
import java.time.Duration;
import java.time.Instant;
import java.time.LocalDateTime;

/**
 * Prix assisté par l'IA : le service ia-tarification (FastAPI) prédit la consommation du véhicule
 * (XGBoost entraîné sur les données ADEME) et un facteur météo (Open-Meteo) ; {@link MoteurFormule}
 * calcule ensuite le prix en FCFA avec les coefficients de l'administrateur.
 * <p>
 * Le service IA ne bloque jamais une publication : en cas d'erreur ou de délai dépassé, le prix est
 * calculé par la formule seule, et le service n'est plus sollicité pendant {@link #PAUSE_APRES_ECHEC}.
 */
@Slf4j
public class MoteurIA implements MoteurTarification {

    static final Duration PAUSE_APRES_ECHEC = Duration.ofSeconds(30);
    /** Taille de la colonne tarification.version_modele. */
    private static final int LONGUEUR_VERSION_MAX = 40;

    private final RestClient client;
    private final MoteurFormule formule;
    private final Clock horloge;
    private volatile Instant pauseJusqua = Instant.MIN;

    public MoteurIA(RestClient client, MoteurFormule formule, Clock horloge) {
        this.client = client;
        this.formule = formule;
        this.horloge = horloge;
    }

    record Requete(String marque, String typeEnergie, int puissanceFiscale, Integer annee,
                   double latitude, double longitude, LocalDateTime dateHeureDepart) {}

    @JsonIgnoreProperties(ignoreUnknown = true)
    record Meteo(double facteur, String source) {}

    @JsonIgnoreProperties(ignoreUnknown = true)
    record Reponse(BigDecimal consommation, Meteo meteo, String versionModele) {}

    @Override
    public EstimationPrix estimer(DemandeEstimation d) {
        return formule.estimer(d, interroger(d));
    }

    /** Apport de l'IA, ou null si le service est indisponible (repli sur la formule seule). */
    private ApportIA interroger(DemandeEstimation d) {
        Instant maintenant = horloge.instant();
        if (maintenant.isBefore(pauseJusqua)) return null;
        try {
            Reponse r = client.post().uri("/v1/estimations")
                    .contentType(MediaType.APPLICATION_JSON)
                    .body(new Requete(d.marque(), d.typeEnergie().name(), d.puissanceFiscale(),
                            d.anneeVehicule() > 0 ? d.anneeVehicule() : null,
                            d.latitudeDepart(), d.longitudeDepart(), d.dateHeureDepart()))
                    .retrieve()
                    .body(Reponse.class);
            if (r == null || r.consommation() == null || r.consommation().signum() <= 0
                    || r.meteo() == null || r.meteo().facteur() < 1 || r.meteo().facteur() > 1.5) {
                throw new IllegalStateException("réponse incohérente : " + r);
            }
            return new ApportIA(r.consommation(), r.meteo().facteur(), version(r.versionModele()));
        } catch (RuntimeException e) {
            pauseJusqua = maintenant.plus(PAUSE_APRES_ECHEC);
            log.warn("Service IA de tarification indisponible ({}), prix calculé par la formule seule pendant {} s",
                    e.getMessage(), PAUSE_APRES_ECHEC.toSeconds());
            return null;
        }
    }

    private static String version(String versionModele) {
        String v = versionModele == null || versionModele.isBlank() ? "IA" : versionModele;
        int max = LONGUEUR_VERSION_MAX - MoteurFormule.VERSION.length() - 1;
        return v.length() > max ? v.substring(0, max) : v;
    }
}
