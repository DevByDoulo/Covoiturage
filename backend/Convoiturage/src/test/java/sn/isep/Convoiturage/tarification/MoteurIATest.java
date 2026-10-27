package sn.isep.Convoiturage.tarification;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.test.web.client.MockRestServiceServer;
import org.springframework.web.client.RestClient;
import sn.isep.Convoiturage.tarification.MoteurTarification.EstimationPrix;
import sn.isep.Convoiturage.tarification.MoteurTarification.SourceConsommation;
import sn.isep.Convoiturage.trajet.TypeRoute;
import sn.isep.Convoiturage.vehicule.TypeEnergie;

import java.math.BigDecimal;
import java.time.Clock;
import java.time.Instant;
import java.time.LocalDateTime;
import java.time.ZoneOffset;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.client.match.MockRestRequestMatchers.*;
import static org.springframework.test.web.client.response.MockRestResponseCreators.withStatus;
import static org.springframework.test.web.client.response.MockRestResponseCreators.withSuccess;

/** Appel du service ia-tarification simulé (MockRestServiceServer) : succès, erreurs et repli sur la formule. */
class MoteurIATest {

    private static final LocalDateTime SAMEDI_MATIN = LocalDateTime.of(2026, 11, 7, 10, 0);
    private static final String REPONSE_IA = """
            {"consommation": 7.0, "unite": "L/100km", "marqueConnue": true, "facteurAge": 1.0,
             "meteo": {"facteur": 1.064, "source": "OPEN_METEO", "temperatureC": 34.0, "precipitationMm": 0.0, "ventKmh": 12.0},
             "versionModele": "xgb-ademe-2026-10-27"}""";

    private final MoteurFormule formule = new MoteurFormule(CleParametre::defaut);
    private MockRestServiceServer serveur;
    private HorlogeReglable horloge;
    private MoteurIA moteur;

    @BeforeEach
    void preparer() {
        RestClient.Builder builder = RestClient.builder().baseUrl("http://ia.test");
        serveur = MockRestServiceServer.bindTo(builder).build();
        horloge = new HorlogeReglable(Instant.parse("2026-11-07T10:00:00Z"));
        moteur = new MoteurIA(builder.build(), formule, horloge);
    }

    /** Toyota essence 7 CV de 2018, aucune consommation déclarée, Dakar -> Thiès (~70 km). */
    private static MoteurTarification.DemandeEstimation demande() {
        return new MoteurTarification.DemandeEstimation("Toyota", TypeEnergie.ESSENCE, 7, 2018, null, null,
                new BigDecimal("25"), 70, 0, TypeRoute.NATIONALE, BigDecimal.ZERO, 3, SAMEDI_MATIN, 14.6928, -17.4467);
    }

    @Test
    void utiliseLaConsommationEtLaMeteoDuServiceIA() {
        serveur.expect(requestTo("http://ia.test/v1/estimations"))
                .andExpect(method(org.springframework.http.HttpMethod.POST))
                .andExpect(jsonPath("$.marque").value("Toyota"))
                .andExpect(jsonPath("$.typeEnergie").value("ESSENCE"))
                .andExpect(jsonPath("$.puissanceFiscale").value(7))
                .andExpect(jsonPath("$.annee").value(2018))
                .andExpect(jsonPath("$.latitude").value(14.6928))
                .andExpect(jsonPath("$.dateHeureDepart").value("2026-11-07T10:00:00"))
                .andRespond(withSuccess(REPONSE_IA, MediaType.APPLICATION_JSON));

        EstimationPrix e = moteur.estimer(demande());

        serveur.verify();
        assertThat(e.sourceConsommation()).isEqualTo(SourceConsommation.IA);
        assertThat(e.consommationUtilisee()).isEqualByComparingTo("7.00");
        assertThat(e.facteurMeteo()).isEqualByComparingTo("1.064");
        assertThat(e.coutCarburant()).isEqualByComparingTo("5161.46"); // 70 × 7/100 × 990 × 1,064
        assertThat(e.versionModele()).isEqualTo("xgb-ademe-2026-10-27+FORMULE-1.0");
    }

    @Test
    void sReplieSurLaFormuleSiLeServiceEstEnPanne() {
        serveur.expect(requestTo("http://ia.test/v1/estimations")).andRespond(withStatus(HttpStatus.SERVICE_UNAVAILABLE));

        EstimationPrix e = moteur.estimer(demande());

        assertThat(e).isEqualTo(formule.estimer(demande()));
        assertThat(e.sourceConsommation()).isEqualTo(SourceConsommation.FORMULE);
        assertThat(e.versionModele()).isEqualTo(MoteurFormule.VERSION);
    }

    @Test
    void sReplieSurLaFormuleSiLaReponseEstIncoherente() {
        serveur.expect(requestTo("http://ia.test/v1/estimations"))
                .andRespond(withSuccess("""
                        {"consommation": -3, "meteo": {"facteur": 1.0}, "versionModele": "x"}""", MediaType.APPLICATION_JSON));

        assertThat(moteur.estimer(demande()).sourceConsommation()).isEqualTo(SourceConsommation.FORMULE);
    }

    @Test
    void neSollicitePlusLeServicePendantUnePauseApresUnEchec() {
        serveur.expect(requestTo("http://ia.test/v1/estimations")).andRespond(withStatus(HttpStatus.BAD_GATEWAY));
        moteur.estimer(demande());

        // Pendant la pause : aucun appel (le serveur simulé échouerait sur une requête inattendue).
        horloge.avancer(MoteurIA.PAUSE_APRES_ECHEC.minusSeconds(1).toSeconds());
        assertThat(moteur.estimer(demande()).sourceConsommation()).isEqualTo(SourceConsommation.FORMULE);
        serveur.verify();

        // Après la pause : le service est de nouveau interrogé.
        serveur.reset();
        serveur.expect(requestTo("http://ia.test/v1/estimations")).andRespond(withSuccess(REPONSE_IA, MediaType.APPLICATION_JSON));
        horloge.avancer(2);
        assertThat(moteur.estimer(demande()).sourceConsommation()).isEqualTo(SourceConsommation.IA);
        serveur.verify();
    }

    static final class HorlogeReglable extends Clock {
        private Instant maintenant;

        HorlogeReglable(Instant depart) { this.maintenant = depart; }

        void avancer(long secondes) { maintenant = maintenant.plusSeconds(secondes); }

        @Override public Instant instant() { return maintenant; }
        @Override public ZoneOffset getZone() { return ZoneOffset.UTC; }
        @Override public Clock withZone(java.time.ZoneId zone) { return this; }
    }
}
