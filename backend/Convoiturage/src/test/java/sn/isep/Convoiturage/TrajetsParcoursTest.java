package sn.isep.Convoiturage;

import com.jayway.jsonpath.JsonPath;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.webmvc.test.autoconfigure.AutoConfigureMockMvc;
import org.springframework.context.annotation.Import;
import org.springframework.http.MediaType;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.ResultActions;
import org.springframework.test.web.servlet.request.MockHttpServletRequestBuilder;

import java.time.LocalDate;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

/**
 * Module 03 — parcours des trajets sur la base locale « covoiturage_test » : estimation du prix,
 * publication, recherche géographique, détail, modification et annulation.
 * La validation des documents par l'administrateur (module 07) est simulée directement en base.
 */
@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
@Import({ParcoursCompletTest.BaseDeTestPropre.class, ParcoursCompletTest.CodesDeTest.class})
class TrajetsParcoursTest {

    // Points réels : Dakar (Place de l'Indépendance) -> Thiès ; le passager est à ~1 km de chaque point.
    static final double DAKAR_LAT = 14.6681, DAKAR_LNG = -17.4318;
    static final double THIES_LAT = 14.7910, THIES_LNG = -16.9260;

    @Autowired
    MockMvc mvc;

    @Autowired
    JdbcTemplate jdbc;

    private String dernierRefresh;

    @Test
    void publicationRechercheModificationAnnulation() throws Exception {
        // --- Conductrice : véhicule déclaré -> rôle CONDUCTEUR (porté par le jeton après rafraîchissement)
        String conductrice = inscrire("Awa", "Diop", "awa.trajets@test.sn", "771112233", "FEMME");
        String vehicule = appel(post("/api/moi/vehicules").header("Authorization", "Bearer " + conductrice), """
                {"immatriculation":"DK-5566-TR","marque":"Toyota","modele":"Corolla","annee":2018,"puissanceFiscale":7,
                 "nombrePlaces":5,"typeEnergie":"ESSENCE","consommationReelle":7.0}""")
                .andExpect(status().isCreated())
                .andReturn().getResponse().getContentAsString();
        long idVehicule = ((Number) JsonPath.read(vehicule, "$.id")).longValue();
        conductrice = jeton(appel(post("/api/auth/refresh"), "{\"refreshToken\":\"" + dernierRefresh + "\"}"));

        String date = LocalDate.now().plusDays(3).toString();
        String publication = """
                {"idVehicule":%d,
                 "depart":{"lieu":"Dakar Plateau","latitude":%s,"longitude":%s},
                 "arrivee":{"lieu":"Thiès centre","latitude":%s,"longitude":%s},
                 "dateHeureDepart":"%sT10:00:00","flexibiliteMinutes":20,"nombrePlaces":3,
                 "modeReservation":"MANUELLE","tailleBagage":"MOYEN","femmesUniquement":false}"""
                .formatted(idVehicule, DAKAR_LAT, DAKAR_LNG, THIES_LAT, THIES_LNG, date);

        // Publication refusée tant que les documents ne sont pas validés
        appel(post("/api/trajets").header("Authorization", "Bearer " + conductrice), publication)
                .andExpect(status().isForbidden());

        // Validation par l'administrateur (module 07, pas encore disponible) : simulée en base.
        jdbc.update("update vehicule set statut_validation = 'VALIDE' where id_vehicule = ?", idVehicule);
        jdbc.update("update utilisateur set conducteur_valide = true where email = 'awa.trajets@test.sn'");

        // --- Estimation : itinéraire + prix (formule seule en profil test)
        appel(post("/api/trajets/estimation").header("Authorization", "Bearer " + conductrice), """
                {"idVehicule":%d,"depart":{"lieu":"Dakar","latitude":%s,"longitude":%s},
                 "arrivee":{"lieu":"Thiès","latitude":%s,"longitude":%s},"dateHeureDepart":"%sT10:00:00","nombrePlaces":3}"""
                .formatted(idVehicule, DAKAR_LAT, DAKAR_LNG, THIES_LAT, THIES_LNG, date))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.distanceKm").isNumber())
                .andExpect(jsonPath("$.itinerairePolyline").isString())
                .andExpect(jsonPath("$.tarif.prixRecommande").isNumber())
                .andExpect(jsonPath("$.tarif.sourceConsommation").value("REELLE"))
                .andExpect(jsonPath("$.tarif.versionModele").value("FORMULE-1.0"));

        // --- Route choisie par le conducteur : autoroute avec péages saisis, nationale sans péage
        String estimation = """
                {"idVehicule":%d,"depart":{"lieu":"Dakar","latitude":%s,"longitude":%s},
                 "arrivee":{"lieu":"Thiès","latitude":%s,"longitude":%s},"dateHeureDepart":"%sT10:00:00","nombrePlaces":3,
                 "typeRoute":"%s","montantPeages":3000}""";
        String autoroute = appel(post("/api/trajets/estimation").header("Authorization", "Bearer " + conductrice),
                estimation.formatted(idVehicule, DAKAR_LAT, DAKAR_LNG, THIES_LAT, THIES_LNG, date, "AUTOROUTE"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.typeRoute").value("AUTOROUTE"))
                .andExpect(jsonPath("$.montantPeages").value(3000))
                .andExpect(jsonPath("$.tarif.coutPeages").value(3000))
                .andReturn().getResponse().getContentAsString();
        String nationale = appel(post("/api/trajets/estimation").header("Authorization", "Bearer " + conductrice),
                estimation.formatted(idVehicule, DAKAR_LAT, DAKAR_LNG, THIES_LAT, THIES_LNG, date, "NATIONALE"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.typeRoute").value("NATIONALE"))
                .andExpect(jsonPath("$.montantPeages").value(0))
                .andReturn().getResponse().getContentAsString();
        org.assertj.core.api.Assertions.assertThat(((Number) JsonPath.read(autoroute, "$.tarif.coutTotal")).doubleValue())
                .isGreaterThan(((Number) JsonPath.read(nationale, "$.tarif.coutTotal")).doubleValue());
        appel(post("/api/trajets/estimation").header("Authorization", "Bearer " + conductrice),
                estimation.formatted(idVehicule, DAKAR_LAT, DAKAR_LNG, THIES_LAT, THIES_LNG, date, "VILLE"))
                .andExpect(status().isBadRequest());

        // --- Publication
        String trajet = appel(post("/api/trajets").header("Authorization", "Bearer " + conductrice), publication)
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.statut").value("PUBLIE"))
                .andExpect(jsonPath("$.vehicule.marque").value("Toyota"))
                .andExpect(jsonPath("$.tarification.prixMin").isNumber())
                .andReturn().getResponse().getContentAsString();
        long idTrajet = ((Number) JsonPath.read(trajet, "$.id")).longValue();
        double prix = ((Number) JsonPath.read(trajet, "$.prixParPlace")).doubleValue();

        // Prix hors de la fourchette proposée : refusé
        appel(put("/api/trajets/" + idTrajet).header("Authorization", "Bearer " + conductrice), "{\"prixParPlace\":1}")
                .andExpect(status().isBadRequest());

        // --- Recherche (publique) d'un passager à ~1 km du départ et de l'arrivée
        String passager = inscrire("Moussa", "Ndiaye", "moussa.trajets@test.sn", "781112233", "HOMME");
        String recherche = "/api/trajets/recherche?latDepart=%s&lngDepart=%s&latArrivee=%s&lngArrivee=%s&date=%s&places=2"
                .formatted(DAKAR_LAT + 0.008, DAKAR_LNG + 0.004, THIES_LAT - 0.005, THIES_LNG, date);
        mvc.perform(get(recherche)).andExpect(status().isOk())
                .andExpect(jsonPath("$.length()").value(1))
                .andExpect(jsonPath("$[0].id").value(idTrajet))
                .andExpect(jsonPath("$[0].correspondance.distanceRamassageM").isNumber())
                .andExpect(jsonPath("$[0].tarification").doesNotExist());
        // Sens inverse, prix maximum trop bas, trop de places : aucun résultat
        mvc.perform(get("/api/trajets/recherche?latDepart=%s&lngDepart=%s&latArrivee=%s&lngArrivee=%s&date=%s"
                        .formatted(THIES_LAT, THIES_LNG, DAKAR_LAT, DAKAR_LNG, date)))
                .andExpect(jsonPath("$.length()").value(0));
        mvc.perform(get(recherche + "&prixMax=" + (prix - 1))).andExpect(jsonPath("$.length()").value(0));
        mvc.perform(get(recherche.replace("places=2", "places=4"))).andExpect(jsonPath("$.length()").value(0));

        // --- Détail public ; le détail de la tarification est réservé au conducteur
        mvc.perform(get("/api/trajets/" + idTrajet)).andExpect(status().isOk())
                .andExpect(jsonPath("$.depart.lieu").value("Dakar Plateau"))
                .andExpect(jsonPath("$.tarification").doesNotExist());

        // Un passager ne peut ni publier ni modifier
        appel(post("/api/trajets").header("Authorization", "Bearer " + passager), publication)
                .andExpect(status().isForbidden());
        appel(put("/api/trajets/" + idTrajet).header("Authorization", "Bearer " + passager), "{\"nombrePlaces\":2}")
                .andExpect(status().isForbidden());

        // --- Modification puis « mes trajets »
        appel(put("/api/trajets/" + idTrajet).header("Authorization", "Bearer " + conductrice), "{\"nombrePlaces\":2}")
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.nombrePlacesDisponibles").value(2));
        mvc.perform(get("/api/moi/trajets").header("Authorization", "Bearer " + conductrice))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.length()").value(1));

        // --- Annulation : le trajet disparaît de la recherche
        appel(post("/api/trajets/" + idTrajet + "/annuler").header("Authorization", "Bearer " + conductrice),
                "{\"motif\":\"Imprévu\"}")
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.statut").value("ANNULE"));
        mvc.perform(get(recherche)).andExpect(jsonPath("$.length()").value(0));
    }

    // ------------------------------------------------------------------ utilitaires

    private String inscrire(String prenom, String nom, String email, String tel, String sexe) throws Exception {
        String ancien = ParcoursCompletTest.CodesDeTest.DERNIER_CODE.get(email);
        appel(post("/api/auth/inscription"), """
                {"prenom":"%s","nom":"%s","email":"%s","telephone":"%s","motDePasse":"MotDePasse2026","sexe":"%s"}"""
                .formatted(prenom, nom, email, tel, sexe))
                .andExpect(status().isCreated());
        String code = ParcoursCompletTest.CodesDeTest.attendreNouveauCode(email, ancien);
        return jeton(appel(post("/api/auth/otp/verifier"), "{\"identifiant\":\"" + tel + "\",\"code\":\"" + code + "\"}"));
    }

    private ResultActions appel(MockHttpServletRequestBuilder req, String json) throws Exception {
        return mvc.perform(req.contentType(MediaType.APPLICATION_JSON).content(json));
    }

    private String jeton(ResultActions r) throws Exception {
        String body = r.andExpect(status().isOk()).andReturn().getResponse().getContentAsString();
        dernierRefresh = JsonPath.read(body, "$.refreshToken");
        return JsonPath.read(body, "$.accessToken");
    }
}
