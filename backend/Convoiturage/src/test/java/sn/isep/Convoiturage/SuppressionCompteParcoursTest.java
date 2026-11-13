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
import sn.isep.Convoiturage.suppression.AnonymisationPlanifiee;

import java.time.LocalDateTime;
import java.time.temporal.ChronoUnit;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNull;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

/**
 * Suppression de compte (RGPD) sur la base locale « covoiturage_test » : refus tant qu'un engagement est en cours,
 * délai de grâce annulé par la reconnexion, anonymisation planifiée qui conserve paiements et réservations.
 */
@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
@Import({ParcoursCompletTest.BaseDeTestPropre.class, ParcoursCompletTest.CodesDeTest.class})
class SuppressionCompteParcoursTest {

    @Autowired
    MockMvc mvc;

    @Autowired
    JdbcTemplate jdbc;

    @Autowired
    AnonymisationPlanifiee planifiee;

    private String dernierRefresh;

    @Test
    void refusPuisDemandeAnnulationEtAnonymisation() throws Exception {
        String seydou = conducteurValide("Seydou", "Ba", "seydou.sup@test.sn", "755900001");
        String awa = inscrire("Awa", "Fall", "awa.sup@test.sn", "755900002");
        String refreshAwa = dernierRefresh;
        long idAwa = idDe("awa.sup@test.sn");

        long idVehicule = ((Number) JsonPath.read(mvc.perform(get("/api/moi/vehicules").header("Authorization", "Bearer " + seydou))
                .andReturn().getResponse().getContentAsString(), "$[0].id")).longValue();
        String depart = LocalDateTime.now().plusDays(1).truncatedTo(ChronoUnit.MINUTES).toString();
        long idTrajet = ((Number) JsonPath.read(appel(post("/api/trajets").header("Authorization", "Bearer " + seydou), """
                {"idVehicule":%d,"depart":{"lieu":"Dakar","latitude":14.6681,"longitude":-17.4318},
                 "arrivee":{"lieu":"Thiès","latitude":14.7910,"longitude":-16.9260},"dateHeureDepart":"%s",
                 "flexibiliteMinutes":15,"nombrePlaces":3,"modeReservation":"AUTOMATIQUE","tailleBagage":"PETIT",
                 "femmesUniquement":false}""".formatted(idVehicule, depart))
                .andExpect(status().isCreated()).andReturn().getResponse().getContentAsString(), "$.id")).longValue();
        appel(post("/api/trajets/" + idTrajet + "/reservations").header("Authorization", "Bearer " + awa),
                "{\"nombrePlaces\":1,\"moyenPaiement\":\"ESPECES\"}").andExpect(status().isCreated());
        appel(post("/api/moi/contacts-urgence").header("Authorization", "Bearer " + awa),
                "{\"nom\":\"Ousmane\",\"telephone\":\"771234512\"}").andExpect(status().isCreated());

        // --- Confirmation par mot de passe, administrateur exclu
        supprimer(awa, "{\"motDePasse\":\"faux12345\"}").andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.champ").value("motDePasse"));
        String admin = jeton(appel(post("/api/auth/connexion"), """
                {"identifiant":"admin@test.local","motDePasse":"Admin-Test-2026!"}"""));
        supprimer(admin, "{\"motDePasse\":\"Admin-Test-2026!\"}").andExpect(status().isForbidden());

        // --- Refus : réservation acceptée à venir (passager), trajet à venir (conducteur)
        supprimer(awa, "{\"motDePasse\":\"MotDePasse2026\"}").andExpect(status().isConflict())
                .andExpect(jsonPath("$.obstacles.length()").value(1))
                .andExpect(jsonPath("$.detail").value(org.hamcrest.Matchers.containsString("réservation acceptée")));
        supprimer(seydou, "{\"motDePasse\":\"MotDePasse2026\"}").andExpect(status().isConflict())
                .andExpect(jsonPath("$.detail").value(org.hamcrest.Matchers.containsString("trajet")));
        assertEquals("ACTIF", statut(idAwa));

        // --- Le conducteur annule son trajet : la réservation tombe, mais un paiement en ligne en attente bloque encore
        appel(post("/api/trajets/" + idTrajet + "/annuler").header("Authorization", "Bearer " + seydou), "{}")
                .andExpect(status().isOk());
        long idReservation = jdbc.queryForObject("select id_reservation from reservation where id_passager = ?", Long.class, idAwa);
        jdbc.update("insert into paiement (id_reservation, montant, moyen_paiement, reference_transaction, numero_telephone, statut, date_initiation) "
                + "values (?, 1500, 'WAVE', 'REF-SUP-1', '+221755900002', 'EN_ATTENTE', now())", idReservation);
        supprimer(awa, "{\"motDePasse\":\"MotDePasse2026\"}").andExpect(status().isConflict())
                .andExpect(jsonPath("$.detail").value(org.hamcrest.Matchers.containsString("paiement")));
        jdbc.update("update paiement set statut = 'ECHOUE' where reference_transaction = 'REF-SUP-1'");

        // --- Demande acceptée : compte déconnecté et prévenu
        supprimer(awa, "{\"motDePasse\":\"MotDePasse2026\"}").andExpect(status().isOk())
                .andExpect(jsonPath("$.dateSuppressionDefinitive").exists());
        assertEquals("SUPPRESSION_DEMANDEE", statut(idAwa));
        ParcoursCompletTest.CodesDeTest.attendreEmail("awa.sup@test.sn", "YOBALEMAsn - Suppression de votre compte demandée");
        appel(post("/api/auth/refresh"), "{\"refreshToken\":\"" + refreshAwa + "\"}").andExpect(status().isUnauthorized());

        // --- Se reconnecter dans le délai annule la suppression
        appel(post("/api/auth/connexion"), "{\"identifiant\":\"awa.sup@test.sn\",\"motDePasse\":\"MotDePasse2026\"}")
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.suppressionAnnulee").value(true))
                .andExpect(jsonPath("$.utilisateur.statut").value("ACTIF"));
        ParcoursCompletTest.CodesDeTest.attendreEmail("awa.sup@test.sn", "YOBALEMAsn - Suppression de votre compte annulée");
        assertNull(jdbc.queryForObject("select date_suppression_demandee from utilisateur where id_utilisateur = ?", java.sql.Timestamp.class, idAwa));

        // --- Nouvelle demande, puis délai écoulé : la tâche planifiée anonymise
        String awa2 = jeton(appel(post("/api/auth/connexion"), "{\"identifiant\":\"awa.sup@test.sn\",\"motDePasse\":\"MotDePasse2026\"}"));
        supprimer(awa2, "{\"motDePasse\":\"MotDePasse2026\"}").andExpect(status().isOk());
        assertEquals(0, planifiee.anonymiserLesComptesEchus(LocalDateTime.now()));   // délai de grâce pas écoulé
        assertEquals("SUPPRESSION_DEMANDEE", statut(idAwa));

        jdbc.update("update paiement set statut = 'REUSSI' where reference_transaction = 'REF-SUP-1'");
        jdbc.update("update utilisateur set date_suppression_demandee = now() - interval '31 days' where id_utilisateur = ?", idAwa);
        assertEquals(1, planifiee.anonymiserLesComptesEchus(LocalDateTime.now()));
        assertEquals(0, planifiee.anonymiserLesComptesEchus(LocalDateTime.now()));   // déjà fait

        assertEquals("SUPPRIME", statut(idAwa));
        var ligne = jdbc.queryForMap("select prenom, nom, email, telephone, mot_de_passe, photo_profil, google_id, date_anonymisation "
                + "from utilisateur where id_utilisateur = ?", idAwa);
        assertEquals("Utilisateur", ligne.get("prenom"));
        assertEquals("Supprimé", ligne.get("nom"));
        assertNull(ligne.get("email"));
        assertNull(ligne.get("telephone"));
        assertNull(ligne.get("mot_de_passe"));
        assertEquals(0, count("select count(*) from contact_urgence where id_utilisateur = ?", idAwa));
        assertEquals(0, count("select count(*) from refresh_token where id_utilisateur = ?", idAwa));
        assertEquals(0, count("select count(*) from notification where id_utilisateur = ?", idAwa));
        // Conservés : la réservation et le paiement (obligation comptable), sans numéro de téléphone
        assertEquals(1, count("select count(*) from reservation where id_passager = ?", idAwa));
        assertEquals(1, count("select count(*) from paiement where reference_transaction = 'REF-SUP-1' and numero_telephone is null and montant = 1500"));
        ParcoursCompletTest.CodesDeTest.attendreEmail("awa.sup@test.sn", "YOBALEMAsn - Votre compte a été supprimé");

        // Plus de connexion possible, ni par l'ancien email ni par le numéro
        appel(post("/api/auth/connexion"), "{\"identifiant\":\"awa.sup@test.sn\",\"motDePasse\":\"MotDePasse2026\"}")
                .andExpect(status().isUnauthorized());
        appel(post("/api/auth/connexion"), "{\"identifiant\":\"755900002\",\"motDePasse\":\"MotDePasse2026\"}")
                .andExpect(status().isUnauthorized());
    }

    @Test
    void compteGoogleConfirmeParCode() throws Exception {
        String modou = inscrire("Modou", "Diop", "modou.sup@test.sn", "755900003");
        long id = idDe("modou.sup@test.sn");
        jdbc.update("update utilisateur set mot_de_passe = null where id_utilisateur = ?", id);   // compte créé avec Google

        // Sans code : refusé ; avec un faux code : refusé ; avec le code reçu : accepté
        supprimer(modou, "{}").andExpect(status().isBadRequest()).andExpect(jsonPath("$.champ").value("code"));
        String ancien = ParcoursCompletTest.CodesDeTest.DERNIER_CODE.get("modou.sup@test.sn");
        appel(post("/api/moi/suppression/code").header("Authorization", "Bearer " + modou), "{}")
                .andExpect(status().isOk()).andExpect(jsonPath("$.etape").value("OTP_ENVOYE"));
        String code = ParcoursCompletTest.CodesDeTest.attendreNouveauCode("modou.sup@test.sn", ancien);
        String faux = code.equals("000000") ? "111111" : "000000";
        supprimer(modou, "{\"code\":\"" + faux + "\"}").andExpect(status().isBadRequest()).andExpect(jsonPath("$.champ").value("code"));
        assertEquals("ACTIF", statut(id));
        supprimer(modou, "{\"code\":\"" + code + "\"}").andExpect(status().isOk());
        assertEquals("SUPPRESSION_DEMANDEE", statut(id));
    }

    // ------------------------------------------------------------------ utilitaires

    private ResultActions supprimer(String jeton, String corps) throws Exception {
        return appel(post("/api/moi/suppression").header("Authorization", "Bearer " + jeton), corps);
    }

    private String statut(long id) {
        return jdbc.queryForObject("select statut from utilisateur where id_utilisateur = ?", String.class, id);
    }

    private int count(String sql, Object... args) {
        return jdbc.queryForObject(sql, Integer.class, args);
    }

    private long idDe(String email) {
        return jdbc.queryForObject("select id_utilisateur from utilisateur where email = ?", Long.class, email);
    }

    private String conducteurValide(String prenom, String nom, String email, String tel) throws Exception {
        String jeton = inscrire(prenom, nom, email, tel);
        appel(post("/api/moi/vehicules").header("Authorization", "Bearer " + jeton), """
                {"immatriculation":"DK-%s","marque":"Toyota","modele":"Yaris","annee":2020,"puissanceFiscale":5,
                 "nombrePlaces":5,"typeEnergie":"ESSENCE","consommationReelle":6.0}""".formatted(tel.substring(5)))
                .andExpect(status().isCreated());
        jdbc.update("update vehicule set statut_validation = 'VALIDE' where id_proprietaire = "
                + "(select id_utilisateur from utilisateur where email = ?)", email);
        jdbc.update("update utilisateur set conducteur_valide = true where email = ?", email);
        return jeton(appel(post("/api/auth/refresh"), "{\"refreshToken\":\"" + dernierRefresh + "\"}"));
    }

    private String inscrire(String prenom, String nom, String email, String tel) throws Exception {
        String ancien = ParcoursCompletTest.CodesDeTest.DERNIER_CODE.get(email);
        appel(post("/api/auth/inscription"), """
                {"prenom":"%s","nom":"%s","email":"%s","telephone":"%s","motDePasse":"MotDePasse2026","sexe":"HOMME"}"""
                .formatted(prenom, nom, email, tel))
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
