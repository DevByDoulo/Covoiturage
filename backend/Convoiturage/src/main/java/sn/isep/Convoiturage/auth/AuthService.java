package sn.isep.Convoiturage.auth;

import lombok.RequiredArgsConstructor;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import sn.isep.Convoiturage.auth.AuthDtos.*;
import sn.isep.Convoiturage.auth.GoogleTokenVerifier.CompteGoogle;
import sn.isep.Convoiturage.common.ApiException;
import sn.isep.Convoiturage.common.AppProperties;
import sn.isep.Convoiturage.common.Telephones;
import sn.isep.Convoiturage.utilisateur.Role;
import sn.isep.Convoiturage.utilisateur.StatutCompte;
import sn.isep.Convoiturage.utilisateur.Utilisateur;
import sn.isep.Convoiturage.utilisateur.UtilisateurDtos.ProfilDto;
import sn.isep.Convoiturage.utilisateur.UtilisateurRepository;

import java.util.Optional;

@Service
@RequiredArgsConstructor
public class AuthService {

    private final UtilisateurRepository utilisateurs;
    private final PasswordEncoder encoder;
    private final OtpService otp;
    private final TokenService tokens;
    private final GoogleTokenVerifier google;
    private final LimiteurConnexion limiteur;
    private final JetonReinitialisation jetonsReinitialisation;
    private final AlertesSecurite alertes;
    private final AppProperties props;

    /** Crée le compte (statut EN_ATTENTE_OTP) et envoie le code de vérification par SMS. */
    @Transactional
    public AuthReponse inscrire(InscriptionRequete req) {
        String telephone = normaliserTelephone(req.telephone());
        String email = req.email().trim().toLowerCase();

        // Une inscription abandonnée avant l'OTP peut être reprise avec le même numéro.
        Utilisateur u = utilisateurs.findByTelephone(telephone)
                .map(existant -> {
                    if (existant.getStatut() != StatutCompte.EN_ATTENTE_OTP) {
                        throw ApiException.conflict("Ce numéro est déjà associé à un compte").surChamp("telephone");
                    }
                    return existant;
                })
                .orElseGet(Utilisateur::new);
        utilisateurs.findByEmailIgnoreCase(email)
                .filter(autre -> !autre.getId().equals(u.getId()))
                .ifPresent(autre -> { throw ApiException.conflict("Cet email est déjà utilisé").surChamp("email"); });

        u.setPrenom(req.prenom().trim());
        u.setNom(req.nom().trim());
        u.setEmail(email);
        u.setTelephone(telephone);
        u.setSexe(req.sexe());
        u.setMotDePasse(encoder.encode(req.motDePasse()));
        u.setRole(Role.PASSAGER);
        u.setStatut(StatutCompte.EN_ATTENTE_OTP);
        utilisateurs.save(u);

        return envoyerCodeVerification(u);
    }

    @Transactional
    public AuthReponse renvoyerOtp(IdentifiantRequete req) {
        Utilisateur u = trouverParIdentifiant(req.identifiant())
                .filter(x -> x.getTelephone() != null && x.getStatut() == StatutCompte.EN_ATTENTE_OTP)
                .orElseThrow(() -> ApiException.notFound("Aucune vérification en attente pour ce compte"));
        return envoyerCodeVerification(u);
    }

    /**
     * Valide le moyen de contact qui a reçu le code (email ou téléphone, jamais les deux à la fois),
     * active le compte et connecte l'utilisateur.
     */
    @Transactional
    public AuthReponse verifierOtp(VerificationOtpRequete req) {
        Utilisateur u = trouverParIdentifiant(req.identifiant())
                .filter(x -> x.getTelephone() != null)
                .orElseThrow(() -> ApiException.badRequest("Code incorrect. Demandez un nouveau code."));
        CanalOtp canal = otp.verifier(u.getTelephone(), ObjetOtp.VERIFICATION_TELEPHONE, req.code());
        if (canal == CanalOtp.EMAIL) u.setEmailVerifie(true);
        else u.setTelephoneVerifie(true);
        if (u.getStatut() == StatutCompte.EN_ATTENTE_OTP) u.setStatut(StatutCompte.ACTIF);
        verifierPeutSeConnecter(u);
        return AuthReponse.connecte(tokens.emettre(u), ProfilDto.de(u));
    }

    /** Connexion par email ou téléphone. 5 échecs en 15 minutes bloquent temporairement l'identifiant. */
    @Transactional
    public AuthReponse connecter(ConnexionRequete req) {
        String cle = cleIdentifiant(req.identifiant());
        limiteur.verifierAutorise(cle);
        Optional<Utilisateur> trouve = trouverParIdentifiant(req.identifiant())
                .filter(x -> x.getMotDePasse() != null && encoder.matches(req.motDePasse(), x.getMotDePasse()));
        if (trouve.isEmpty()) {
            limiteur.enregistrerEchec(cle);
            throw ApiException.unauthorized("Identifiant ou mot de passe incorrect");
        }
        limiteur.reinitialiser(cle);
        Utilisateur u = trouve.get();
        reactiverSiDesactive(u);
        if (u.getStatut() == StatutCompte.EN_ATTENTE_OTP) {
            return envoyerCodeVerification(u);
        }
        verifierPeutSeConnecter(u);
        return AuthReponse.connecte(tokens.emettre(u), ProfilDto.de(u));
    }

    /**
     * Connexion Google. 1er passage : le compte est créé/lié, puis on exige un numéro
     * (TELEPHONE_REQUIS) et un code de vérification. Ensuite (compte vérifié) : connexion directe.
     */
    @Transactional
    public AuthReponse connecterAvecGoogle(GoogleRequete req) {
        CompteGoogle g = google.verifier(req.idToken());
        Optional<Utilisateur> existant = utilisateurs.findByGoogleId(g.sub());
        if (existant.isEmpty() && g.email() != null && g.emailVerifie()) {
            existant = utilisateurs.findByEmailIgnoreCase(g.email());
        }
        Utilisateur u = existant.orElseGet(() -> {
            Utilisateur nouveau = new Utilisateur();
            nouveau.setPrenom(g.prenom());
            nouveau.setNom(g.nom());
            nouveau.setEmail(g.emailVerifie() ? g.email() : null);
            nouveau.setRole(Role.PASSAGER);
            nouveau.setStatut(StatutCompte.EN_ATTENTE_OTP);
            return nouveau;
        });
        u.setGoogleId(g.sub());
        if (u.getSexe() == null && req.sexe() != null) u.setSexe(req.sexe());

        if (u.estVerifie() && u.getTelephone() != null) {
            reactiverSiDesactive(u);
            utilisateurs.save(u);
            verifierPeutSeConnecter(u);
            return AuthReponse.connecte(tokens.emettre(u), ProfilDto.de(u));
        }
        if (req.telephone() == null || req.telephone().isBlank()) {
            utilisateurs.save(u);
            return AuthReponse.telephoneRequis();
        }
        String telephone = normaliserTelephone(req.telephone());
        utilisateurs.findByTelephone(telephone)
                .filter(autre -> !autre.getId().equals(u.getId()))
                .ifPresent(autre -> { throw ApiException.conflict("Ce numéro est déjà associé à un compte").surChamp("telephone"); });
        u.setTelephone(telephone);
        utilisateurs.save(u);
        return envoyerCodeVerification(u);
    }

    @Transactional
    public AuthReponse rafraichir(RefreshRequete req) {
        Utilisateur u = tokens.consommerRefreshToken(req.refreshToken());
        verifierPeutSeConnecter(u);
        return AuthReponse.connecte(tokens.emettre(u), ProfilDto.de(u));
    }

    @Transactional
    public void deconnecter(RefreshRequete req) {
        tokens.revoquer(req.refreshToken());
    }

    /**
     * Envoie un code de réinitialisation au compte (identifié par email ou téléphone), par email ou à défaut par SMS.
     * Les réponses sont identiques que le compte existe ou non, pour ne pas révéler les comptes inscrits :
     * pour un compte inconnu, un code fictif est enregistré sans être envoyé (mêmes délais, quotas et essais).
     */
    @Transactional
    public AuthReponse motDePasseOublie(IdentifiantRequete req) {
        String cle = cleIdentifiant(req.identifiant());
        CanalOtp canal = compteRecuperable(req.identifiant())
                .map(x -> otp.envoyer(x.getTelephone(), x.getEmail(), ObjetOtp.REINITIALISATION_MOT_DE_PASSE))
                .orElseGet(() -> {
                    CanalOtp c = otp.canalPour("compte-inconnu");
                    otp.simulerEnvoi(cleFictive(cle), ObjetOtp.REINITIALISATION_MOT_DE_PASSE, c);
                    return c;
                });
        // L'adresse ou le numéro masqué n'est montré que si l'utilisateur l'a lui-même saisi.
        boolean saisiParEmail = cle.contains("@");
        return AuthReponse.otpEnvoye(canal,
                saisiParEmail ? null : Telephones.masquer(cle),
                saisiParEmail ? masquerEmail(cle) : null,
                props.otp());
    }

    /** Vérifie le code reçu (5 essais) et remet le jeton qui autorise le choix du nouveau mot de passe. */
    @Transactional
    public CodeVerifieReponse verifierCodeReinitialisation(VerificationOtpRequete req) {
        Optional<Utilisateur> u = compteRecuperable(req.identifiant());
        String cleCode = u.map(Utilisateur::getTelephone).orElseGet(() -> cleFictive(cleIdentifiant(req.identifiant())));
        otp.verifier(cleCode, ObjetOtp.REINITIALISATION_MOT_DE_PASSE, req.code());
        // Code fictif deviné (1 chance sur un million) : même refus qu'un code faux.
        Utilisateur compte = u.orElseThrow(() -> ApiException.badRequest("Code incorrect. Demandez un nouveau code."));
        return new CodeVerifieReponse(jetonsReinitialisation.emettre(compte), JetonReinitialisation.VALIDITE.toSeconds());
    }

    /** Change le mot de passe (jeton obtenu après vérification du code) et déconnecte tous les appareils. */
    @Transactional
    public void reinitialiserMotDePasse(ReinitialisationRequete req) {
        Utilisateur u = JetonReinitialisation.lireIdentifiant(req.jeton())
                .flatMap(utilisateurs::findById)
                .filter(x -> jetonsReinitialisation.signatureValide(req.jeton(), x))
                .orElseThrow(() -> ApiException.badRequest("Ce lien de réinitialisation a expiré. Recommencez la procédure."));
        u.setMotDePasse(encoder.encode(req.nouveauMotDePasse()));
        tokens.revoquerTous(u.getId());
        limiteur.reinitialiser(u.getTelephone());
        if (u.getEmail() != null) limiteur.reinitialiser(u.getEmail());
        alertes.motDePasseModifie(u);
    }

    /**
     * Utilisateur connecté : change son mot de passe (l'ancien est exigé s'il en a un), ferme toutes les autres
     * sessions et renvoie de nouveaux jetons pour l'appareil courant. Le titulaire est prévenu.
     */
    @Transactional
    public AuthReponse changerMotDePasse(Long utilisateurId, ChangementMotDePasseRequete req) {
        Utilisateur u = charger(utilisateurId);
        verifierMotDePasseActuel(u, req.motDePasseActuel(), "motDePasseActuel");
        if (u.getMotDePasse() != null && encoder.matches(req.nouveauMotDePasse(), u.getMotDePasse())) {
            throw ApiException.badRequest("Le nouveau mot de passe doit être différent de l'ancien").surChamp("nouveauMotDePasse");
        }
        u.setMotDePasse(encoder.encode(req.nouveauMotDePasse()));
        tokens.revoquerTous(u.getId());
        alertes.motDePasseModifie(u);
        return AuthReponse.connecte(tokens.emettre(u), ProfilDto.de(u));
    }

    /**
     * Désactivation à la demande du titulaire : le compte n'apparaît plus et toutes les sessions sont fermées.
     * Il est réactivé à la prochaine connexion réussie.
     */
    @Transactional
    public void desactiver(Long utilisateurId, DesactivationRequete req) {
        Utilisateur u = charger(utilisateurId);
        if (u.getRole() == Role.ADMIN) throw ApiException.forbidden("Un compte administrateur ne peut pas être désactivé ici");
        verifierMotDePasseActuel(u, req.motDePasse(), "motDePasse");
        u.setStatut(StatutCompte.DESACTIVE);
        tokens.revoquerTous(u.getId());
    }

    private Utilisateur charger(Long id) {
        return utilisateurs.findById(id).orElseThrow(() -> ApiException.notFound("Utilisateur introuvable"));
    }

    /** Contrôle du mot de passe actuel, compté comme une tentative de connexion (blocage après 5 échecs). */
    private void verifierMotDePasseActuel(Utilisateur u, String saisi, String champ) {
        if (u.getMotDePasse() == null) return;
        String cle = u.getTelephone() != null ? u.getTelephone() : "id:" + u.getId();
        limiteur.verifierAutorise(cle);
        if (saisi == null || !encoder.matches(saisi, u.getMotDePasse())) {
            limiteur.enregistrerEchec(cle);
            throw ApiException.badRequest("Mot de passe incorrect").surChamp(champ);
        }
    }

    private static void reactiverSiDesactive(Utilisateur u) {
        if (u.getStatut() == StatutCompte.DESACTIVE) u.setStatut(StatutCompte.ACTIF);
    }

    /** Compte pouvant récupérer son mot de passe : actif et avec un numéro (auquel les codes sont rattachés). */
    private Optional<Utilisateur> compteRecuperable(String identifiant) {
        return trouverParIdentifiant(identifiant)
                .filter(x -> x.getStatut() == StatutCompte.ACTIF && x.getTelephone() != null);
    }

    /**
     * Clé des codes fictifs d'un identifiant sans compte : « ? » suivi d'un hash (20 caractères, la taille
     * de la colonne). Elle ne peut pas correspondre à un numéro, et l'identifiant saisi n'est pas conservé.
     */
    static String cleFictive(String cleIdentifiant) {
        return "?" + TokenService.hash("reinitialisation|" + cleIdentifiant).substring(0, 19);
    }

    /** Envoie le code de vérification du compte (email si possible, sinon SMS) et décrit l'envoi à l'interface. */
    private AuthReponse envoyerCodeVerification(Utilisateur u) {
        CanalOtp canal = otp.envoyer(u.getTelephone(), u.getEmail(), ObjetOtp.VERIFICATION_TELEPHONE);
        return canal == CanalOtp.EMAIL
                ? AuthReponse.otpEnvoye(canal, null, masquerEmail(u.getEmail()), props.otp())
                : AuthReponse.otpEnvoye(canal, Telephones.masquer(u.getTelephone()), null, props.otp());
    }

    /** « awa.diop@gmail.com » → « a*******@gmail.com ». */
    static String masquerEmail(String email) {
        int arobase = email.indexOf('@');
        if (arobase < 1) return email;
        return email.charAt(0) + "*".repeat(Math.max(1, arobase - 1)) + email.substring(arobase);
    }

    private Optional<Utilisateur> trouverParIdentifiant(String identifiant) {
        String id = identifiant.trim();
        if (id.contains("@")) return utilisateurs.findByEmailIgnoreCase(id);
        try {
            return utilisateurs.findByTelephone(Telephones.normaliser(id));
        } catch (ApiException e) {
            return Optional.empty();
        }
    }

    /** Forme canonique d'un identifiant (email en minuscules ou téléphone E.164) pour le limiteur. */
    private static String cleIdentifiant(String identifiant) {
        String id = identifiant.trim();
        if (id.contains("@")) return id.toLowerCase();
        try {
            return Telephones.normaliser(id);
        } catch (ApiException e) {
            return id;
        }
    }

    private static String normaliserTelephone(String brut) {
        try {
            return Telephones.normaliser(brut);
        } catch (ApiException e) {
            throw e.surChamp("telephone");
        }
    }

    private static void verifierPeutSeConnecter(Utilisateur u) {
        switch (u.getStatut()) {
            case BLOQUE -> throw ApiException.forbidden("Votre compte est temporairement bloqué. Contactez le support.");
            case BANNI -> throw ApiException.forbidden("Votre compte a été banni.");
            case DESACTIVE -> throw ApiException.forbidden("Ce compte a été désactivé.");
            case EN_ATTENTE_OTP -> throw ApiException.forbidden("Veuillez d'abord vérifier votre numéro de téléphone.");
            case ACTIF -> { }
        }
    }
}
