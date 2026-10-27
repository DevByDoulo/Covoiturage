package sn.isep.Convoiturage.auth;

import org.junit.jupiter.api.Test;
import sn.isep.Convoiturage.common.ApiException;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

class LimiteurParIpTest {

    @Test
    void refuseAuDelaDuPlafondPourUneMemeIp() {
        LimiteurParIp limiteur = new LimiteurParIp();
        for (int i = 0; i < LimiteurParIp.Action.DEMANDE_CODE.maxParHeure; i++) {
            limiteur.consommer(LimiteurParIp.Action.DEMANDE_CODE, "10.0.0.1");
        }
        assertThatThrownBy(() -> limiteur.consommer(LimiteurParIp.Action.DEMANDE_CODE, "10.0.0.1"))
                .isInstanceOfSatisfying(ApiException.class,
                        e -> assertThat(e.getProprietes()).containsEntry("motif", "LIMITE_IP"));
        // Une autre IP, ou une autre action, n'est pas concernée.
        limiteur.consommer(LimiteurParIp.Action.DEMANDE_CODE, "10.0.0.2");
        limiteur.consommer(LimiteurParIp.Action.VERIFICATION_CODE, "10.0.0.1");
    }
}
