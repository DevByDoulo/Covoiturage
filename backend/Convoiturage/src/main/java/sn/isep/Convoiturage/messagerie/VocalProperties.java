package sn.isep.Convoiturage.messagerie;

import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.util.unit.DataSize;

import java.time.Duration;

/**
 * Messages vocaux (préfixe {@code app.messagerie.vocal}). Les fichiers sont rangés dans le dossier « vocaux » de
 * {@code app.stockage.repertoire}.
 *
 * @param tailleMax    taille maximale d'un fichier
 * @param dureeMin     en dessous, l'enregistrement est refusé (un appui trop court)
 * @param dureeMax     durée maximale, lue dans le fichier
 * @param conservation durée de conservation du fichier après le départ du trajet ; ensuite il est effacé
 */
@ConfigurationProperties("app.messagerie.vocal")
public record VocalProperties(DataSize tailleMax, Duration dureeMin, Duration dureeMax, Duration conservation) {

    public VocalProperties {
        if (tailleMax == null) tailleMax = DataSize.ofMegabytes(3);
        if (dureeMin == null) dureeMin = Duration.ofSeconds(1);
        if (dureeMax == null) dureeMax = Duration.ofMinutes(5);
        if (conservation == null) conservation = Duration.ofDays(180);
    }
}
