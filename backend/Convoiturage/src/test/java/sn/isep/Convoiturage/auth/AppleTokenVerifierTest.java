package sn.isep.Convoiturage.auth;

import org.junit.jupiter.api.Test;
import org.springframework.http.HttpStatus;
import sn.isep.Convoiturage.common.ApiException;
import sn.isep.Convoiturage.common.AppProperties;

import java.util.Arrays;
import java.util.List;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;

/** Sans réseau : configuration absente et jeton mal formé (refusé avant tout appel aux clés d'Apple). */
class AppleTokenVerifierTest {

    private static AppleTokenVerifier avec(String... clientIds) {
        return new AppleTokenVerifier(new AppProperties(null, null, null, null, null, null, null, null,
                new AppProperties.Apple(Arrays.asList(clientIds))));
    }

    @Test
    void nonConfigureRepond503() {
        ApiException e = assertThrows(ApiException.class, () -> avec().verifier("x.y.z"));
        assertEquals(HttpStatus.SERVICE_UNAVAILABLE, e.getStatus());
        assertThrows(ApiException.class, () -> avec(" ", "").verifier("x.y.z"));
    }

    @Test
    void jetonMalFormeRefuse() {
        ApiException e = assertThrows(ApiException.class, () -> avec("sn.yobalema.web").verifier("pas-un-jeton"));
        assertEquals(HttpStatus.UNAUTHORIZED, e.getStatus());
    }

    @Test
    void identifiantsNettoyes() {
        assertEquals(List.of("sn.yobalema.web", "sn.isep.yobalema"),
                avec(" sn.yobalema.web ", "", "sn.isep.yobalema").identifiantsClients());
    }
}
