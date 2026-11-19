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
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.ResultActions;
import sn.isep.Convoiturage.auth.AppleTokenVerifier;
import sn.isep.Convoiturage.auth.AppleTokenVerifier.CompteApple;
import sn.isep.Convoiturage.auth.GoogleTokenVerifier;
import sn.isep.Convoiturage.auth.GoogleTokenVerifier.CompteGoogle;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

/**
 * Connexion et inscription avec Apple et Google (jetons simulés : la vérification auprès d'Apple / Google est
 * remplacée). Règle principale : pas de session tant que le compte n'a pas de numéro de téléphone confirmé par code.
 */
@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
@Import({ParcoursCompletTest.BaseDeTestPropre.class, ParcoursCompletTest.CodesDeTest.class})
class ConnexionExterneParcoursTest {

    @Autowired
    MockMvc mvc;

    @Autowired
    JdbcTemplate jdbc;

    @MockitoBean
    AppleTokenVerifier apple;

    @MockitoBean
    GoogleTokenVerifier google;

    @Test
    void inscriptionAppleNumeroObligatoirePuisConnexionDirecte() throws Exception {
        when(apple.verifier("jeton-apple-fatou")).thenReturn(new CompteApple("001234.fatou", "fatou.apple@test.sn", true));

        // 1er passage : compte créé (nom transmis par le site), mais pas de session sans numéro.
        appelApple("{\"idToken\":\"jeton-apple-fatou\",\"prenom\":\"Fatou\",\"nom\":\"Sow\"}")
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.etape").value("TELEPHONE_REQUIS"))
                .andExpect(jsonPath("$.accessToken").doesNotExist());
        assertEquals("Fatou Sow EN_ATTENTE_OTP", jdbc.queryForObject(
                "select prenom || ' ' || nom || ' ' || statut from utilisateur where apple_id = '001234.fatou'", String.class));

        // Sans numéro, on peut réessayer autant qu'on veut : toujours pas de session.
        appelApple("{\"idToken\":\"jeton-apple-fatou\"}").andExpect(jsonPath("$.etape").value("TELEPHONE_REQUIS"));

        // Numéro + sexe : un code est envoyé ; la session s'ouvre après le code.
        String reponse = appelApple("""
                {"idToken":"jeton-apple-fatou","telephone":"756100001","sexe":"FEMME"}""")
                .andExpect(jsonPath("$.etape").value("OTP_ENVOYE"))
                .andExpect(jsonPath("$.accessToken").doesNotExist())
                .andReturn().getResponse().getContentAsString();
        verifierCode(reponse, "fatou.apple@test.sn", "+221756100001").andExpect(jsonPath("$.etape").value("CONNECTE"))
                .andExpect(jsonPath("$.utilisateur.prenom").value("Fatou"))
                .andExpect(jsonPath("$.utilisateur.sexe").value("FEMME"));

        // Passages suivants : connexion directe, sans le nom (Apple ne le renvoie plus).
        appelApple("{\"idToken\":\"jeton-apple-fatou\"}")
                .andExpect(jsonPath("$.etape").value("CONNECTE"))
                .andExpect(jsonPath("$.accessToken").isNotEmpty())
                .andExpect(jsonPath("$.utilisateur.nom").value("Sow"));
    }

    @Test
    void googleSansNumeroDemandeLeNumeroEtRefuseUnNumeroDejaPris() throws Exception {
        // Compte existant (inscription classique) avec son numéro.
        appel("/api/auth/inscription", """
                {"prenom":"Modou","nom":"Ndiaye","email":"modou.ext@test.sn","telephone":"756100002",
                 "motDePasse":"MotDePasse2026","sexe":"HOMME"}""").andExpect(status().isCreated());

        when(google.verifier("jeton-google-awa"))
                .thenReturn(new CompteGoogle("g-awa", "awa.google@test.sn", true, "Awa", "Diop"));
        appel("/api/auth/google", "{\"idToken\":\"jeton-google-awa\"}")
                .andExpect(jsonPath("$.etape").value("TELEPHONE_REQUIS"))
                .andExpect(jsonPath("$.accessToken").doesNotExist());

        // Numéro d'un autre compte : refusé, sous le champ téléphone.
        appel("/api/auth/google", "{\"idToken\":\"jeton-google-awa\",\"telephone\":\"756100002\",\"sexe\":\"FEMME\"}")
                .andExpect(status().isConflict())
                .andExpect(jsonPath("$.champ").value("telephone"));

        String reponse = appel("/api/auth/google", "{\"idToken\":\"jeton-google-awa\",\"telephone\":\"756100003\",\"sexe\":\"FEMME\"}")
                .andExpect(jsonPath("$.etape").value("OTP_ENVOYE"))
                .andReturn().getResponse().getContentAsString();
        verifierCode(reponse, "awa.google@test.sn", "+221756100003").andExpect(jsonPath("$.etape").value("CONNECTE"));
    }

    @Test
    void appleAvecEmailDUnCompteExistantLeLieSansRedemanderLeNumero() throws Exception {
        String ancien = ParcoursCompletTest.CodesDeTest.DERNIER_CODE.get("binta.ext@test.sn");
        appel("/api/auth/inscription", """
                {"prenom":"Binta","nom":"Kane","email":"binta.ext@test.sn","telephone":"756100004",
                 "motDePasse":"MotDePasse2026","sexe":"FEMME"}""").andExpect(status().isCreated());
        String code = ParcoursCompletTest.CodesDeTest.attendreNouveauCode("binta.ext@test.sn", ancien);
        appel("/api/auth/otp/verifier", "{\"identifiant\":\"756100004\",\"code\":\"" + code + "\"}").andExpect(status().isOk());

        when(apple.verifier("jeton-apple-binta")).thenReturn(new CompteApple("001234.binta", "binta.ext@test.sn", true));
        appelApple("{\"idToken\":\"jeton-apple-binta\",\"prenom\":\"B\",\"nom\":\"K\"}")
                .andExpect(jsonPath("$.etape").value("CONNECTE"))
                .andExpect(jsonPath("$.utilisateur.prenom").value("Binta"));
        assertEquals("001234.binta", jdbc.queryForObject(
                "select apple_id from utilisateur where email = 'binta.ext@test.sn'", String.class));
    }

    /** Saisit le code reçu (par email ou par SMS selon le canal annoncé). */
    private ResultActions verifierCode(String reponseOtp, String email, String telephone) throws Exception {
        String canal = JsonPath.read(reponseOtp, "$.canal");
        String destinataire = "EMAIL".equals(canal) ? email : telephone;
        String code = ParcoursCompletTest.CodesDeTest.attendreNouveauCode(destinataire, null);
        return appel("/api/auth/otp/verifier", "{\"identifiant\":\"" + telephone + "\",\"code\":\"" + code + "\"}")
                .andExpect(status().isOk());
    }

    private ResultActions appelApple(String json) throws Exception {
        return appel("/api/auth/apple", json);
    }

    private ResultActions appel(String url, String json) throws Exception {
        return mvc.perform(post(url).contentType(MediaType.APPLICATION_JSON).content(json));
    }
}
