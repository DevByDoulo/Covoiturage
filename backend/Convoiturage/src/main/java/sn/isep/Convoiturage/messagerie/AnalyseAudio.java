package sn.isep.Convoiturage.messagerie;

import java.nio.charset.StandardCharsets;
import java.util.Optional;

/**
 * Reconnaît un fichier audio à ses octets (jamais à l'en-tête Content-Type du client) et en lit la durée dans le
 * conteneur, sans dépendance externe. Formats acceptés : WebM (Chrome, Edge, Firefox), Ogg Opus / Vorbis (Firefox),
 * MP4 / M4A (Safari, appli mobile), AAC brut (ADTS).
 */
final class AnalyseAudio {

    /** Format reconnu et durée lue dans le fichier (en millisecondes). */
    record Resultat(String typeMime, String extension, long dureeMs) {}

    private AnalyseAudio() {}

    /** Vide si le format n'est pas accepté ou si la durée ne peut pas être lue. */
    static Optional<Resultat> analyser(byte[] b) {
        try {
            if (b.length >= 4 && u8(b, 0) == 0x1A && u8(b, 1) == 0x45 && u8(b, 2) == 0xDF && u8(b, 3) == 0xA3) {
                return webm(b).map(d -> new Resultat("audio/webm", "webm", d));
            }
            if (b.length >= 4 && ascii(b, 0, 4).equals("OggS")) {
                return ogg(b).map(d -> new Resultat("audio/ogg", "ogg", d));
            }
            if (b.length >= 8 && ascii(b, 4, 4).equals("ftyp")) {
                return mp4(b).map(d -> new Resultat("audio/mp4", "m4a", d));
            }
            if (b.length >= 7 && u8(b, 0) == 0xFF && (u8(b, 1) & 0xF6) == 0xF0) {
                return adts(b).map(d -> new Resultat("audio/aac", "aac", d));
            }
        } catch (IndexOutOfBoundsException | ArithmeticException e) {
            return Optional.empty(); // fichier tronqué ou mal formé
        }
        return Optional.empty();
    }

    // ------------------------------------------------------------------ WebM (EBML)

    private static final long ID_SEGMENT = 0x18538067L, ID_CLUSTER = 0x1F43B675L, ID_INFO = 0x1549A966L,
            ID_BLOCKGROUP = 0xA0L, ID_TIMECODE = 0xE7L, ID_SIMPLEBLOCK = 0xA3L, ID_BLOCK = 0xA1L,
            ID_TIMECODESCALE = 0x2AD7B1L, ID_DURATION = 0x4489L, ID_DOCTYPE = 0x4282L, ID_EBML = 0x1A45DFA3L,
            ID_TRACKS = 0x1654AE6BL, ID_TRACKENTRY = 0xAEL, ID_TRACKTYPE = 0x83L;

    /**
     * Parcours linéaire : on entre dans les éléments conteneurs (Segment et Cluster sont souvent de taille inconnue
     * dans les enregistrements de MediaRecorder, qui n'écrit pas non plus la durée) et on retient le plus grand
     * horodatage de bloc. Refuse un WebM qui contient une piste vidéo.
     */
    private static Optional<Long> webm(byte[] b) {
        long echelleNs = 1_000_000, cluster = 0, maxBloc = -1;
        double dureeDeclaree = 0;
        boolean webm = false, video = false;
        int p = 0;
        while (p < b.length) {
            long[] id = vint(b, p, true);
            if (id == null) break;
            long[] taille = vint(b, p + (int) id[1], false);
            if (taille == null) break;
            int debut = p + (int) id[1] + (int) taille[1];
            boolean inconnue = taille[0] < 0;
            long t = taille[0];
            if (id[0] == ID_EBML || id[0] == ID_SEGMENT || id[0] == ID_CLUSTER || id[0] == ID_INFO
                    || id[0] == ID_BLOCKGROUP || id[0] == ID_TRACKS || id[0] == ID_TRACKENTRY) {
                p = debut; // conteneur : on lit ses enfants
                continue;
            }
            if (inconnue || debut + t > b.length) break; // fin du fichier (éventuellement tronquée)
            int n = (int) t;
            if (id[0] == ID_DOCTYPE) webm = ascii(b, debut, n).equals("webm");
            else if (id[0] == ID_TIMECODESCALE) echelleNs = uint(b, debut, n);
            else if (id[0] == ID_DURATION) dureeDeclaree = n == 4 ? Float.intBitsToFloat((int) uint(b, debut, 4))
                    : Double.longBitsToDouble(uint(b, debut, 8));
            else if (id[0] == ID_TIMECODE) cluster = uint(b, debut, n);
            else if (id[0] == ID_TRACKTYPE && uint(b, debut, n) == 1) video = true;
            else if (id[0] == ID_SIMPLEBLOCK || id[0] == ID_BLOCK) {
                long[] piste = vint(b, debut, false);
                if (piste != null && n >= piste[1] + 2) {
                    int o = debut + (int) piste[1];
                    short relatif = (short) ((u8(b, o) << 8) | u8(b, o + 1));
                    maxBloc = Math.max(maxBloc, cluster + relatif);
                }
            }
            p = debut + n;
        }
        if (!webm || video || echelleNs <= 0) return Optional.empty();
        if (dureeDeclaree > 0) return Optional.of(Math.round(dureeDeclaree * echelleNs / 1_000_000d));
        if (maxBloc < 0) return Optional.empty();
        // Le dernier bloc commence avant la fin : on ajoute la durée d'une trame Opus (20 ms).
        return Optional.of(Math.round(maxBloc * echelleNs / 1_000_000d) + 20);
    }

    /** Entier de taille variable EBML : {valeur, longueur} ; valeur -1 si « taille inconnue ». */
    private static long[] vint(byte[] b, int p, boolean garderMarqueur) {
        if (p >= b.length) return null;
        int premier = u8(b, p);
        int longueur = Integer.numberOfLeadingZeros(premier) - 23;
        if (premier == 0 || longueur > 8 || p + longueur > b.length) return null;
        long v = garderMarqueur ? premier : premier & (0xFF >> longueur);
        boolean tousUns = v == (0xFF >> longueur);
        for (int i = 1; i < longueur; i++) {
            v = (v << 8) | u8(b, p + i);
            tousUns &= u8(b, p + i) == 0xFF;
        }
        return new long[]{!garderMarqueur && tousUns ? -1 : v, longueur};
    }

    // ------------------------------------------------------------------ Ogg

    /** Durée = position (granule) de la dernière page, à 48 kHz pour Opus (moins le pré-décalage). */
    private static Optional<Long> ogg(byte[] b) {
        int tete = indexDe(b, "OpusHead", 0, Math.min(b.length, 200));
        long frequence, decalage = 0;
        if (tete >= 0) {
            frequence = 48_000;
            decalage = u8(b, tete + 10) | (u8(b, tete + 11) << 8);
        } else {
            int vorbis = indexDe(b, "\u0001vorbis", 0, Math.min(b.length, 200));
            if (vorbis < 0) return Optional.empty();
            frequence = le32(b, vorbis + 12);
        }
        for (int p = b.length - 27; p >= 0; p--) {
            if (b[p] == 'O' && b[p + 1] == 'g' && b[p + 2] == 'g' && b[p + 3] == 'S') {
                long granule = 0;
                for (int i = 7; i >= 0; i--) granule = (granule << 8) | u8(b, p + 6 + i);
                if (granule <= 0 || frequence <= 0) return Optional.empty();
                return Optional.of(Math.max(0, granule - decalage) * 1000 / frequence);
            }
        }
        return Optional.empty();
    }

    // ------------------------------------------------------------------ MP4 / M4A

    /**
     * Durée de l'en-tête « mvhd » ; pour un MP4 fragmenté (MediaRecorder de Safari, durée 0), somme des durées des
     * échantillons des fragments. Refuse un MP4 qui contient une piste vidéo.
     */
    private static Optional<Long> mp4(byte[] b) {
        Mp4 etat = new Mp4();
        boites(b, 0, b.length, etat);
        if (etat.video || !etat.son) return Optional.empty();
        if (etat.dureeMvhd > 0 && etat.echelleMvhd > 0) return Optional.of(etat.dureeMvhd * 1000 / etat.echelleMvhd);
        if (etat.dureeFragments > 0 && etat.echellePiste > 0) return Optional.of(etat.dureeFragments * 1000 / etat.echellePiste);
        return Optional.empty();
    }

    private static final class Mp4 {
        long echelleMvhd, dureeMvhd, echellePiste, dureeFragments, dureeParDefaut;
        boolean son, video;
    }

    private static void boites(byte[] b, int debut, int fin, Mp4 e) {
        int p = debut;
        while (p + 8 <= fin) {
            long taille = be32(b, p);
            String type = ascii(b, p + 4, 4);
            int entete = 8;
            if (taille == 1) {
                taille = be64(b, p + 8);
                entete = 16;
            } else if (taille == 0) {
                taille = fin - p;
            }
            if (taille < entete || p + taille > fin) taille = fin - p; // boîte tronquée : on lit ce qui reste
            int contenu = p + entete, finBoite = (int) (p + taille);
            switch (type) {
                case "moov", "trak", "mdia", "moof", "traf", "mvex" -> boites(b, contenu, finBoite, e);
                case "mvhd" -> {
                    if (u8(b, contenu) == 1) {
                        e.echelleMvhd = be32(b, contenu + 20);
                        e.dureeMvhd = be64(b, contenu + 24);
                    } else {
                        e.echelleMvhd = be32(b, contenu + 12);
                        e.dureeMvhd = be32(b, contenu + 16);
                    }
                }
                case "mdhd" -> e.echellePiste = be32(b, contenu + (u8(b, contenu) == 1 ? 20 : 12));
                case "hdlr" -> {
                    String genre = ascii(b, contenu + 8, 4);
                    if (genre.equals("soun")) e.son = true;
                    if (genre.equals("vide")) e.video = true;
                }
                case "trex" -> e.dureeParDefaut = be32(b, contenu + 12);
                case "tfhd" -> {
                    int drapeaux = (int) (be32(b, contenu) & 0xFFFFFF);
                    int o = contenu + 8;
                    if ((drapeaux & 0x01) != 0) o += 8;
                    if ((drapeaux & 0x02) != 0) o += 4;
                    if ((drapeaux & 0x08) != 0) e.dureeParDefaut = be32(b, o);
                }
                case "trun" -> {
                    int drapeaux = (int) (be32(b, contenu) & 0xFFFFFF);
                    long nombre = be32(b, contenu + 4);
                    if (nombre > b.length) throw new IndexOutOfBoundsException("trun incohérent");
                    int o = contenu + 8;
                    if ((drapeaux & 0x01) != 0) o += 4;
                    if ((drapeaux & 0x04) != 0) o += 4;
                    boolean avecDuree = (drapeaux & 0x100) != 0;
                    int pas = 4 * Integer.bitCount(drapeaux & 0xF00);
                    for (long i = 0; i < nombre; i++) {
                        e.dureeFragments += avecDuree ? be32(b, o) : e.dureeParDefaut;
                        o += pas;
                    }
                }
                default -> { }
            }
            p = finBoite;
        }
    }

    // ------------------------------------------------------------------ AAC (ADTS)

    private static final int[] FREQUENCES = {96000, 88200, 64000, 48000, 44100, 32000, 24000, 22050, 16000, 12000,
            11025, 8000, 7350};

    /** Chaque trame ADTS contient 1024 échantillons par bloc. */
    private static Optional<Long> adts(byte[] b) {
        long echantillons = 0;
        int frequence = 0, p = 0;
        while (p + 7 <= b.length && u8(b, p) == 0xFF && (u8(b, p + 1) & 0xF6) == 0xF0) {
            int indice = (u8(b, p + 2) >> 2) & 0x0F;
            if (indice >= FREQUENCES.length) return Optional.empty();
            frequence = FREQUENCES[indice];
            int longueur = ((u8(b, p + 3) & 0x03) << 11) | (u8(b, p + 4) << 3) | (u8(b, p + 5) >> 5);
            if (longueur < 7) return Optional.empty();
            echantillons += 1024L * ((u8(b, p + 6) & 0x03) + 1);
            p += longueur;
        }
        if (frequence == 0 || echantillons == 0) return Optional.empty();
        return Optional.of(echantillons * 1000 / frequence);
    }

    // ------------------------------------------------------------------ octets

    private static int u8(byte[] b, int p) {
        return b[p] & 0xFF;
    }

    private static long uint(byte[] b, int p, int n) {
        long v = 0;
        for (int i = 0; i < n; i++) v = (v << 8) | u8(b, p + i);
        return v;
    }

    private static long be32(byte[] b, int p) {
        return uint(b, p, 4);
    }

    private static long be64(byte[] b, int p) {
        return uint(b, p, 8);
    }

    private static long le32(byte[] b, int p) {
        return u8(b, p) | (u8(b, p + 1) << 8) | (u8(b, p + 2) << 16) | ((long) u8(b, p + 3) << 24);
    }

    private static String ascii(byte[] b, int p, int n) {
        if (p < 0 || n < 0 || p + n > b.length) return "";
        return new String(b, p, n, StandardCharsets.ISO_8859_1);
    }

    private static int indexDe(byte[] b, String motif, int debut, int fin) {
        byte[] m = motif.getBytes(StandardCharsets.ISO_8859_1);
        for (int i = debut; i + m.length <= fin; i++) {
            int j = 0;
            while (j < m.length && b[i + j] == m[j]) j++;
            if (j == m.length) return i;
        }
        return -1;
    }
}
