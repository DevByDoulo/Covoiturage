package sn.isep.Convoiturage.suppression;

import java.time.LocalDateTime;

public final class SuppressionDtos {

    private SuppressionDtos() {}

    /** motDePasse pour un compte avec mot de passe ; code (reçu par email ou SMS) pour un compte créé avec Google. */
    public record SuppressionRequete(String motDePasse, String code) {}

    /** Date à laquelle les données seront définitivement effacées, sauf reconnexion avant. */
    public record SuppressionReponse(LocalDateTime dateSuppressionDefinitive) {}
}
