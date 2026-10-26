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
     * La réponse est identique que le compte existe ou non, pour ne pas révéler les comptes inscrits.
     */
    @Transactional
    public AuthReponse motDePasseOublie(IdentifiantRequete req) {
        Optional<Utilisateur> u = trouverParIdentifiant(req.identifiant())
                .filter(x -> x.getStatut() == StatutCompte.ACTIF && x.getTelephone() != null);
        CanalOtp canal = u.map(x -> otp.envoyer(x.getTelephone(), x.getEmail(), ObjetOtp.REINITIALISATION_MOT_DE_PASSE))
                .orElseGet(() -> otp.canalPour("compte-inconnu"));
        // L'adresse ou le numéro masqué n'est montré que si l'utilisateur l'a lui-même saisi.
        String cle = cleIdentifiant(req.identifiant());
        boolean saisiParEmail = cle.contains("@");
        return AuthReponse.otpEnvoye(canal,
                saisiParEmail ? null : Telephones.masquer(cle),
                saisiParEmail ? masquerEmail(cle) : null,
                props.otp());
    }

    /** Vérifie le code reçu (5 essais) et remet le jeton qui autorise le choix du nouveau mot de passe. */
    @Transactional
    public CodeVerifieReponse verifierCodeReinitialisation(VerificationOtpRequete req) {
        Utilisateur u = trouverParIdentifiant(req.identifiant())
                .filter(x -> x.getTelephone() != null)
                .orElseThrow(() -> ApiException.badRequest("Code incorrect. Demandez un nouveau code."));
        otp.verifier(u.getTelephone(), ObjetOtp.REINITIALISATION_MOT_DE_PASSE, req.code());
        return new CodeVerifieReponse(jetonsReinitialisation.emettre(u), JetonReinitialisation.VALIDITE.toSeconds());
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
