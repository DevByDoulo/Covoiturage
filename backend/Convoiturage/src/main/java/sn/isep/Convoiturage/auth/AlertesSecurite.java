package sn.isep.Convoiturage.auth;

import lombok.RequiredArgsConstructor;
import org.springframework.context.ApplicationEventPublisher;
import org.springframework.stereotype.Component;
import sn.isep.Convoiturage.utilisateur.Utilisateur;

import java.time.LocalDateTime;
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
public class AlertesSecurite {

    private static final DateTimeFormatter DATE = DateTimeFormatter.ofPattern("d MMMM yyyy 'à' HH'h'mm", Locale.FRENCH);
    private static final DateTimeFormatter DATE_JOUR = DateTimeFormatter.ofPattern("d MMMM yyyy", Locale.FRENCH);

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

    /** Demande de suppression enregistrée : rappelle le délai de grâce et comment annuler. */
    public void suppressionDemandee(Utilisateur u, LocalDateTime dateEffective) {
        String le = dateEffective.format(DATE_JOUR);
        prevenir(u.getEmail(), u.getTelephone(), "YOBALEMAsn - Suppression de votre compte demandée",
                "Bonjour " + u.getPrenom() + ",\n\n"
                        + "Nous avons bien reçu votre demande de suppression de compte. Votre compte est dès maintenant invisible "
                        + "et vous avez été déconnecté de tous vos appareils.\n"
                        + "Vos données personnelles seront définitivement effacées le " + le + ".\n\n"
                        + "Vous avez changé d'avis ? Il suffit de vous reconnecter avant cette date : la suppression sera annulée.\n"
                        + "Si vous n'êtes pas à l'origine de cette demande, reconnectez-vous tout de suite pour l'annuler, "
                        + "puis changez votre mot de passe.",
                "YOBALEMAsn : suppression de votre compte demandée. Elle sera définitive le " + le
                        + ". Reconnectez-vous avant pour l'annuler.");
    }

    public void suppressionAnnulee(Utilisateur u) {
        prevenir(u.getEmail(), u.getTelephone(), "YOBALEMAsn - Suppression de votre compte annulée",
                "Bonjour " + u.getPrenom() + ",\n\n"
                        + "Vous vous êtes reconnecté : la suppression de votre compte a été annulée et votre compte est de nouveau actif.\n"
                        + "Si ce n'est pas vous, changez votre mot de passe et contactez le support YOBALEMAsn.",
                "YOBALEMAsn : la suppression de votre compte a été annulée (reconnexion).");
    }

    /** Anonymisation faite : les coordonnées sont lues avant d'être effacées. */
    public void compteSupprime(String prenom, String email, String telephone) {
        prevenir(email, telephone, "YOBALEMAsn - Votre compte a été supprimé",
                "Bonjour " + prenom + ",\n\n"
                        + "Le délai de 30 jours est écoulé : vos données personnelles (identité, coordonnées, photo, documents, "
                        + "jetons de notification, alertes) ont été définitivement effacées.\n"
                        + "Seules les informations que la loi nous impose de conserver (paiements, trajets passés) restent, "
                        + "sans aucun lien avec votre identité.\n\n"
                        + "Merci d'avoir utilisé YOBALEMAsn.",
                "YOBALEMAsn : votre compte a été supprimé et vos données personnelles effacées.");
    }

    private void prevenir(String email, String telephone, String sujet, String texteEmail, String texteSms) {
        if (email != null && emails.disponible()) {
            evenements.publishEvent(new ExpediteurEmails.EmailAEnvoyer(email, sujet, texteEmail));
        } else if (telephone != null) {
            sms.envoyer(telephone, texteSms);
        }
    }
}
