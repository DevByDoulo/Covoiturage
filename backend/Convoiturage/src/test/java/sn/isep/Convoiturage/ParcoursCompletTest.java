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
    void contactsUrgenceMotDePasseEtDesactivation() throws Exception {
        String moussa = inscrire("Moussa", "Fall", "moussa@test.sn", "775550001", "HOMME");
        String auth = "Bearer " + moussa;

        // Contacts d'urgence : numéro normalisé, pas le sien, pas de doublon, 3 au plus
        mvc.perform(post("/api/moi/contacts-urgence").header("Authorization", auth).contentType(MediaType.APPLICATION_JSON)
                        .content("{\"nom\":\"Ousmane Diop\",\"telephone\":\"77 123 45 12\",\"lien\":\"Frère\"}"))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.telephone").value("+221771234512"));
        mvc.perform(post("/api/moi/contacts-urgence").header("Authorization", auth).contentType(MediaType.APPLICATION_JSON)
                        .content("{\"nom\":\"Moi\",\"telephone\":\"775550001\"}"))
                .andExpect(status().isBadRequest()).andExpect(jsonPath("$.champ").value("telephone"));
        mvc.perform(post("/api/moi/contacts-urgence").header("Authorization", auth).contentType(MediaType.APPLICATION_JSON)
                        .content("{\"nom\":\"Encore\",\"telephone\":\"+221771234512\"}"))
                .andExpect(status().isConflict());
        for (String tel : new String[]{"761234589", "781234589"}) {
            mvc.perform(post("/api/moi/contacts-urgence").header("Authorization", auth).contentType(MediaType.APPLICATION_JSON)
                    .content("{\"nom\":\"Proche\",\"telephone\":\"" + tel + "\"}")).andExpect(status().isCreated());
        }
        mvc.perform(post("/api/moi/contacts-urgence").header("Authorization", auth).contentType(MediaType.APPLICATION_JSON)
                        .content("{\"nom\":\"Quatrième\",\"telephone\":\"701234589\"}"))
                .andExpect(status().isConflict());
        String liste = mvc.perform(get("/api/moi/contacts-urgence").header("Authorization", auth))
                .andExpect(status().isOk()).andExpect(jsonPath("$.length()").value(3))
                .andReturn().getResponse().getContentAsString();
        long idContact = ((Number) JsonPath.read(liste, "$[0].id")).longValue();
        mvc.perform(delete("/api/moi/contacts-urgence/" + idContact).header("Authorization", auth)).andExpect(status().isNoContent());

        // Changement du mot de passe : l'ancien est vérifié, les autres sessions sont fermées, le titulaire est prévenu
        String ancienRefresh = dernierRefresh;
        mvc.perform(put("/api/moi/mot-de-passe").header("Authorization", auth).contentType(MediaType.APPLICATION_JSON)
                        .content("{\"motDePasseActuel\":\"faux12345\",\"nouveauMotDePasse\":\"Nouveau2026\"}"))
                .andExpect(status().isBadRequest()).andExpect(jsonPath("$.champ").value("motDePasseActuel"));
        String nouveau = jeton(mvc.perform(put("/api/moi/mot-de-passe").header("Authorization", auth).contentType(MediaType.APPLICATION_JSON)
                .content("{\"motDePasseActuel\":\"MotDePasse2026\",\"nouveauMotDePasse\":\"Nouveau2026\"}"))
                .andExpect(jsonPath("$.utilisateur.motDePasseDefini").value(true)));
        appel(post("/api/auth/refresh"), "{\"refreshToken\":\"" + ancienRefresh + "\"}").andExpect(status().isUnauthorized());
        CodesDeTest.attendreEmail("moussa@test.sn", "YOBALEMAsn - Votre mot de passe a été modifié");

        // Désactivation (mot de passe exigé) puis réactivation à la connexion suivante
        mvc.perform(post("/api/moi/desactivation").header("Authorization", "Bearer " + nouveau).contentType(MediaType.APPLICATION_JSON)
                .content("{\"motDePasse\":\"MotDePasse2026\"}")).andExpect(status().isBadRequest());
        mvc.perform(post("/api/moi/desactivation").header("Authorization", "Bearer " + nouveau).contentType(MediaType.APPLICATION_JSON)
                .content("{\"motDePasse\":\"Nouveau2026\"}")).andExpect(status().isNoContent());
        appel(post("/api/auth/refresh"), "{\"refreshToken\":\"" + dernierRefresh + "\"}").andExpect(status().isUnauthorized());
        appel(post("/api/auth/connexion"), "{\"identifiant\":\"moussa@test.sn\",\"motDePasse\":\"Nouveau2026\"}")
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.utilisateur.statut").value("ACTIF"));
    }

    @Test
    void vehiculesEtDocuments() throws Exception {
        String khady = "Bearer " + inscrire("Khady", "Ndiaye", "khady@test.sn", "776660001", "FEMME");
        String vehicule = """
                {"immatriculation":"dk 1234 ab","marque":"Toyota","modele":"Corolla","annee":2018,"puissanceFiscale":7,
                 "nombrePlaces":5,"typeEnergie":"ESSENCE","consommationTheorique":6.5}""";

        // Déclaration : immatriculation normalisée, rôle conducteur (visible après rafraîchissement du jeton)
        String cree = mvc.perform(post("/api/moi/vehicules").header("Authorization", khady)
                        .contentType(MediaType.APPLICATION_JSON).content(vehicule))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.immatriculation").value("DK-1234-AB"))
                .andExpect(jsonPath("$.statutValidation").value("EN_ATTENTE"))
                .andReturn().getResponse().getContentAsString();
        long idVehicule = ((Number) JsonPath.read(cree, "$.id")).longValue();
        mvc.perform(post("/api/moi/vehicules").header("Authorization", khady)
                        .contentType(MediaType.APPLICATION_JSON).content(vehicule))
                .andExpect(status().isConflict()).andExpect(jsonPath("$.champ").value("immatriculation"));
        String conductrice = "Bearer " + jeton(appel(post("/api/auth/refresh"), "{\"refreshToken\":\"" + dernierRefresh + "\"}")
                .andExpect(jsonPath("$.utilisateur.role").value("CONDUCTEUR")));

        // Documents : permis, pièce d'identité, carte grise (rattachée au véhicule) ; un nouvel envoi remplace l'attente
        byte[] png = {(byte) 0x89, 'P', 'N', 'G', 0x0D, 0x0A, 0x1A, 0x0A, 0, 0, 0, 0};
        for (String type : new String[]{"PERMIS_CONDUIRE", "PIECE_IDENTITE", "PERMIS_CONDUIRE"}) {
            mvc.perform(multipart("/api/moi/documents").file(new MockMultipartFile("fichier", "doc.png", "image/png", png))
                            .param("type", type).header("Authorization", conductrice))
                    .andExpect(status().isCreated()).andExpect(jsonPath("$.statutValidation").value("EN_ATTENTE"));
        }
        mvc.perform(multipart("/api/moi/documents").file(new MockMultipartFile("fichier", "cg.png", "image/png", png))
                        .param("type", "CARTE_GRISE").header("Authorization", conductrice))
                .andExpect(status().isBadRequest());
        String carteGrise = mvc.perform(multipart("/api/moi/documents").file(new MockMultipartFile("fichier", "cg.png", "image/png", png))
                        .param("type", "CARTE_GRISE").param("idVehicule", String.valueOf(idVehicule)).header("Authorization", conductrice))
                .andExpect(status().isCreated()).andExpect(jsonPath("$.immatriculation").value("DK-1234-AB"))
                .andReturn().getResponse().getContentAsString();
        mvc.perform(get("/api/moi/documents").header("Authorization", conductrice))
                .andExpect(status().isOk()).andExpect(jsonPath("$.length()").value(3));

        // Le fichier n'est visible que par son propriétaire
        String url = JsonPath.read(carteGrise, "$.urlFichier");
        mvc.perform(get(url).header("Authorization", conductrice)).andExpect(status().isOk());
        String autre = "Bearer " + inscrire("Bineta", "Sarr", "bineta@test.sn", "776660002", "FEMME");
        mvc.perform(get(url).header("Authorization", autre)).andExpect(status().isNotFound());

        // Avant validation tout est modifiable ; après, seulement la consommation et l'usure
        mvc.perform(put("/api/moi/vehicules/" + idVehicule).header("Authorization", conductrice)
                        .contentType(MediaType.APPLICATION_JSON).content(vehicule.replace("Corolla", "Yaris")))
                .andExpect(status().isOk()).andExpect(jsonPath("$.modele").value("Yaris"));
        jdbc.update("update vehicule set statut_validation = 'VALIDE' where id_vehicule = ?", idVehicule);
        mvc.perform(put("/api/moi/vehicules/" + idVehicule).header("Authorization", conductrice)
                        .contentType(MediaType.APPLICATION_JSON).content(vehicule.replace("Corolla", "Camry")))
                .andExpect(status().isConflict());
        mvc.perform(put("/api/moi/vehicules/" + idVehicule).header("Authorization", conductrice)
                        .contentType(MediaType.APPLICATION_JSON).content(vehicule.replace("Corolla", "Yaris").replace("6.5", "7.2")))
                .andExpect(status().isOk()).andExpect(jsonPath("$.consommationTheorique").value(7.2));

        // Retrait puis nouvelle déclaration de la même voiture : elle est réactivée
        mvc.perform(delete("/api/moi/vehicules/" + idVehicule).header("Authorization", conductrice)).andExpect(status().isNoContent());
        mvc.perform(get("/api/moi/vehicules").header("Authorization", conductrice)).andExpect(jsonPath("$.length()").value(0));
        mvc.perform(post("/api/moi/vehicules").header("Authorization", conductrice)
                        .contentType(MediaType.APPLICATION_JSON).content(vehicule))
                .andExpect(status().isCreated()).andExpect(jsonPath("$.id").value(idVehicule));
    }

    @Test
    void administrationValidationDesDocumentsEtBlocage() throws Exception {
        String admin = "Bearer " + jeton(appel(post("/api/auth/connexion"), """
                {"identifiant":"admin@test.local","motDePasse":"Admin-Test-2026!"}"""));
        String ousmane = "Bearer " + inscrire("Ousmane", "Gueye", "ousmane@test.sn", "778880001", "HOMME");
        long idOusmane = ((Number) JsonPath.read(mvc.perform(get("/api/moi").header("Authorization", ousmane))
                .andReturn().getResponse().getContentAsString(), "$.id")).longValue();
        mvc.perform(get("/api/admin/statistiques").header("Authorization", ousmane)).andExpect(status().isForbidden());

        // Ousmane déclare un véhicule et envoie ses trois pièces
        String vehicule = mvc.perform(post("/api/moi/vehicules").header("Authorization", ousmane).contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"immatriculation":"DK-7788-AA","marque":"Toyota","modele":"Yaris","annee":2020,"puissanceFiscale":5,
                                 "nombrePlaces":4,"typeEnergie":"ESSENCE"}"""))
                .andExpect(status().isCreated()).andReturn().getResponse().getContentAsString();
        long idVehicule = ((Number) JsonPath.read(vehicule, "$.id")).longValue();
        byte[] png = {(byte) 0x89, 'P', 'N', 'G', 0x0D, 0x0A, 0x1A, 0x0A, 0, 0, 0, 0};
        for (String type : new String[]{"PERMIS_CONDUIRE", "PIECE_IDENTITE", "CARTE_GRISE"}) {
            var envoi = multipart("/api/moi/documents").file(new MockMultipartFile("fichier", "doc.png", "image/png", png))
                    .param("type", type).header("Authorization", ousmane);
            if (type.equals("CARTE_GRISE")) envoi.param("idVehicule", String.valueOf(idVehicule));
            mvc.perform(envoi).andExpect(status().isCreated());
        }

        // File de validation : filtres par titulaire et par type, autres pièces du titulaire jointes
        mvc.perform(get("/api/admin/documents").param("recherche", "ousmane").header("Authorization", admin))
                .andExpect(status().isOk()).andExpect(jsonPath("$.content.length()").value(3));
        String permis = mvc.perform(get("/api/admin/documents").param("recherche", "ousmane").param("type", "PERMIS_CONDUIRE")
                        .header("Authorization", admin))
                .andExpect(jsonPath("$.content.length()").value(1))
                .andExpect(jsonPath("$.content[0].autresDocuments.length()").value(2))
                .andReturn().getResponse().getContentAsString();
        long idPermis = ((Number) JsonPath.read(permis, "$.content[0].document.id")).longValue();

        // Refus : motif obligatoire, communiqué au titulaire ; une pièce déjà traitée ne peut plus l'être
        mvc.perform(post("/api/admin/documents/" + idPermis + "/refuser").header("Authorization", admin)
                .contentType(MediaType.APPLICATION_JSON).content("{\"motif\":\"\"}")).andExpect(status().isBadRequest());
        mvc.perform(post("/api/admin/documents/" + idPermis + "/refuser").header("Authorization", admin)
                        .contentType(MediaType.APPLICATION_JSON).content("{\"motif\":\"Photo floue\"}"))
                .andExpect(status().isOk()).andExpect(jsonPath("$.statutValidation").value("REFUSE"));
        CodesDeTest.attendreEmail("ousmane@test.sn", "YOBALEMAsn - Document à renvoyer");
        mvc.perform(post("/api/admin/documents/" + idPermis + "/valider").header("Authorization", admin)).andExpect(status().isConflict());

        // Nouveau permis, puis validation des trois pièces : Ousmane devient conducteur validé
        mvc.perform(multipart("/api/moi/documents").file(new MockMultipartFile("fichier", "permis.png", "image/png", png))
                .param("type", "PERMIS_CONDUIRE").header("Authorization", ousmane)).andExpect(status().isCreated());
        String file = mvc.perform(get("/api/admin/documents").param("recherche", "ousmane").header("Authorization", admin))
                .andExpect(jsonPath("$.content.length()").value(3)).andReturn().getResponse().getContentAsString();
        for (Object id : JsonPath.<List<Object>>read(file, "$.content[*].document.id")) {
            mvc.perform(post("/api/admin/documents/" + id + "/valider").header("Authorization", admin)).andExpect(status().isOk());
        }
        mvc.perform(get("/api/moi").header("Authorization", ousmane)).andExpect(jsonPath("$.conducteurValide").value(true));

        // Fiche : véhicule, pièces, historique des décisions
        mvc.perform(get("/api/admin/utilisateurs/" + idOusmane).header("Authorization", admin))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.vehicules.length()").value(1))
                .andExpect(jsonPath("$.documents.length()").value(4))
                .andExpect(jsonPath("$.historique.length()").value(4))
                .andExpect(jsonPath("$.historique[3].type").value("DOCUMENT_REFUSE"));
        mvc.perform(get("/api/admin/utilisateurs").param("recherche", "ousmane").header("Authorization", admin))
                .andExpect(jsonPath("$.page.totalElements").value(1));

        // Blocage : motif obligatoire, pas sur soi-même ; connexion et sessions coupées ; puis déblocage
        mvc.perform(post("/api/admin/utilisateurs/" + idOusmane + "/bloquer").header("Authorization", admin)
                .contentType(MediaType.APPLICATION_JSON).content("{}")).andExpect(status().isBadRequest());
        mvc.perform(post("/api/admin/utilisateurs/" + idOusmane + "/bloquer").header("Authorization", admin)
                        .contentType(MediaType.APPLICATION_JSON).content("{\"motif\":\"Annulations répétées\"}"))
                .andExpect(status().isOk()).andExpect(jsonPath("$.utilisateur.statut").value("BLOQUE"));
        appel(post("/api/auth/connexion"), "{\"identifiant\":\"ousmane@test.sn\",\"motDePasse\":\"MotDePasse2026\"}")
                .andExpect(status().isForbidden());
        mvc.perform(post("/api/admin/utilisateurs/" + idOusmane + "/reactiver").header("Authorization", admin))
                .andExpect(status().isOk()).andExpect(jsonPath("$.utilisateur.statut").value("ACTIF"))
                .andExpect(jsonPath("$.historique[0].type").value("COMPTE_REACTIVE"));
        appel(post("/api/auth/connexion"), "{\"identifiant\":\"ousmane@test.sn\",\"motDePasse\":\"MotDePasse2026\"}")
                .andExpect(status().isOk());
        mvc.perform(get("/api/admin/statistiques").header("Authorization", admin))
                .andExpect(status().isOk()).andExpect(jsonPath("$.conducteursValides").isNumber());
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
