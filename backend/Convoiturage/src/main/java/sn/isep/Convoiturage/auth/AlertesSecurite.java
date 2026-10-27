package sn.isep.Convoiturage.auth;

import lombok.RequiredArgsConstructor;
import org.springframework.context.ApplicationEventPublisher;
import org.springframework.stereotype.Component;
import sn.isep.Convoiturage.utilisateur.Utilisateur;

import java.time.ZoneId;
import java.time.ZonedDateTime;
import java.time.format.DateTimeFormatter;
import java.util.Locale;

/**
 * Prévient le titulaire d'un compte des changements sensibles : c'est sa seule chance de réagir si
 * quelqu'un d'autre a eu accès à sa boîte mail ou à son téléphone. Par email si possible, sinon par SMS.
 */
@Component
@RequiredArgsConstructor
class AlertesSecurite {

    private static final DateTimeFormatter DATE = DateTimeFormatter.ofPattern("d MMMM yyyy 'à' HH'h'mm", Locale.FRENCH);

    private final EmailSender emails;
    private final SmsSender sms;
    private final ApplicationEventPublisher evenements;

    void motDePasseModifie(Utilisateur u) {
        String quand = ZonedDateTime.now(ZoneId.of("Africa/Dakar")).format(DATE);
        if (u.getEmail() != null && emails.disponible()) {
            evenements.publishEvent(new ExpediteurEmails.EmailAEnvoyer(u.getEmail(),
                    "YOBALEMAsn - Votre mot de passe a été modifié",
                    "Bonjour " + u.getPrenom() + ",\n\n"
                            + "Le mot de passe de votre compte YOBALEMAsn a été modifié le " + quand + " (heure de Dakar).\n"
                            + "Par sécurité, vous avez été déconnecté de tous vos appareils.\n\n"
                            + "Si c'est bien vous, vous n'avez rien à faire.\n"
                            + "Sinon, choisissez tout de suite un nouveau mot de passe avec « Mot de passe oublié ? » "
                            + "sur l'écran de connexion, puis contactez le support YOBALEMAsn."));
        } else {
            sms.envoyer(u.getTelephone(), "YOBALEMAsn : le mot de passe de votre compte a été modifié le " + quand
                    + ". Si ce n'est pas vous, utilisez « Mot de passe oublié ? » et contactez le support.");
        }
    }
}
