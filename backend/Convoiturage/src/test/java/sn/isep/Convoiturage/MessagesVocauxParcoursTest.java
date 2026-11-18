package sn.isep.Convoiturage;

import com.jayway.jsonpath.JsonPath;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.webmvc.test.autoconfigure.AutoConfigureMockMvc;
import org.springframework.context.annotation.Import;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.mock.web.MockMultipartFile;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.ResultActions;
import org.springframework.test.web.servlet.request.MockHttpServletRequestBuilder;
import sn.isep.Convoiturage.common.AppProperties;
import sn.isep.Convoiturage.messagerie.EchantillonsAudio;
import sn.isep.Convoiturage.messagerie.NettoyageVocaux;
import sn.isep.Convoiturage.suppression.AnonymisationService;

import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.attribute.FileTime;
import java.time.Instant;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.temporal.ChronoUnit;
import java.util.Arrays;

import static org.assertj.core.api.Assertions.assertThat;
import static org.hamcrest.Matchers.containsString;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

/**
 * 09 — Messages vocaux : envoi (format et durée vérifiés sur le fichier), aperçus « 🎤 Message vocal (0:03) »,
 * écoute réservée aux deux participants avec requêtes Range, « écouté », signalement d'un vocal et écoute par
 * l'administrateur, effacement à l'anonymisation du compte, expiration et fichiers orphelins.
 */
@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
@Import({ParcoursCompletTest.BaseDeTestPropre.class, ParcoursCompletTest.CodesDeTest.class})
class MessagesVocauxParcoursTest {

    static final double DAKAR_LAT = 14.6681, DAKAR_LNG = -17.4318;
    static final double THIES_LAT = 14.7910, THIES_LNG = -16.9260;

    @Autowired
    MockMvc mvc;

    @Autowired
    JdbcTemplate jdbc;

    @Autowired
    AppProperties props;

    @Autowired
    AnonymisationService anonymisation;

    @Autowired
    NettoyageVocaux nettoyage;

    private String dernierRefresh;

    @Test
    void messagesVocaux() throws Exception {
        String conducteur = conducteurValide("Ousmane", "Ba", "ousmane.vocaux@test.sn", "777770011");
        String passagere = inscrire("Khady", "Ndiaye", "khady.vocaux@test.sn", "767770011", "FEMME");
        String autre = inscrire("Modou", "Seck", "modou.vocaux@test.sn", "787770011", "HOMME");
        long idVehicule = ((Number) JsonPath.read(mvc.perform(get("/api/moi/vehicules").header("Authorization", conducteur))
                .andReturn().getResponse().getContentAsString(), "$[0].id")).longValue();
        long idTrajet = ((Number) JsonPath.read(appel(post("/api/trajets").header("Authorization", conducteur), """
                {"idVehicule":%d,"depart":{"lieu":"Dakar","latitude":%s,"longitude":%s},
                 "arrivee":{"lieu":"Thiès","latitude":%s,"longitude":%s},"dateHeureDepart":"%sT10:00:00",
                 "flexibiliteMinutes":20,"nombrePlaces":3,"modeReservation":"MANUELLE","tailleBagage":"MOYEN",
                 "femmesUniquement":false}""".formatted(idVehicule, DAKAR_LAT, DAKAR_LNG, THIES_LAT, THIES_LNG,
                        LocalDate.now().plusDays(2)))
                .andExpect(status().isCreated()).andReturn().getResponse().getContentAsString(), "$.id")).longValue();
        long idConv = ((Number) JsonPath.read(appel(post("/api/trajets/" + idTrajet + "/conversation")
                .header("Authorization", passagere), "{}").andExpect(status().isOk())
                .andReturn().getResponse().getContentAsString(), "$.id")).longValue();

        // --- Envoi : durée lue dans le fichier, forme d'onde gardée
        byte[] vocal = EchantillonsAudio.aac(3000);
        String r = vocal(passagere, idConv, vocal, "audio.aac", "10,50,90").andExpect(status().isCreated())
                .andExpect(jsonPath("$.type").value("VOCAL"))
                .andExpect(jsonPath("$.contenu").doesNotExist())
                .andExpect(jsonPath("$.audioDisponible").value(true))
                .andExpect(jsonPath("$.ecoute").value(false))
                .andExpect(jsonPath("$.formeOnde[2]").value(90))
                .andReturn().getResponse().getContentAsString();
        long idVocal = ((Number) JsonPath.read(r, "$.id")).longValue();
        assertThat(((Number) JsonPath.read(r, "$.dureeMs")).longValue()).isBetween(3000L, 3100L);
        String nomFichier = jdbc.queryForObject("select fichier_audio from message where id_message = ?", String.class, idVocal);
        assertThat(nomFichier).matches("[0-9a-f\\-]{36}\\.aac");
        Path fichier = Path.of(props.stockage().repertoire()).toAbsolutePath().resolve("vocaux").resolve(nomFichier);
        assertThat(fichier).exists();

        // --- Refus : format, taille, durée, forme d'onde (rien n'est enregistré)
        long avant = compterMessages(idConv);
        vocal(passagere, idConv, "<html>pas du son</html>".getBytes(StandardCharsets.UTF_8), "faux.webm", null)
                .andExpect(status().isBadRequest()).andExpect(jsonPath("$.detail").value(containsString("Format audio non accepté")));
        vocal(passagere, idConv, Arrays.copyOf(vocal, 3 * 1024 * 1024 + 1), "gros.aac", null)
                .andExpect(status().isBadRequest()).andExpect(jsonPath("$.detail").value(containsString("taille maximale")));
        vocal(passagere, idConv, EchantillonsAudio.aac(500), "court.aac", null)
                .andExpect(status().isBadRequest()).andExpect(jsonPath("$.detail").value("Message vocal trop court"));
        vocal(passagere, idConv, EchantillonsAudio.webm(6 * 60_000), "long.webm", null)
                .andExpect(status().isBadRequest()).andExpect(jsonPath("$.detail").value(containsString("trop long")));
        vocal(passagere, idConv, vocal, "audio.aac", "10,500").andExpect(status().isBadRequest());
        vocal(passagere, idConv, EchantillonsAudio.m4a(4000, "vide"), "video.mp4", null).andExpect(status().isBadRequest());
        assertThat(compterMessages(idConv)).isEqualTo(avant);
        // Un tiers ne peut pas écrire dans la conversation
        vocal(autre, idConv, vocal, "audio.aac", null).andExpect(status().isNotFound());

        // --- Aperçus : liste des conversations et notification (donc push)
        mvc.perform(get("/api/moi/conversations").header("Authorization", conducteur))
                .andExpect(jsonPath("$[0].dernierMessage").value("🎤 Message vocal (0:03)"));
        mvc.perform(get("/api/moi/notifications").header("Authorization", conducteur))
                .andExpect(jsonPath("$.content[0].type").value("MESSAGE_RECU"))
                .andExpect(jsonPath("$.content[0].contenu").value(containsString("🎤 Message vocal (0:03)")));

        // --- Fichier : servi aux deux participants (Range compris), jamais à un tiers ni sans jeton
        String url = "/api/moi/conversations/" + idConv + "/messages/" + idVocal + "/audio";
        byte[] recu = mvc.perform(get(url).header("Authorization", conducteur)).andExpect(status().isOk())
                .andExpect(header().string(HttpHeaders.CONTENT_TYPE, "audio/aac"))
                .andExpect(header().string(HttpHeaders.ACCEPT_RANGES, "bytes"))
                .andReturn().getResponse().getContentAsByteArray();
        assertThat(recu).isEqualTo(vocal);
        byte[] plage = mvc.perform(get(url).header("Authorization", passagere).header(HttpHeaders.RANGE, "bytes=0-9"))
                .andExpect(status().isPartialContent())
                .andExpect(header().string(HttpHeaders.CONTENT_RANGE, "bytes 0-9/" + vocal.length))
                .andReturn().getResponse().getContentAsByteArray();
        assertThat(plage).isEqualTo(Arrays.copyOf(vocal, 10));
        mvc.perform(get(url).header("Authorization", autre)).andExpect(status().isNotFound());
        mvc.perform(get(url)).andExpect(status().isUnauthorized());
        mvc.perform(post("/api/moi/conversations/" + idConv + "/messages/" + idVocal + "/ecoute").header("Authorization", autre))
                .andExpect(status().isNotFound());

        // --- « Écouté » : seulement quand le destinataire l'écoute
        mvc.perform(post("/api/moi/conversations/" + idConv + "/messages/" + idVocal + "/ecoute").header("Authorization", passagere))
                .andExpect(status().isOk()).andExpect(jsonPath("$.ecoute").value(false));
        mvc.perform(post("/api/moi/conversations/" + idConv + "/messages/" + idVocal + "/ecoute").header("Authorization", conducteur))
                .andExpect(status().isOk()).andExpect(jsonPath("$.ecoute").value(true));
        mvc.perform(get("/api/moi/conversations/" + idConv).header("Authorization", passagere))
                .andExpect(jsonPath("$.messages[0].ecoute").value(true))
                .andExpect(jsonPath("$.messages[0].lu").value(true));

        // --- Signalement du vocal (sans réservation commune) puis écoute par l'administrateur
        long idPassagere = idDe("khady.vocaux@test.sn");
        appel(post("/api/signalements").header("Authorization", autre), """
                {"idUtilisateur":%d,"idMessage":%d,"motif":"COMPORTEMENT"}""".formatted(idPassagere, idVocal))
                .andExpect(status().isNotFound());
        appel(post("/api/signalements").header("Authorization", passagere), """
                {"idUtilisateur":%d,"idMessage":%d,"motif":"COMPORTEMENT"}""".formatted(idDe("ousmane.vocaux@test.sn"), idVocal))
                .andExpect(status().isNotFound());                                   // on ne signale pas son propre message
        long idSignalement = ((Number) JsonPath.read(appel(post("/api/signalements").header("Authorization", conducteur), """
                {"idUtilisateur":%d,"idMessage":%d,"motif":"COMPORTEMENT","description":"Propos insultants"}"""
                .formatted(idPassagere, idVocal)).andExpect(status().isCreated())
                .andReturn().getResponse().getContentAsString(), "$.id")).longValue();
        String admin = "Bearer " + jeton(appel(post("/api/auth/connexion"), """
                {"identifiant":"admin@test.local","motDePasse":"Admin-Test-2026!"}"""));
        mvc.perform(get("/api/admin/signalements/" + idSignalement).header("Authorization", admin))
                .andExpect(jsonPath("$.message.id").value(idVocal))
                .andExpect(jsonPath("$.message.type").value("VOCAL"))
                .andExpect(jsonPath("$.message.audioDisponible").value(true))
                .andExpect(jsonPath("$.idTrajet").value(idTrajet));
        assertThat(mvc.perform(get("/api/admin/signalements/" + idSignalement + "/audio").header("Authorization", admin))
                .andExpect(status().isOk()).andReturn().getResponse().getContentAsByteArray()).isEqualTo(vocal);
        mvc.perform(get("/api/admin/signalements/" + idSignalement + "/audio").header("Authorization", conducteur))
                .andExpect(status().isForbidden());

        // --- Réponse vocale du conducteur, puis suppression du compte de la passagère : son fichier est effacé
        long idReponse = ((Number) JsonPath.read(vocal(conducteur, idConv, EchantillonsAudio.oggOpus(2000), "r.ogg", null)
                .andExpect(status().isCreated()).andReturn().getResponse().getContentAsString(), "$.id")).longValue();
        Path fichierReponse = fichierDe(idReponse);
        jdbc.update("update utilisateur set statut = 'SUPPRESSION_DEMANDEE', date_suppression_demandee = ? where id_utilisateur = ?",
                LocalDateTime.now().minusDays(31), idPassagere);
        assertThat(anonymisation.anonymiser(idPassagere)).isTrue();
        assertThat(fichier).doesNotExist();
        assertThat(fichierReponse).exists();
        mvc.perform(get("/api/moi/conversations/" + idConv).header("Authorization", conducteur))
                .andExpect(jsonPath("$.messages[0].type").value("VOCAL"))
                .andExpect(jsonPath("$.messages[0].audioDisponible").value(false))
                .andExpect(jsonPath("$.messages[0].contenu").value("[message supprimé]"))
                .andExpect(jsonPath("$.messages[1].audioDisponible").value(true));
        mvc.perform(get(url).header("Authorization", conducteur)).andExpect(status().isNotFound());

        // --- Nettoyage : fichier orphelin ancien supprimé (un récent est gardé), vocal expiré 180 jours après le trajet
        Path dossier = fichier.getParent();
        Path orphelin = dossier.resolve("00000000-0000-0000-0000-000000000001.webm");
        Path recent = dossier.resolve("00000000-0000-0000-0000-000000000002.webm");
        Files.write(orphelin, new byte[]{1, 2, 3});
        Files.setLastModifiedTime(orphelin, FileTime.from(Instant.now().minus(2, ChronoUnit.HOURS)));
        Files.write(recent, new byte[]{1, 2, 3});
        jdbc.update("update trajet set date_heure_depart = ? where id_trajet = ?", LocalDateTime.now().minusDays(181), idTrajet);
        NettoyageVocaux.Bilan bilan = nettoyage.nettoyer(LocalDateTime.now(), Instant.now());
        assertThat(bilan.expires()).isGreaterThanOrEqualTo(1);
        assertThat(bilan.orphelins()).isGreaterThanOrEqualTo(1);
        assertThat(orphelin).doesNotExist();
        assertThat(recent).exists();
        assertThat(fichierReponse).doesNotExist();
        mvc.perform(get("/api/moi/conversations/" + idConv).header("Authorization", conducteur))
                .andExpect(jsonPath("$.messages[1].audioDisponible").value(false))
                .andExpect(jsonPath("$.messages[1].contenu").doesNotExist())
                .andExpect(jsonPath("$.messages[1].dureeMs").value(2000));
        Files.deleteIfExists(recent);
    }

    // ------------------------------------------------------------------ utilitaires

    private ResultActions vocal(String jeton, long idConv, byte[] octets, String nom, String formeOnde) throws Exception {
        var req = multipart("/api/moi/conversations/" + idConv + "/vocaux")
                .file(new MockMultipartFile("fichier", nom, "audio/webm", octets))
                .header("Authorization", jeton);
        if (formeOnde != null) req.param("formeOnde", formeOnde);
        return mvc.perform(req);
    }

    private Path fichierDe(long idMessage) {
        String nom = jdbc.queryForObject("select fichier_audio from message where id_message = ?", String.class, idMessage);
        return Path.of(props.stockage().repertoire()).toAbsolutePath().resolve("vocaux").resolve(nom);
    }

    private long compterMessages(long idConv) {
        Long n = jdbc.queryForObject("select count(*) from message where id_conversation = ?", Long.class, idConv);
        return n == null ? 0 : n;
    }

    private long idDe(String email) {
        Long id = jdbc.queryForObject("select id_utilisateur from utilisateur where email = ?", Long.class, email);
        return id == null ? 0 : id;
    }

    private String conducteurValide(String prenom, String nom, String email, String tel) throws Exception {
        String jeton = "Bearer " + inscrire(prenom, nom, email, tel, "HOMME").substring(7);
        appel(post("/api/moi/vehicules").header("Authorization", jeton), """
                {"immatriculation":"DK-%s","marque":"Peugeot","modele":"308","annee":2019,"puissanceFiscale":6,
                 "nombrePlaces":5,"typeEnergie":"DIESEL","consommationReelle":5.5}""".formatted(tel.substring(5)))
                .andExpect(status().isCreated());
        jdbc.update("update vehicule set statut_validation = 'VALIDE' where id_proprietaire = "
                + "(select id_utilisateur from utilisateur where email = ?)", email);
        jdbc.update("update utilisateur set conducteur_valide = true where email = ?", email);
        return "Bearer " + jeton(appel(post("/api/auth/refresh"), "{\"refreshToken\":\"" + dernierRefresh + "\"}"));
    }

    /** Renvoie « Bearer <jeton> ». */
    private String inscrire(String prenom, String nom, String email, String tel, String sexe) throws Exception {
        String ancien = ParcoursCompletTest.CodesDeTest.DERNIER_CODE.get(email);
        appel(post("/api/auth/inscription"), """
                {"prenom":"%s","nom":"%s","email":"%s","telephone":"%s","motDePasse":"MotDePasse2026","sexe":"%s"}"""
                .formatted(prenom, nom, email, tel, sexe))
                .andExpect(status().isCreated());
        String code = ParcoursCompletTest.CodesDeTest.attendreNouveauCode(email, ancien);
        return "Bearer " + jeton(appel(post("/api/auth/otp/verifier"), "{\"identifiant\":\"" + tel + "\",\"code\":\"" + code + "\"}"));
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
