package sn.isep.Convoiturage.common;

import lombok.Getter;
import org.springframework.http.HttpStatus;

import java.util.LinkedHashMap;
import java.util.Map;

/**
 * Erreur métier renvoyée au client sous forme de ProblemDetail (voir {@link GlobalExceptionHandler}).
 * Des propriétés supplémentaires peuvent être jointes pour l'interface, par exemple
 * {@code champ} (champ de formulaire concerné) ou {@code tentativesRestantes}.
 */
@Getter
public class ApiException extends RuntimeException {

    private final HttpStatus status;
    private final Map<String, Object> proprietes = new LinkedHashMap<>();

    public ApiException(HttpStatus status, String message) {
        super(message);
        this.status = status;
    }

    public ApiException avec(String cle, Object valeur) {
        proprietes.put(cle, valeur);
        return this;
    }

    /** Indique le champ du formulaire à mettre en erreur côté interface. */
    public ApiException surChamp(String champ) {
        return avec("champ", champ);
    }

    public static ApiException badRequest(String message) { return new ApiException(HttpStatus.BAD_REQUEST, message); }

    public static ApiException unauthorized(String message) { return new ApiException(HttpStatus.UNAUTHORIZED, message); }

    public static ApiException forbidden(String message) { return new ApiException(HttpStatus.FORBIDDEN, message); }

    public static ApiException notFound(String message) { return new ApiException(HttpStatus.NOT_FOUND, message); }

    public static ApiException conflict(String message) { return new ApiException(HttpStatus.CONFLICT, message); }

    public static ApiException tooManyRequests(String message) { return new ApiException(HttpStatus.TOO_MANY_REQUESTS, message); }
}
