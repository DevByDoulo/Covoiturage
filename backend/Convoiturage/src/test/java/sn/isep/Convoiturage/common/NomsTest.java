package sn.isep.Convoiturage.common;

import jakarta.validation.Validation;
import jakarta.validation.Validator;
import org.junit.jupiter.api.Test;
import sn.isep.Convoiturage.auth.AuthDtos.FinInscriptionTelephoneRequete;
import sn.isep.Convoiturage.auth.AuthDtos.InscriptionRequete;
import sn.isep.Convoiturage.utilisateur.UtilisateurDtos.ModificationProfilRequete;

import java.util.List;
import java.util.Set;
import java.util.stream.Collectors;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;

/** Prénom et nom : des lettres seulement (accents, espaces, tirets et apostrophes admis), à l'inscription et au profil. */
class NomsTest {

    private final Validator validator = Validation.buildDefaultValidatorFactory().getValidator();

    private static final String MOT_DE_PASSE = "MotDePasse2026";

    private Set<String> champsRefuses(Object requete) {
        return validator.validate(requete).stream().map(v -> v.getPropertyPath().toString()).collect(Collectors.toSet());
    }

    @Test
    void accepteLesNomsDeVraiesPersonnes() {
        for (String nom : List.of("Awa", "Éloïse", "Marie-Claire", "N'Diaye", "N’Diaye", "Ba Fall", "Çelik", " Aminata ")) {
            assertTrue(champsRefuses(new InscriptionRequete(nom, nom, "a@test.sn", "771234567", MOT_DE_PASSE, null)).isEmpty(), nom);
        }
    }

    @Test
    void refuseChiffresEtSymbolesALInscription() {
        for (String nom : List.of("Awa2", "123", "Awa!", "@Diop", "Awa_Diop", "-Awa", "---", "Awa.D")) {
            assertEquals(Set.of("prenom", "nom"),
                    champsRefuses(new InscriptionRequete(nom, nom, "a@test.sn", "771234567", MOT_DE_PASSE, null)), nom);
        }
    }

    @Test
    void refuseAussiALaFinDeLInscriptionParTelephone() {
        assertEquals(Set.of("prenom"), champsRefuses(new FinInscriptionTelephoneRequete("jeton", "Awa7", "Diop", null, null)));
        assertEquals(Set.of("nom"), champsRefuses(new FinInscriptionTelephoneRequete("jeton", "Awa", "D1op", null, null)));
        assertTrue(champsRefuses(new FinInscriptionTelephoneRequete("jeton", "Awa", "Diop", null, null)).isEmpty());
    }

    @Test
    void refuseAussiAuProfil() {
        assertEquals(Set.of("prenom", "nom"), champsRefuses(new ModificationProfilRequete("Awa1", "Diop#", null, null)));
        assertTrue(champsRefuses(new ModificationProfilRequete("Marie-Claire", "N'Diaye", null, null)).isEmpty());
    }

    @Test
    void leMessageEstExplicite() {
        var violations = validator.validate(new ModificationProfilRequete("Awa1", "Diop", null, null));
        assertEquals(Noms.MESSAGE, violations.iterator().next().getMessage());
    }
}
