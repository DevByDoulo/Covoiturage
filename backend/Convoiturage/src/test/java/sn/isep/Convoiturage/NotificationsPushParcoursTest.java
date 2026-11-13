package sn.isep.Convoiturage;

import com.jayway.jsonpath.JsonPath;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.context.TestConfiguration;
import org.springframework.boot.webmvc.test.autoconfigure.AutoConfigureMockMvc;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Import;
import org.springframework.context.annotation.Primary;
import org.springframework.http.MediaType;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.ResultActions;
import org.springframework.test.web.servlet.request.MockHttpServletRequestBuilder;
import org.springframework.transaction.support.TransactionTemplate;
import sn.isep.Convoiturage.notification.NotificationService;
import sn.isep.Convoiturage.notification.PlateformeAppareil;
import sn.isep.Convoiturage.notification.Priorite;
import sn.isep.Convoiturage.notification.PushSender;
import sn.isep.Convoiturage.notification.TypeNotification;
import sn.isep.Convoiturage.utilisateur.UtilisateurRepository;

import java.util.List;
import java.util.Map;
import java.util.concurrent.CopyOnWriteArrayList;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

/**
 * Module 06 — notifications push (envoi simulé) : enregistrement idempotent des appareils, envoi à tous les appareils
 * du destinataire après validation de la transaction (rien si elle est annulée), jeton rejeté par FCM supprimé,
 * préférence « push coupés », suppression à la déconnexion et jeton repris par un autre compte.
 */
@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
@Import({ParcoursCompletTest.BaseDeTestPropre.class, ParcoursCompletTest.CodesDeTest.class,
        NotificationsPushParcoursTest.PushCapture.class})
class NotificationsPushParcoursTest {

    record PushRecu(String jeton, PlateformeAppareil plateforme, String titre, Map<String, String> donnees) {}

    @TestConfiguration
    static class PushCapture {
        static final List<PushRecu> RECUS = new CopyOnWriteArrayList<>();

        /** Les jetons qui commencent par « invalide » sont rejetés, comme FCM le fait pour une appli désinstallée. */
        @Bean
        @Primary
        PushSender pushCapture() {
            return (jeton, plateforme, titre, contenu, donnees) -> {
                RECUS.add(new PushRecu(jeton, plateforme, titre, donnees));
                return jeton.startsWith("invalide") ? PushSender.Resultat.JETON_INVALIDE : PushSender.Resultat.ENVOYE;
            };
        }
    }

    @Autowired
    MockMvc mvc;

    @Autowired
    JdbcTemplate jdbc;

    @Autowired
    NotificationService notifications;

    @Autowired
    UtilisateurRepository utilisateurs;

    @Autowired
    TransactionTemplate transactions;

    @Test
    void pushEnvoyesATousLesAppareils() throws Exception {
        String awa = inscrire("Awa", "Push", "awa.push@test.sn", "773335566");
        String modou = inscrire("Modou", "Push", "modou.push@test.sn", "763335566");
        long idAwa = jdbc.queryForObject("select id_utilisateur from utilisateur where email = 'awa.push@test.sn'", Long.class);

        // Enregistrement : idempotent, plateforme obligatoire
        appareil(awa, "android-awa", "ANDROID").andExpect(status().isNoContent());
        appareil(awa, "android-awa", "ANDROID").andExpect(status().isNoContent());
        appareil(awa, "web-awa", "WEB").andExpect(status().isNoContent());
        appareil(awa, "invalide-awa", "ANDROID").andExpect(status().isNoContent());
        appel(post("/api/moi/appareils").header("Authorization", awa), "{\"jeton\":\"x\"}").andExpect(status().isBadRequest());
        assertThat(appareilsDe(idAwa)).isEqualTo(3);

        // Une notification : un push par appareil, avec le lien de l'écran ; le jeton rejeté est supprimé
        notifier(idAwa, "Réservation confirmée");
        List<PushRecu> recus = attendrePush("Réservation confirmée", 3);
        assertThat(recus).extracting(PushRecu::jeton).containsExactlyInAnyOrder("android-awa", "web-awa", "invalide-awa");
        assertThat(recus).allSatisfy(p -> {
            assertThat(p.donnees()).containsEntry("lien", "/trajets/42").containsEntry("type", "RESERVATION_CONFIRMEE");
            assertThat(p.donnees()).containsKey("notificationId");
        });
        assertThat(recus).filteredOn(p -> p.jeton().equals("web-awa")).extracting(PushRecu::plateforme)
                .containsExactly(PlateformeAppareil.WEB);
        for (int i = 0; i < 100 && appareilsDe(idAwa) != 2; i++) Thread.sleep(50);
        assertThat(appareilsDe(idAwa)).isEqualTo(2);

        // Transaction annulée : la notification n'existe pas, aucun push ne part
        transactions.executeWithoutResult(tx -> {
            notifications.notifier(utilisateurs.getReferenceById(idAwa), TypeNotification.RESERVATION_CONFIRMEE,
                    Priorite.NORMALE, "Annulée avant envoi", "Contenu", "/trajets/42");
            tx.setRollbackOnly();
        });

        // Préférence : push coupés, la notification reste visible dans l'application
        mvc.perform(get("/api/moi/notifications/preferences").header("Authorization", awa))
                .andExpect(jsonPath("$.pushActive").value(true));
        appel(put("/api/moi/notifications/preferences").header("Authorization", awa), "{\"pushActive\":false}")
                .andExpect(status().isOk()).andExpect(jsonPath("$.pushActive").value(false));
        notifier(idAwa, "Sans push");
        mvc.perform(get("/api/moi/notifications").header("Authorization", awa))
                .andExpect(jsonPath("$.content[0].titre").value("Sans push"));
        Thread.sleep(300);
        assertThat(PushCapture.RECUS).extracting(PushRecu::titre).doesNotContain("Sans push", "Annulée avant envoi");
        appel(put("/api/moi/notifications/preferences").header("Authorization", awa), "{\"pushActive\":true}")
                .andExpect(status().isOk());

        // Déconnexion : seul le propriétaire retire son jeton
        mvc.perform(delete("/api/moi/appareils/web-awa").header("Authorization", modou)).andExpect(status().isNoContent());
        assertThat(appareilsDe(idAwa)).isEqualTo(2);
        mvc.perform(delete("/api/moi/appareils/web-awa").header("Authorization", awa)).andExpect(status().isNoContent());
        assertThat(appareilsDe(idAwa)).isEqualTo(1);

        // Le téléphone change de compte : le jeton suit la personne connectée
        appareil(modou, "android-awa", "ANDROID").andExpect(status().isNoContent());
        assertThat(appareilsDe(idAwa)).isZero();
        notifier(idAwa, "Plus d'appareil");
        Thread.sleep(300);
        assertThat(PushCapture.RECUS).extracting(PushRecu::titre).doesNotContain("Plus d'appareil");
    }

    // ------------------------------------------------------------------ utilitaires

    private void notifier(long idUtilisateur, String titre) {
        transactions.executeWithoutResult(tx -> notifications.notifier(utilisateurs.getReferenceById(idUtilisateur),
                TypeNotification.RESERVATION_CONFIRMEE, Priorite.NORMALE, titre, "Contenu", "/trajets/42"));
    }

    private List<PushRecu> attendrePush(String titre, int nombre) throws InterruptedException {
        for (int i = 0; i < 100; i++) {
            List<PushRecu> recus = PushCapture.RECUS.stream().filter(p -> p.titre().equals(titre)).toList();
            if (recus.size() >= nombre) return recus;
            Thread.sleep(50);
        }
        throw new AssertionError("Push « " + titre + " » non reçus");
    }

    private int appareilsDe(long idUtilisateur) {
        return jdbc.queryForObject("select count(*) from appareil where id_utilisateur = ?", Integer.class, idUtilisateur);
    }

    private ResultActions appareil(String jeton, String jetonPush, String plateforme) throws Exception {
        return appel(post("/api/moi/appareils").header("Authorization", jeton),
                "{\"jeton\":\"" + jetonPush + "\",\"plateforme\":\"" + plateforme + "\"}");
    }

    /** Renvoie « Bearer <jeton> ». */
    private String inscrire(String prenom, String nom, String email, String tel) throws Exception {
        String ancien = ParcoursCompletTest.CodesDeTest.DERNIER_CODE.get(email);
        appel(post("/api/auth/inscription"), """
                {"prenom":"%s","nom":"%s","email":"%s","telephone":"%s","motDePasse":"MotDePasse2026","sexe":"FEMME"}"""
                .formatted(prenom, nom, email, tel))
                .andExpect(status().isCreated());
        String code = ParcoursCompletTest.CodesDeTest.attendreNouveauCode(email, ancien);
        String corps = appel(post("/api/auth/otp/verifier"), "{\"identifiant\":\"" + tel + "\",\"code\":\"" + code + "\"}")
                .andExpect(status().isOk()).andReturn().getResponse().getContentAsString();
        return "Bearer " + JsonPath.read(corps, "$.accessToken");
    }

    private ResultActions appel(MockHttpServletRequestBuilder req, String json) throws Exception {
        return mvc.perform(req.contentType(MediaType.APPLICATION_JSON).content(json));
    }
}
