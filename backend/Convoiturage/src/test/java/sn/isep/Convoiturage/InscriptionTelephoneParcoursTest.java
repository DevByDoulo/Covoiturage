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

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

/**
 * Connexion ou inscription par numéro de téléphone et code SMS (codes captés par un SmsSender de test).
 * Chaque test appelle depuis sa propre adresse IP, pour ne pas partager le plafond de demandes par IP.
 */
@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
@Import({ParcoursCompletTest.BaseDeTestPropre.class, ParcoursCompletTest.CodesDeTest.class})
class InscriptionTelephoneParcoursTest {

    @Autowired
    MockMvc mvc;

    @Autowired
    JdbcTemplate jdbc;

    @Test
    void nouveauNumeroCodePuisProfilPuisCompteConnecte() throws Exception {
        String ip = "10.20.0.1";
        demanderCode("77 610 02 01", ip)
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.etape").value("OTP_ENVOYE"))
                .andExpect(jsonPath("$.canal").value("SMS"))
                .andExpect(jsonPath("$.telephoneMasque").value("+221 77 *** ** 01"));
        String code = ParcoursCompletTest.CodesDeTest.attendreNouveauCode("+221776100201", null);

        String reponse = verifier("776100201", code, ip)
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.etape").value("PROFIL_REQUIS"))
                .andExpect(jsonPath("$.accessToken").doesNotExist())
                .andReturn().getResponse().getContentAsString();
        String jeton = JsonPath.read(reponse, "$.jetonInscription");
        assertEquals(0, compter("+221776100201"), "aucun compte avant la fin de l'inscription");

        // Mot de passe facultatif : absent ici.
        appel("/api/auth/telephone/terminer", """
                {"jeton":"%s","prenom":" Aminata ","nom":"Fall","sexe":"FEMME"}""".formatted(jeton), ip)
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.etape").value("CONNECTE"))
                .andExpect(jsonPath("$.accessToken").isNotEmpty())
                .andExpect(jsonPath("$.utilisateur.prenom").value("Aminata"))
                .andExpect(jsonPath("$.utilisateur.telephone").value("+221776100201"));
        assertEquals("ACTIF true true", jdbc.queryForObject("""
                select statut || ' ' || telephone_verifie || ' ' || (mot_de_passe is null)
                from utilisateur where telephone = '+221776100201'""", String.class));

        // Le même jeton ne crée pas un second compte.
        appel("/api/auth/telephone/terminer", """
                {"jeton":"%s","prenom":"Autre","nom":"Personne"}""".formatted(jeton), ip)
                .andExpect(status().isConflict());
        assertEquals(1, compter("+221776100201"));
    }

    @Test
    void numeroDejaConnuConnecteLeCompteExistantSansDoublon() throws Exception {
        String ip = "10.20.0.2";
        appel("/api/auth/inscription", """
                {"prenom":"Ibou","nom":"Sarr","email":"ibou.tel@test.sn","telephone":"776100202",
                 "motDePasse":"MotDePasse2026","sexe":"HOMME"}""", ip).andExpect(status().isCreated());
        String codeEmail = ParcoursCompletTest.CodesDeTest.attendreNouveauCode("ibou.tel@test.sn", null);
        appel("/api/auth/otp/verifier", "{\"identifiant\":\"776100202\",\"code\":\"" + codeEmail + "\"}", ip)
                .andExpect(status().isOk());
        vieillirCodes("+221776100202");

        // Le compte a un email, mais le code part par SMS : c'est le numéro qui est prouvé.
        demanderCode("776100202", ip).andExpect(jsonPath("$.canal").value("SMS"));
        String code = ParcoursCompletTest.CodesDeTest.attendreNouveauCode("+221776100202", null);
        verifier("+221776100202", code, ip)
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.etape").value("CONNECTE"))
                .andExpect(jsonPath("$.utilisateur.prenom").value("Ibou"))
                .andExpect(jsonPath("$.utilisateur.email").value("ibou.tel@test.sn"));
        assertEquals(1, compter("+221776100202"));
        assertEquals(Boolean.TRUE, jdbc.queryForObject(
                "select telephone_verifie from utilisateur where telephone = '+221776100202'", Boolean.class));

        // L'ancienne méthode (email + mot de passe) fonctionne toujours.
        appel("/api/auth/connexion", """
                {"identifiant":"ibou.tel@test.sn","motDePasse":"MotDePasse2026"}""", ip)
                .andExpect(jsonPath("$.etape").value("CONNECTE"));
    }

    @Test
    void mauvaisCodePuisTropDeTentatives() throws Exception {
        String ip = "10.20.0.3";
        demanderCode("776100203", ip).andExpect(status().isOk());
        String code = ParcoursCompletTest.CodesDeTest.attendreNouveauCode("+221776100203", null);
        String faux = code.equals("000000") ? "111111" : "000000";

        verifier("776100203", faux, ip)
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.tentativesRestantes").value(4));
        for (int restantes = 3; restantes >= 0; restantes--) {
            verifier("776100203", faux, ip).andExpect(jsonPath("$.tentativesRestantes").value(restantes));
        }
        // 5 essais épuisés : même le bon code est refusé, il faut un nouveau code.
        verifier("776100203", code, ip).andExpect(status().isTooManyRequests());
        // Et pas de nouveau code avant le délai de renvoi.
        demanderCode("776100203", ip)
                .andExpect(status().isTooManyRequests())
                .andExpect(jsonPath("$.motif").value("DELAI_RENVOI"));
        assertEquals(0, compter("+221776100203"));
    }

    @Test
    void jetonFalsifieEtNumeroEtrangerRefuses() throws Exception {
        String ip = "10.20.0.4";
        appel("/api/auth/telephone/terminer", """
                {"jeton":"KzIyMTc3NjEwMDIwNA.9999999999.signature","prenom":"Faux","nom":"Compte"}""", ip)
                .andExpect(status().isBadRequest());
        demanderCode("+33612345678", ip)
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.champ").value("telephone"));
        // Mot de passe facultatif, mais s'il est donné il suit la règle habituelle.
        appel("/api/auth/telephone/terminer", """
                {"jeton":"x","prenom":"A","nom":"B","motDePasse":"court"}""", ip)
                .andExpect(status().isBadRequest());
    }

    @Test
    void inscriptionAbandonneeAvecCeNumeroEstRepriseSansRienGarder() throws Exception {
        String ip = "10.20.0.5";
        // Quelqu'un a commencé une inscription avec ce numéro sans jamais saisir de code.
        appel("/api/auth/inscription", """
                {"prenom":"Intrus","nom":"X","email":"intrus.tel@test.sn","telephone":"776100205",
                 "motDePasse":"MotDePasse2026"}""", ip).andExpect(status().isCreated());
        vieillirCodes("+221776100205");

        demanderCode("776100205", ip).andExpect(status().isOk());
        String code = ParcoursCompletTest.CodesDeTest.attendreNouveauCode("+221776100205", null);
        String jeton = JsonPath.read(verifier("776100205", code, ip)
                .andExpect(jsonPath("$.etape").value("PROFIL_REQUIS"))
                .andReturn().getResponse().getContentAsString(), "$.jetonInscription");
        appel("/api/auth/telephone/terminer", """
                {"jeton":"%s","prenom":"Khady","nom":"Ba","sexe":"FEMME","motDePasse":"Teranga2026"}""".formatted(jeton), ip)
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.utilisateur.prenom").value("Khady"));

        assertEquals(1, compter("+221776100205"));
        appel("/api/auth/connexion", """
                {"identifiant":"intrus.tel@test.sn","motDePasse":"MotDePasse2026"}""", ip)
                .andExpect(status().isUnauthorized());
        appel("/api/auth/connexion", """
                {"identifiant":"776100205","motDePasse":"Teranga2026"}""", ip)
                .andExpect(jsonPath("$.etape").value("CONNECTE"));
    }

    @Test
    void plafondDeDemandesParAdresseIp() throws Exception {
        String ip = "10.20.0.6";
        for (int i = 0; i < 20; i++) demanderCode("123", ip).andExpect(status().isBadRequest());
        demanderCode("123", ip)
                .andExpect(status().isTooManyRequests())
                .andExpect(jsonPath("$.motif").value("LIMITE_IP"));
    }

    /** Recule les codes déjà envoyés à ce numéro, pour passer le délai de renvoi (60 s) sans attendre. */
    private void vieillirCodes(String telephone) {
        jdbc.update("update otp_code set date_creation = date_creation - interval '5 minutes' where telephone = ?", telephone);
    }

    private int compter(String telephone) {
        Integer n = jdbc.queryForObject("select count(*) from utilisateur where telephone = ?", Integer.class, telephone);
        return n == null ? 0 : n;
    }

    private ResultActions demanderCode(String telephone, String ip) throws Exception {
        return appel("/api/auth/telephone/code", "{\"telephone\":\"" + telephone + "\"}", ip);
    }

    private ResultActions verifier(String telephone, String code, String ip) throws Exception {
        return appel("/api/auth/telephone/verifier", "{\"telephone\":\"" + telephone + "\",\"code\":\"" + code + "\"}", ip);
    }

    private ResultActions appel(String url, String json, String ip) throws Exception {
        return mvc.perform(post(url).contentType(MediaType.APPLICATION_JSON).content(json)
                .with(requete -> {
                    requete.setRemoteAddr(ip);
                    return requete;
                }));
    }
}
