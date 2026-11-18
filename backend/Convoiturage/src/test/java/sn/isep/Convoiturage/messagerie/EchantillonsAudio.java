package sn.isep.Convoiturage.messagerie;

import java.io.ByteArrayOutputStream;
import java.nio.charset.StandardCharsets;

/**
 * Petits fichiers audio construits octet par octet pour les tests : seuls les en-têtes lus par {@link AnalyseAudio}
 * sont exacts (le contenu sonore est du remplissage).
 */
public final class EchantillonsAudio {

    private EchantillonsAudio() {}

    /** AAC brut (ADTS) à 16 kHz : 1024 échantillons par trame, soit 64 ms. */
    public static byte[] aac(long dureeMs) {
        int trames = (int) Math.ceil(dureeMs * 16_000 / 1000.0 / 1024);
        ByteArrayOutputStream out = new ByteArrayOutputStream();
        int longueur = 7 + 20;
        for (int i = 0; i < trames; i++) {
            out.writeBytes(new byte[]{(byte) 0xFF, (byte) 0xF1,
                    (byte) ((1 << 6) | (8 << 2)),                        // profil LC, fréquence n° 8 (16 kHz)
                    (byte) ((1 << 6) | ((longueur >> 11) & 0x03)),       // 1 canal
                    (byte) ((longueur >> 3) & 0xFF),
                    (byte) (((longueur & 0x07) << 5) | 0x1F),
                    (byte) 0xFC});                                       // 1 bloc par trame
            out.writeBytes(new byte[20]);
        }
        return out.toByteArray();
    }

    /** Ogg Opus : OpusHead (pré-décalage 312) puis une page de données dont la position vaut la durée à 48 kHz. */
    public static byte[] oggOpus(long dureeMs) {
        ByteArrayOutputStream out = new ByteArrayOutputStream();
        byte[] tete = new byte[19];
        System.arraycopy("OpusHead".getBytes(StandardCharsets.US_ASCII), 0, tete, 0, 8);
        tete[8] = 1;
        tete[9] = 1;
        tete[10] = (byte) (312 & 0xFF);
        tete[11] = (byte) (312 >> 8);
        out.writeBytes(pageOgg(0, tete));
        out.writeBytes(pageOgg(dureeMs * 48 + 312, new byte[50]));
        return out.toByteArray();
    }

    private static byte[] pageOgg(long granule, byte[] donnees) {
        ByteArrayOutputStream p = new ByteArrayOutputStream();
        p.writeBytes("OggS".getBytes(StandardCharsets.US_ASCII));
        p.write(0);
        p.write(0);
        for (int i = 0; i < 8; i++) p.write((int) (granule >> (8 * i)) & 0xFF);
        p.writeBytes(new byte[12]); // numéro de flux, de page, somme de contrôle
        p.write(1);
        p.write(donnees.length);
        p.writeBytes(donnees);
        return p.toByteArray();
    }

    /**
     * WebM tel que l'écrit MediaRecorder : Segment et Cluster de taille inconnue, sans durée déclarée ; un bloc
     * toutes les 20 ms.
     */
    public static byte[] webm(long dureeMs) {
        ByteArrayOutputStream out = new ByteArrayOutputStream();
        out.writeBytes(element(0x1A45DFA3, element(0x4282, "webm".getBytes(StandardCharsets.US_ASCII))));
        out.writeBytes(new byte[]{0x18, 0x53, (byte) 0x80, 0x67, 0x01, (byte) 0xFF, (byte) 0xFF, (byte) 0xFF,
                (byte) 0xFF, (byte) 0xFF, (byte) 0xFF, (byte) 0xFF});                      // Segment, taille inconnue
        out.writeBytes(element(0x1549A966, element(0x2AD7B1, new byte[]{0x0F, 0x42, 0x40}))); // échelle 1 ms
        out.writeBytes(element(0x1654AE6B, element(0xAE, element(0x83, new byte[]{2}))));   // piste audio
        for (long debut = 0; debut < dureeMs; debut += 10_000) {
            out.writeBytes(new byte[]{0x1F, 0x43, (byte) 0xB6, 0x75, 0x01, (byte) 0xFF, (byte) 0xFF, (byte) 0xFF,
                    (byte) 0xFF, (byte) 0xFF, (byte) 0xFF, (byte) 0xFF});                  // Cluster, taille inconnue
            out.writeBytes(element(0xE7, new byte[]{(byte) (debut >> 16), (byte) (debut >> 8), (byte) debut}));
            for (long t = 0; t < 10_000 && debut + t + 20 <= dureeMs; t += 20) {
                out.writeBytes(element(0xA3, new byte[]{(byte) 0x81, (byte) (t >> 8), (byte) t, (byte) 0x80, 1, 2, 3}));
            }
        }
        return out.toByteArray();
    }

    private static byte[] element(int id, byte[] donnees) {
        ByteArrayOutputStream e = new ByteArrayOutputStream();
        int octetsId = id > 0xFFFFFF ? 4 : id > 0xFFFF ? 3 : id > 0xFF ? 2 : 1;
        for (int i = octetsId - 1; i >= 0; i--) e.write((id >> (8 * i)) & 0xFF);
        e.writeBytes(new byte[]{0x10, 0, 0, 0}); // taille sur 4 octets
        byte[] r = e.toByteArray();
        int n = donnees.length;
        r[octetsId + 1] = (byte) (n >> 16);
        r[octetsId + 2] = (byte) (n >> 8);
        r[octetsId + 3] = (byte) n;
        ByteArrayOutputStream fin = new ByteArrayOutputStream();
        fin.writeBytes(r);
        fin.writeBytes(donnees);
        return fin.toByteArray();
    }

    /** M4A : ftyp + moov (mvhd avec échelle 1000, piste de type « soun » ou « vide »). */
    public static byte[] m4a(long dureeMs, String typePiste) {
        byte[] mvhd = new byte[100];
        mvhd[15] = (byte) 0xE8;
        mvhd[14] = 0x03;                                     // échelle 1000
        for (int i = 0; i < 4; i++) mvhd[16 + i] = (byte) (dureeMs >> (8 * (3 - i)));
        byte[] hdlr = new byte[24];
        System.arraycopy(typePiste.getBytes(StandardCharsets.US_ASCII), 0, hdlr, 8, 4);
        byte[] moov = boite("moov", concat(boite("mvhd", mvhd), boite("trak", boite("mdia", boite("hdlr", hdlr)))));
        return concat(boite("ftyp", "M4A \0\0\0\0isom".getBytes(StandardCharsets.US_ASCII)), moov);
    }

    private static byte[] boite(String type, byte[] contenu) {
        int n = contenu.length + 8;
        return concat(new byte[]{(byte) (n >> 24), (byte) (n >> 16), (byte) (n >> 8), (byte) n},
                type.getBytes(StandardCharsets.US_ASCII), contenu);
    }

    private static byte[] concat(byte[]... parties) {
        ByteArrayOutputStream out = new ByteArrayOutputStream();
        for (byte[] p : parties) out.writeBytes(p);
        return out.toByteArray();
    }
}
