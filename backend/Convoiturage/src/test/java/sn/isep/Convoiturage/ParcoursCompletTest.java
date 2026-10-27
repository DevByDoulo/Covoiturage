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
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.ResultActions;
import org.springframework.test.web.servlet.request.MockHttpServletRequestBuilder;
import sn.isep.Convoiturage.auth.EmailSender;
import sn.isep.Convoiturage.auth.SmsSender;

import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.concurrent.ConcurrentHashMap;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

/**
 * Parcours de bout en bout (inscription, connexion, profil, mot de passe oublié) sur la base PostgreSQL locale « covoiturage_test »
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
        /** Sujets des emails reçus, par adresse. */
        static final Map<String, List<String>> SUJETS = new ConcurrentHashMap<>();
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

        /** Attend (5 secondes au plus) qu'un email de ce sujet soit arrivé à cette adresse. */
        static void attendreEmail(String email, String sujet) throws InterruptedException {
            for (int i = 0; i < 100; i++) {
                if (SUJETS.getOrDefault(email, List.of()).contains(sujet)) return;
                Thread.sleep(50);
            }
            throw new AssertionError("Email « " + sujet + " » non reçu par " + email);
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
                @Override public void envoyer(String email, String sujet, String texte) {
                    SUJETS.computeIfAbsent(email, k -> new java.util.concurrent.CopyOnWriteArrayList<>()).add(sujet);
                    capturer(email, texte);
                }
            };
        }
    }

    @Autowired
    MockMvc mvc;

    @Autowired
    JdbcTemplate jdbc;

    @Test
    void connexionProfilEtSession() throws Exception {
        // Compte admin créé au démarrage
        appel(post("/api/auth/connexion"), """
                {"identifiant":"admin@test.local","motDePasse":"Admin-Test-2026!"}""")
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.utilisateur.role").value("ADMIN"));

        // Inscription + code par email, puis connexion par email ou par téléphone
        inscrire("Awa", "Diop", "awa@test.sn", "771111111", "FEMME");
        appel(post("/api/auth/connexion"), """
                {"identifiant":"awa@test.sn","motDePasse":"mauvais123"}""").andExpect(status().isUnauthorized());
        String awa = jeton(appel(post("/api/auth/connexion"), """
                {"identifiant":"77 111 11 11","motDePasse":"MotDePasse2026"}"""));

        // Profil et préférences
        mvc.perform(get("/api/moi").header("Authorization", "Bearer " + awa))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.prenom").value("Awa"))
                .andExpect(jsonPath("$.telephone").value("+221771111111"));
        mvc.perform(put("/api/moi/preferences").header("Authorization", "Bearer " + awa)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"fumeurAccepte":false,"musiqueAcceptee":true,"animauxAcceptes":true,"discussionAcceptee":false}"""))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.preferences.animauxAcceptes").value(true));
        mvc.perform(get("/api/moi")).andExpect(status().isUnauthorized());

        // Rafraîchissement (rotation) puis déconnexion : l'ancien refresh token n'est plus utilisable
        String refresh = dernierRefresh;
        jeton(appel(post("/api/auth/refresh"), "{\"refreshToken\":\"" + refresh + "\"}"));
        appel(post("/api/auth/refresh"), "{\"refreshToken\":\"" + refresh + "\"}").andExpect(status().isUnauthorized());
        appel(post("/api/auth/deconnexion"), "{\"refreshToken\":\"" + dernierRefresh + "\"}").andExpect(status().isNoContent());
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
        String codeFaux = code.equals("000000") ? "111111" : "000000";
        // 1) Le code est vérifié seul : un mauvais code est refusé avant tout choix de mot de passe.
        appel(post("/api/auth/mot-de-passe/verifier-code"), "{\"identifiant\":\"fatou@test.sn\",\"code\":\"" + codeFaux + "\"}")
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.tentativesRestantes").value(4));
        String jeton = JsonPath.read(appel(post("/api/auth/mot-de-passe/verifier-code"),
                        "{\"identifiant\":\"fatou@test.sn\",\"code\":\"" + code + "\"}")
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.validiteSecondes").value(600))
                .andReturn().getResponse().getContentAsString(), "$.jeton");
        // 2) Le jeton remis autorise le nouveau mot de passe, une seule fois.
        String reinitialisation = "{\"jeton\":\"" + jeton + "\",\"nouveauMotDePasse\":\"NouveauMdp2026\"}";
        appel(post("/api/auth/mot-de-passe/reinitialiser"), reinitialisation).andExpect(status().isNoContent());
        appel(post("/api/auth/mot-de-passe/reinitialiser"), reinitialisation).andExpect(status().isBadRequest());
        appel(post("/api/auth/connexion"), "{\"identifiant\":\"76 111 22 33\",\"motDePasse\":\"NouveauMdp2026\"}")
                .andExpect(status().isOk()).andExpect(jsonPath("$.etape").value("CONNECTE"));
        // Le jeton n'est pas un jeton d'accès.
        mvc.perform(get("/api/moi").header("Authorization", "Bearer " + jeton)).andExpect(status().isUnauthorized());
        // Le titulaire est prévenu du changement.
        CodesDeTest.attendreEmail("fatou@test.sn", "YOBALEMAsn - Votre mot de passe a été modifié");

        // Compte inexistant : mêmes réponses qu'un vrai compte (envoi, code faux, renvoi trop rapide).
        appel(post("/api/auth/mot-de-passe/oublie"), "{\"identifiant\":\"inconnu@test.sn\"}")
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.canal").value("EMAIL"))
                .andExpect(jsonPath("$.emailMasque").value("i******@test.sn"));
        appel(post("/api/auth/mot-de-passe/verifier-code"), "{\"identifiant\":\"inconnu@test.sn\",\"code\":\"123456\"}")
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.tentativesRestantes").value(4));
        appel(post("/api/auth/mot-de-passe/oublie"), "{\"identifiant\":\"inconnu@test.sn\"}")
                .andExpect(status().isTooManyRequests())
                .andExpect(jsonPath("$.motif").value("DELAI_RENVOI"));
    }

    @Test
    void limiteLeNombreDeCodesParHeure() throws Exception {
        String demande = "{\"identifiant\":\"77 999 88 77\"}";
        for (int i = 0; i < 5; i++) {
            appel(post("/api/auth/mot-de-passe/oublie"), demande).andExpect(status().isOk());
            // Les codes fictifs (comptes inconnus) ont une clé commençant par « ? » : on les vieillit
            // de 2 minutes pour passer le délai de renvoi de 60 s sans attendre.
            jdbc.update("update otp_code set date_creation = date_creation - interval '2 minutes' where telephone like '?%'");
        }
        appel(post("/api/auth/mot-de-passe/oublie"), demande)
                .andExpect(status().isTooManyRequests())
                .andExpect(jsonPath("$.motif").value("QUOTA_CODES"))
                .andExpect(jsonPath("$.reessayerDansSecondes").isNumber());
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
}
