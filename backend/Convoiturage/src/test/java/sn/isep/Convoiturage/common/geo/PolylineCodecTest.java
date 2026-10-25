package sn.isep.Convoiturage.common.geo;

import org.junit.jupiter.api.Test;

import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.within;

class PolylineCodecTest {

    @Test
    void decodeLExempleDeLaDocumentationGoogle() {
        List<Coordonnee> points = PolylineCodec.decoder("_p~iF~ps|U_ulLnnqC_mqNvxq`@");

        assertThat(points).hasSize(3);
        assertThat(points.get(0).latitude()).isCloseTo(38.5, within(1e-5));
        assertThat(points.get(0).longitude()).isCloseTo(-120.2, within(1e-5));
        assertThat(points.get(2).latitude()).isCloseTo(43.252, within(1e-5));
        assertThat(points.get(2).longitude()).isCloseTo(-126.453, within(1e-5));
    }

    @Test
    void encodeEtDecodeSontInverses() {
        List<Coordonnee> dakarThies = List.of(new Coordonnee(14.69281, -17.44672), new Coordonnee(14.75, -17.2),
                new Coordonnee(14.79102, -16.92599));

        List<Coordonnee> retour = PolylineCodec.decoder(PolylineCodec.encoder(dakarThies));

        assertThat(retour).hasSize(3);
        for (int i = 0; i < 3; i++) {
            assertThat(retour.get(i).latitude()).isCloseTo(dakarThies.get(i).latitude(), within(1e-5));
            assertThat(retour.get(i).longitude()).isCloseTo(dakarThies.get(i).longitude(), within(1e-5));
        }
    }

    @Test
    void distanceDakarThiesAVolDOiseau() {
        double km = GeoUtils.distanceKm(new Coordonnee(14.69281, -17.44672), new Coordonnee(14.79102, -16.92599));
        assertThat(km).isBetween(55.0, 58.0);
    }
}
