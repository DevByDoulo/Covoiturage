package sn.isep.Convoiturage.messagerie;

import org.junit.jupiter.api.Test;

import java.nio.charset.StandardCharsets;
import java.util.Arrays;

import static org.assertj.core.api.Assertions.assertThat;

/** Reconnaissance du format par les octets et lecture de la durée dans chaque conteneur accepté. */
class AnalyseAudioTest {

    @Test
    void aacBrut() {
        AnalyseAudio.Resultat r = AnalyseAudio.analyser(EchantillonsAudio.aac(3000)).orElseThrow();
        assertThat(r.typeMime()).isEqualTo("audio/aac");
        assertThat(r.extension()).isEqualTo("aac");
        assertThat(r.dureeMs()).isBetween(3000L, 3100L);
    }

    @Test
    void oggOpus() {
        AnalyseAudio.Resultat r = AnalyseAudio.analyser(EchantillonsAudio.oggOpus(23_000)).orElseThrow();
        assertThat(r.typeMime()).isEqualTo("audio/ogg");
        assertThat(r.dureeMs()).isEqualTo(23_000);
    }

    @Test
    void webmSansDureeDeclareeCommeMediaRecorder() {
        AnalyseAudio.Resultat r = AnalyseAudio.analyser(EchantillonsAudio.webm(12_000)).orElseThrow();
        assertThat(r.typeMime()).isEqualTo("audio/webm");
        assertThat(r.dureeMs()).isBetween(11_950L, 12_050L);
    }

    @Test
    void webmLongEstMesure() {
        assertThat(AnalyseAudio.analyser(EchantillonsAudio.webm(6 * 60_000)).orElseThrow().dureeMs())
                .isGreaterThan(5 * 60_000L + 1000);
    }

    @Test
    void m4aAudio() {
        AnalyseAudio.Resultat r = AnalyseAudio.analyser(EchantillonsAudio.m4a(4_500, "soun")).orElseThrow();
        assertThat(r.typeMime()).isEqualTo("audio/mp4");
        assertThat(r.extension()).isEqualTo("m4a");
        assertThat(r.dureeMs()).isEqualTo(4_500);
    }

    @Test
    void refuseUneVideoUnTexteEtUnFichierTronque() {
        assertThat(AnalyseAudio.analyser(EchantillonsAudio.m4a(4_500, "vide"))).isEmpty();
        assertThat(AnalyseAudio.analyser("<html>bonjour</html>".getBytes(StandardCharsets.UTF_8))).isEmpty();
        assertThat(AnalyseAudio.analyser(new byte[]{(byte) 0x89, 'P', 'N', 'G', 0x0D, 0x0A, 0x1A, 0x0A})).isEmpty();
        byte[] ogg = EchantillonsAudio.oggOpus(5000);
        assertThat(AnalyseAudio.analyser(Arrays.copyOf(ogg, 30))).isEmpty();
        assertThat(AnalyseAudio.analyser(new byte[0])).isEmpty();
    }

    @Test
    void apercuDuVocal() {
        Message m = new Message();
        m.setType(TypeMessage.VOCAL);
        m.setDureeMs(23_400);
        assertThat(m.apercu(120)).isEqualTo("🎤 Message vocal (0:23)");
        m.setDureeMs(299_600);
        assertThat(m.apercu(120)).isEqualTo("🎤 Message vocal (5:00)");
    }

    @Test
    void formeOnde() {
        assertThat(FormeOnde.valider(" 0, 50 ,100")).isEqualTo("0,50,100");
        assertThat(FormeOnde.valider(null)).isNull();
        assertThat(FormeOnde.lire("0,50,100")).containsExactly(0, 50, 100);
        org.assertj.core.api.Assertions.assertThatThrownBy(() -> FormeOnde.valider("12,abc"))
                .isInstanceOf(sn.isep.Convoiturage.common.ApiException.class);
        org.assertj.core.api.Assertions.assertThatThrownBy(() -> FormeOnde.valider("101"))
                .isInstanceOf(sn.isep.Convoiturage.common.ApiException.class);
    }
}
