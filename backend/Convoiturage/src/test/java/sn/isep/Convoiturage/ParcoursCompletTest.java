package sn.isep.Convoiturage;

import com.jayway.jsonpath.JsonPath;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.flyway.autoconfigure.FlywayMigrationStrategy;
import org.springframework.boot.test.context.TestConfiguration;
import org.springframework.boot.webmvc.test.autoconfigure.AutoConfigureMockMvc;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Primary;
import org.springframework.http.MediaType;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.mock.web.MockMultipartFile;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.ResultActions;
import org.springframework.test.web.servlet.request.MockHttpServletRequestBuilder;
import sn.isep.Convoiturage.auth.EmailSender;
import sn.isep.Convoiturage.auth.SmsSender;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.concurrent.ConcurrentHashMap;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

/**
 * Parcours de bout en bout du lot 1 sur la base PostgreSQL/PostGIS locale « covoiturage_test »
 * (créée par db/init-local.sql). Les données sont effacées au démarrage de chaque exécution.
 */
@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
class ParcoursCompletTest {

    /**
     * Avant que l'application ne démarre : schéma à jour (Flyway), puis tables vidées, sauf l'historique
     * Flyway, la table de PostGIS et les coefficients de prix insérés par la migration.
     */
    @TestConfiguration
    static class BaseDeTestPropre {
        private static final Set<String> CONSERVEES = Set.of("flyway_schema_history", "spatial_ref_sys", "parametre_tarification");

        @Bean
        FlywayMigrationStrategy migrerPuisVider() {
            return flyway -> {
                flyway.migrate();
                JdbcTemplate jdbc = new JdbcTemplate(flyway.getConfiguration().getDataSource());
                List<String> tables = jdbc.queryForList(
                                "select tablename from pg_tables where schemaname = 'public'", String.class)
                        .stream().filter(t -> !CONSERVEES.contains(t)).toList();
                if (!tables.isEmpty()) jdbc.execute("TRUNCATE " + String.join(", ", tables) + " RESTART IDENTITY CASCADE");
            };
        }
    }

    /** Capture des codes envoyés, par destinataire (email, ou numéro pour les envois par SMS). */
    @TestConfiguration
    static class CodesDeTest {
        static final Map<String, String> DERNIER_CODE = new ConcurrentHashMap<>();
        private static final Pattern CODE = Pattern.compile("est (\\d{6})");

        private static void capturer(String destinataire, String message) {
            Matcher m = CODE.matcher(message);
            if (m.find()) DERNIER_CODE.put(destinataire, m.group(1));
        }

        /**
         * Les emails partent en arrière-plan après la réponse HTTP : on attend qu'un code différent
         * de {@code ancien} soit arrivé pour ce destinataire (5 secondes au plus).
         */
        static String attendreNouveauCode(String destinataire, String ancien) throws InterruptedException {
            for (int i = 0; i < 100; i++) {
                String code = DERNIER_CODE.get(destinataire);
                if (code != null && !code.equals(ancien)) return code;
                Thread.sleep(50);
            }
            throw new AssertionError("Aucun nouveau code reçu pour " + destinataire);
        }

        @Bean
        @Primary
        SmsSender smsCapture() {
            return CodesDeTest::capturer;
        }

        @Bean
        @Primary
        EmailSender emailCapture() {
            return new EmailSender() {
                @Override public boolean disponible() { return true; }
                @Override public void envoyer(String email, String sujet, String texte) { capturer(email, texte); }
            };
        }
    }

    @Autowired
    MockMvc mvc;

    // Points réels : Dakar (Place de l'Indépendance) -> Thiès ; le passager est à ~1 km de chaque point.
    static final double DAKAR_LAT = 14.6681, DAKAR_LNG = -17.4318;
    static final double THIES_LAT = 14.7910, THIES_LNG = -16.9260;

    @Test
    void parcoursConducteurPassagerAdmin() throws Exception {
        String admin = jeton(appel(post("/api/auth/connexion"), """
                {"identifiant":"admin@test.local","motDePasse":"Admin-Test-2026!"}""").andExpect(status().isOk()));

        // --- Conductrice : inscription + OTP
        String conductrice = inscrire("Awa", "Diop", "awa@test.sn", "771111111", "FEMME");

        // Mauvais mot de passe / mauvais OTP
        appel(post("/api/auth/connexion"), """
                {"identifiant":"awa@test.sn","motDePasse":"mauvais123"}""").andExpect(status().isUnauthorized());

        // --- Déclaration du véhicule -> rôle CONDUCTEUR (visible après rafraîchissement du jeton)
        String vehicule = appel(post("/api/moi/vehicules").header("Authorization", "Bearer " + conductrice), """
                {"immatriculation":"dk 1234 ab","marque":"Toyota","modele":"Corolla","annee":2018,"puissanceFiscale":7,
                 "nombrePlaces":5,"typeEnergie":"ESSENCE","consommationReelle":7.0}""")
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.immatriculation").value("DK-1234-AB"))
                .andExpect(jsonPath("$.statutValidation").value("EN_ATTENTE"))
                .andReturn().getResponse().getContentAsString();
        long idVehicule = ((Number) JsonPath.read(vehicule, "$.id")).longValue();
        conductrice = jeton(appel(post("/api/auth/refresh"), "{\"refreshToken\":\"" + dernierRefresh + "\"}"));

        String publication = """
                {"idVehicule":%d,
                 "depart":{"lieu":"Dakar Plateau","latitude":%s,"longitude":%s},
                 "arrivee":{"lieu":"Thiès centre","latitude":%s,"longitude":%s},
                 "dateHeureDepart":"%s","flexibiliteMinutes":20,"nombrePlaces":3,
                 "modeReservation":"MANUELLE","tailleBagage":"MOYEN","femmesUniquement":false}"""
                .formatted(idVehicule, DAKAR_LAT, DAKAR_LNG, THIES_LAT, THIES_LNG, depart());

        // Publication refusée tant que les documents ne sont pas validés
        appel(post("/api/trajets").header("Authorization", "Bearer " + conductrice), publication)
                .andExpect(status().isForbidden());

        // --- Documents
        byte[] png = {(byte) 0x89, 'P', 'N', 'G', 0x0D, 0x0A, 0x1A, 0x0A, 0, 0, 0, 0};
        byte[] pdf = "%PDF-1.4 carte grise".getBytes();
        mvc.perform(multipart("/api/moi/documents").file(new MockMultipartFile("fichier", "permis.png", "image/png", png))
                        .param("type", "PERMIS_CONDUIRE").header("Authorization", "Bearer " + conductrice))
                .andExpect(status().isCreated());
        mvc.perform(multipart("/api/moi/documents").file(new MockMultipartFile("fichier", "cg.pdf", "application/pdf", pdf))
                        .param("type", "CARTE_GRISE").param("idVehicule", String.valueOf(idVehicule))
                        .header("Authorization", "Bearer " + conductrice))
                .andExpect(status().isCreated());
        // Un faux PDF (contenu texte) est rejeté
        mvc.perform(multipart("/api/moi/documents").file(new MockMultipartFile("fichier", "x.pdf", "application/pdf", "hello".getBytes()))
                        .param("type", "PERMIS_CONDUIRE").header("Authorization", "Bearer " + conductrice))
                .andExpect(status().isBadRequest());

        // Un non-admin n'accède pas au back-office
        mvc.perform(get("/api/admin/documents").header("Authorization", "Bearer " + conductrice)).andExpect(status().isForbidden());

        // --- L'administrateur valide la file
        String file = mvc.perform(get("/api/admin/documents").header("Authorization", "Bearer " + admin))
                .andExpect(status().isOk()).andExpect(jsonPath("$.page.totalElements").value(2))
                .andReturn().getResponse().getContentAsString();
        for (Object id : JsonPath.<java.util.List<Object>>read(file, "$.content[*].document.id")) {
            mvc.perform(post("/api/admin/documents/" + id + "/valider").header("Authorization", "Bearer " + admin))
                    .andExpect(status().isOk()).andExpect(jsonPath("$.statutValidation").value("VALIDE"));
        }
        mvc.perform(get("/api/moi").header("Authorization", "Bearer " + conductrice))
                .andExpect(jsonPath("$.conducteurValide").value(true));

        // --- Passager : recherche infructueuse, puis alertes de recherche (F5)
        String passager = inscrire("Moussa", "Ndiaye", "moussa@test.sn", "781234567", "HOMME");
        String date = LocalDate.now().plusDays(3).toString();
        String recherche = "/api/trajets/recherche?latDepart=%s&lngDepart=%s&latArrivee=%s&lngArrivee=%s&date=%s&places=2"
                .formatted(DAKAR_LAT + 0.008, DAKAR_LNG + 0.004, THIES_LAT - 0.005, THIES_LNG, date);
        mvc.perform(get(recherche)).andExpect(jsonPath("$.length()").value(0));
        String alerte = """
                {"depart":{"lieu":"%s","latitude":%s,"longitude":%s},"arrivee":{"lieu":"%s","latitude":%s,"longitude":%s},
                 "date":"%s","rayonKm":5%s}""";
        // Correspond au futur trajet :
        appel(post("/api/moi/alertes").header("Authorization", "Bearer " + passager),
                alerte.formatted("Dakar", DAKAR_LAT + 0.008, DAKAR_LNG + 0.004, "Thiès", THIES_LAT - 0.005, THIES_LNG, date, ""))
                .andExpect(status().isCreated());
        // Ne correspondent pas : sens inverse, prix maximum trop bas.
        appel(post("/api/moi/alertes").header("Authorization", "Bearer " + passager),
                alerte.formatted("Thiès", THIES_LAT, THIES_LNG, "Dakar", DAKAR_LAT, DAKAR_LNG, date, "")).andExpect(status().isCreated());
        appel(post("/api/moi/alertes").header("Authorization", "Bearer " + passager),
                alerte.formatted("Dakar", DAKAR_LAT, DAKAR_LNG, "Thiès", THIES_LAT, THIES_LNG, date, ",\"prixMax\":100"))
                .andExpect(status().isCreated());
        mvc.perform(get("/api/moi/alertes").header("Authorization", "Bearer " + passager))
                .andExpect(jsonPath("$.length()").value(3));

        // --- Estimation puis publication
        appel(post("/api/trajets/estimation").header("Authorization", "Bearer " + conductrice), """
                {"idVehicule":%d,"depart":{"lieu":"Dakar","latitude":%s,"longitude":%s},
                 "arrivee":{"lieu":"Thiès","latitude":%s,"longitude":%s},"dateHeureDepart":"%s","nombrePlaces":3}"""
                .formatted(idVehicule, DAKAR_LAT, DAKAR_LNG, THIES_LAT, THIES_LNG, depart()))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.tarif.prixRecommande").isNumber())
                .andExpect(jsonPath("$.tarif.versionModele").value("FORMULE-1.0"));

        String trajet = appel(post("/api/trajets").header("Authorization", "Bearer " + conductrice), publication)
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.statut").value("PUBLIE"))
                .andExpect(jsonPath("$.tarification.prixMin").isNumber())
                .andReturn().getResponse().getContentAsString();
        long idTrajet = ((Number) JsonPath.read(trajet, "$.id")).longValue();
        double prix = ((Number) JsonPath.read(trajet, "$.prixParPlace")).doubleValue();

        // Prix hors fourchette refusé
        appel(put("/api/trajets/" + idTrajet).header("Authorization", "Bearer " + conductrice), "{\"prixParPlace\":1}")
                .andExpect(status().isBadRequest());

        // Une seule alerte déclenchée : celle qui correspond (même sens, prix accepté).
        mvc.perform(get("/api/moi/notifications").header("Authorization", "Bearer " + passager))
                .andExpect(jsonPath("$.page.totalElements").value(1))
                .andExpect(jsonPath("$.content[0].type").value("ALERTE_TRAJET"));

        // --- Recherche du passager
        mvc.perform(get(recherche)).andExpect(status().isOk())
                .andExpect(jsonPath("$.length()").value(1))
                .andExpect(jsonPath("$[0].id").value(idTrajet))
                .andExpect(jsonPath("$[0].correspondance.distanceRamassageM").isNumber())
                .andExpect(jsonPath("$[0].tarification").doesNotExist());
        // Sens inverse (Thiès -> Dakar) : aucun résultat
        mvc.perform(get("/api/trajets/recherche?latDepart=%s&lngDepart=%s&latArrivee=%s&lngArrivee=%s&date=%s"
                        .formatted(THIES_LAT, THIES_LNG, DAKAR_LAT, DAKAR_LNG, date)))
                .andExpect(jsonPath("$.length()").value(0));
        // Prix maximum trop bas : aucun résultat
        mvc.perform(get(recherche + "&prixMax=" + (prix - 1))).andExpect(jsonPath("$.length()").value(0));

        // --- Réservation (mode manuel) puis acceptation
        String resa = appel(post("/api/trajets/" + idTrajet + "/reservations").header("Authorization", "Bearer " + passager),
                "{\"nombrePlaces\":2}")
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.statut").value("EN_ATTENTE"))
                .andReturn().getResponse().getContentAsString();
        long idResa = ((Number) JsonPath.read(resa, "$.id")).longValue();
        appel(post("/api/trajets/" + idTrajet + "/reservations").header("Authorization", "Bearer " + passager),
                "{\"nombrePlaces\":1}").andExpect(status().isConflict());
        // Le passager n'est pas conducteur
        mvc.perform(post("/api/reservations/" + idResa + "/accepter").header("Authorization", "Bearer " + passager))
                .andExpect(status().isForbidden());

        mvc.perform(post("/api/reservations/" + idResa + "/accepter").header("Authorization", "Bearer " + conductrice))
                .andExpect(status().isOk()).andExpect(jsonPath("$.statut").value("ACCEPTEE"))
                .andExpect(jsonPath("$.statutPaiement").value("EN_ATTENTE"));
        mvc.perform(get("/api/trajets/" + idTrajet)).andExpect(jsonPath("$.nombrePlacesDisponibles").value(1));

        // --- Embarquement par PIN
        String code = mvc.perform(get("/api/reservations/" + idResa + "/embarquement").header("Authorization", "Bearer " + passager))
                .andExpect(status().isOk()).andReturn().getResponse().getContentAsString();
        String pin = JsonPath.read(code, "$.codePin");
        assertThat(pin).matches("\\d{6}");

        appel(post("/api/trajets/" + idTrajet + "/embarquement").header("Authorization", "Bearer " + conductrice),
                "{\"code\":\"" + (pin.equals("000000") ? "111111" : "000000") + "\"}").andExpect(status().isNotFound());
        appel(post("/api/trajets/" + idTrajet + "/embarquement").header("Authorization", "Bearer " + conductrice),
                "{\"code\":\"" + pin + "\"}")
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.nombrePlaces").value(2))
                .andExpect(jsonPath("$.montantAEncaisser").value(prix * 2));
        mvc.perform(get("/api/moi/reservations").header("Authorization", "Bearer " + passager))
                .andExpect(jsonPath("$[0].embarque").value(true))
                .andExpect(jsonPath("$[0].statutPaiement").value("REUSSI"));

        // --- Notifications et statistiques
        // Alerte de recherche + réservation acceptée + embarquement confirmé
        mvc.perform(get("/api/moi/notifications").header("Authorization", "Bearer " + passager))
                .andExpect(status().isOk()).andExpect(jsonPath("$.page.totalElements").value(3));
        mvc.perform(get("/api/admin/statistiques").header("Authorization", "Bearer " + admin))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.conducteursValides").value(1))
                .andExpect(jsonPath("$.reservations.montantEncaisse").value(prix * 2));
    }

    @Test
    void motDePasseOublieParOtp() throws Exception {
        inscrire("Fatou", "Sow", "fatou@test.sn", "761112233", "FEMME");
        String codeInscription = CodesDeTest.DERNIER_CODE.get("fatou@test.sn");
        // Par email : le code part à l'adresse du compte, sans révéler le numéro.
        appel(post("/api/auth/mot-de-passe/oublie"), "{\"identifiant\":\"fatou@test.sn\"}")
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.canal").value("EMAIL"))
                .andExpect(jsonPath("$.emailMasque").value("f****@test.sn"))
                .andExpect(jsonPath("$.telephoneMasque").doesNotExist())
                .andExpect(jsonPath("$.otpValiditeSecondes").value(300));
        String code = CodesDeTest.attendreNouveauCode("fatou@test.sn", codeInscription);
        appel(post("/api/auth/mot-de-passe/reinitialiser"),
                "{\"identifiant\":\"fatou@test.sn\",\"code\":\"" + code + "\",\"nouveauMotDePasse\":\"NouveauMdp2026\"}")
                .andExpect(status().isNoContent());
        appel(post("/api/auth/connexion"), "{\"identifiant\":\"76 111 22 33\",\"motDePasse\":\"NouveauMdp2026\"}")
                .andExpect(status().isOk()).andExpect(jsonPath("$.etape").value("CONNECTE"));
        // Compte inexistant : même réponse
        appel(post("/api/auth/mot-de-passe/oublie"), "{\"identifiant\":\"inconnu@test.sn\"}").andExpect(status().isOk());
    }

    @Test
    void bloqueApresCinqEchecsDeConnexion() throws Exception {
        inscrire("Ibrahima", "Fall", "ibou@test.sn", "701234567", "HOMME");
        for (int i = 0; i < 5; i++) {
            appel(post("/api/auth/connexion"), "{\"identifiant\":\"ibou@test.sn\",\"motDePasse\":\"faux12345\"}")
                    .andExpect(status().isUnauthorized());
        }
        appel(post("/api/auth/connexion"), "{\"identifiant\":\"IBOU@test.sn\",\"motDePasse\":\"MotDePasse2026\"}")
                .andExpect(status().isTooManyRequests())
                .andExpect(jsonPath("$.reessayerDansSecondes").isNumber());
    }

    @Test
    void signaleLeChampEnConflitALInscription() throws Exception {
        inscrire("Aminata", "Ba", "aminata@test.sn", "772223344", "FEMME");
        appel(post("/api/auth/inscription"), """
                {"prenom":"A","nom":"B","email":"aminata@test.sn","telephone":"775556677","motDePasse":"MotDePasse2026"}""")
                .andExpect(status().isConflict())
                .andExpect(jsonPath("$.champ").value("email"));
    }

    // ------------------------------------------------------------------ utilitaires

    private String dernierRefresh;

    private String inscrire(String prenom, String nom, String email, String tel, String sexe) throws Exception {
        String ancien = CodesDeTest.DERNIER_CODE.get(email);
        appel(post("/api/auth/inscription"), """
                {"prenom":"%s","nom":"%s","email":"%s","telephone":"%s","motDePasse":"MotDePasse2026","sexe":"%s"}"""
                .formatted(prenom, nom, email, tel, sexe))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.etape").value("OTP_ENVOYE"))
                .andExpect(jsonPath("$.canal").value("EMAIL"));
        appel(post("/api/auth/otp/verifier"), "{\"identifiant\":\"" + tel + "\",\"code\":\"999999x\"}")
                .andExpect(status().isBadRequest());
        String code = CodesDeTest.attendreNouveauCode(email, ancien);
        // Code reçu par email : l'adresse est vérifiée, le numéro ne l'est pas.
        return jeton(appel(post("/api/auth/otp/verifier"), "{\"identifiant\":\"" + tel + "\",\"code\":\"" + code + "\"}")
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.utilisateur.statut").value("ACTIF"))
                .andExpect(jsonPath("$.utilisateur.emailVerifie").value(true))
                .andExpect(jsonPath("$.utilisateur.telephoneVerifie").value(false)));
    }

    private ResultActions appel(MockHttpServletRequestBuilder req, String json) throws Exception {
        return mvc.perform(req.contentType(MediaType.APPLICATION_JSON).content(json));
    }

    private String jeton(ResultActions r) throws Exception {
        String body = r.andExpect(status().isOk()).andReturn().getResponse().getContentAsString();
        dernierRefresh = JsonPath.read(body, "$.refreshToken");
        return JsonPath.read(body, "$.accessToken");
    }

    private static String depart() {
        return LocalDateTime.now().plusDays(3).withHour(10).withMinute(0).withSecond(0).withNano(0).toString();
    }
}
