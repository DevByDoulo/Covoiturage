package sn.isep.Convoiturage.common.stockage;

import org.springframework.core.io.PathResource;
import org.springframework.core.io.Resource;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;
import sn.isep.Convoiturage.common.ApiException;
import sn.isep.Convoiturage.common.AppProperties;

import java.io.IOException;
import java.io.InputStream;
import java.io.UncheckedIOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.StandardCopyOption;
import java.util.Arrays;
import java.util.Set;
import java.util.UUID;
import java.util.regex.Pattern;

/**
 * Stockage local des fichiers téléversés. Le type est déterminé par les premiers octets
 * (et non par l'en-tête Content-Type fourni par le client), et le nom est toujours généré.
 */
@Service
public class StockageService {

    public enum Dossier { DOCUMENTS, PHOTOS }

    public record FichierStocke(String nom, String typeMime) {}

    private static final Set<String> TYPES_DOCUMENTS = Set.of("image/jpeg", "image/png", "application/pdf");
    private static final Set<String> TYPES_PHOTOS = Set.of("image/jpeg", "image/png", "image/webp");
    private static final Pattern NOM_VALIDE = Pattern.compile("^[0-9a-f\\-]{36}\\.(jpg|png|pdf|webp)$");

    private final Path racine;

    public StockageService(AppProperties props) {
        this.racine = Path.of(props.stockage().repertoire()).toAbsolutePath().normalize();
    }

    public FichierStocke enregistrer(MultipartFile fichier, Dossier dossier) {
        if (fichier == null || fichier.isEmpty()) throw ApiException.badRequest("Fichier manquant");
        try {
            byte[] entete;
            try (InputStream in = fichier.getInputStream()) {
                entete = in.readNBytes(12);
            }
            String mime = detecterType(entete);
            Set<String> autorises = dossier == Dossier.DOCUMENTS ? TYPES_DOCUMENTS : TYPES_PHOTOS;
            if (mime == null || !autorises.contains(mime)) {
                throw ApiException.badRequest("Format non accepté. Formats autorisés : " + String.join(", ", autorises));
            }
            String nom = UUID.randomUUID() + "." + extension(mime);
            Path cible = repertoire(dossier).resolve(nom);
            try (InputStream in = fichier.getInputStream()) {
                Files.copy(in, cible, StandardCopyOption.REPLACE_EXISTING);
            }
            return new FichierStocke(nom, mime);
        } catch (IOException e) {
            throw new UncheckedIOException("Échec de l'enregistrement du fichier", e);
        }
    }

    public Resource charger(String nom, Dossier dossier) {
        if (nom == null || !NOM_VALIDE.matcher(nom).matches()) throw ApiException.notFound("Fichier introuvable");
        Path chemin = repertoire(dossier).resolve(nom).normalize();
        if (!chemin.startsWith(racine) || !Files.isRegularFile(chemin)) throw ApiException.notFound("Fichier introuvable");
        return new PathResource(chemin);
    }

    public static String typeMime(String nom) {
        if (nom.endsWith(".pdf")) return "application/pdf";
        if (nom.endsWith(".png")) return "image/png";
        if (nom.endsWith(".webp")) return "image/webp";
        return "image/jpeg";
    }

    private Path repertoire(Dossier dossier) throws UncheckedIOException {
        Path dir = racine.resolve(dossier.name().toLowerCase());
        try {
            Files.createDirectories(dir);
        } catch (IOException e) {
            throw new UncheckedIOException(e);
        }
        return dir;
    }

    static String detecterType(byte[] b) {
        if (b.length >= 3 && (b[0] & 0xFF) == 0xFF && (b[1] & 0xFF) == 0xD8 && (b[2] & 0xFF) == 0xFF) return "image/jpeg";
        if (b.length >= 8 && Arrays.equals(Arrays.copyOf(b, 8),
                new byte[]{(byte) 0x89, 'P', 'N', 'G', 0x0D, 0x0A, 0x1A, 0x0A})) return "image/png";
        if (b.length >= 4 && b[0] == '%' && b[1] == 'P' && b[2] == 'D' && b[3] == 'F') return "application/pdf";
        if (b.length >= 12 && b[0] == 'R' && b[1] == 'I' && b[2] == 'F' && b[3] == 'F'
                && b[8] == 'W' && b[9] == 'E' && b[10] == 'B' && b[11] == 'P') return "image/webp";
        return null;
    }

    private static String extension(String mime) {
        return switch (mime) {
            case "image/png" -> "png";
            case "application/pdf" -> "pdf";
            case "image/webp" -> "webp";
            default -> "jpg";
        };
    }
}
