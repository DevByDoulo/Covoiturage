# Plan de tests — YOBALEMAsn (état au 27/10/2026, branche 02-vehicules)

Tests manuels de ce qui est disponible dans l'interface : inscription, connexion, session, mot de passe
oublié et connexion Google. Cocher chaque ligne : ✅ conforme · ❌ anomalie (noter l'ID du test,
ce qui s'est passé, une capture d'écran) · ⏭ non testé.

## 0. Préparation

| | |
|---|---|
| Application | http://localhost:4200 (backend http://localhost:8080 démarré, PostgreSQL 16 lancé) |
| Codes de vérification | Comptes avec une **vraie** adresse email : le code arrive par email (vérifier les spams). Comptes avec une fausse adresse : ligne `[SMS simulé]` dans la console du backend. |
| Navigateur | Chrome conseillé, sans bloqueur de publicités sur `localhost` (sinon le bouton Google ne s'affiche pas). |

**Comptes de test** (base locale de développement uniquement) :

| Compte | Identifiant | Mot de passe | Rôle |
|---|---|---|---|
| Admin | `admin@covoitia.local` | voir `application-dev.yml` | Administrateur |
| Awa | `awa.conductrice@covoitia.sn` | `MotDePasse2026` | Conductrice |
| Moussa | `moussa.passager@covoitia.sn` | `MotDePasse2026` | Passager |
| Vous | votre email Gmail | le vôtre | Passager |

---

## A. Inscription et vérification

| ID | Étapes | Résultat attendu | ✓ |
|---|---|---|---|
| A1 | « S'inscrire » avec une vraie adresse email, un numéro `77 xxx xx xx`, sexe, mot de passe valide, CGU cochées | Passage **immédiat** (< 1 s) à l'écran « Vérifiez votre email », adresse masquée (`d*****@gmail.com`) ; email reçu | |
| A2 | Saisir le code reçu | Arrivée sur l'accueil « Bonjour … » ; le compte est actif | |
| A3 | S'inscrire avec un email déjà utilisé | Message « Cet email est déjà utilisé » **sous le champ email** | |
| A4 | Numéro invalide (`12 34`) | « Numéro sénégalais à 9 chiffres… » | |
| A5 | Mot de passe `abcdefgh` (sans chiffre) | Message de règle du mot de passe en rouge | |
| A6 | Confirmation différente | « Les deux mots de passe ne correspondent pas » | |
| A7 | CGU non cochées | « Vous devez accepter les conditions… » | |
| A8 | Écran de code : saisir un mauvais code | « Code incorrect — Il vous reste 4 tentatives » | |
| A9 | « Renvoyer le code » | Bouton grisé avec compte à rebours 60 s, puis nouveau code reçu | |
| A10 | Pavé numérique à l'écran et collage d'un code (Ctrl+V) | Les 6 cases se remplissent, vérification automatique | |

## B. Connexion et session

| ID | Étapes | Résultat attendu | ✓ |
|---|---|---|---|
| B1 | Connexion par email (Awa) | Accueil « Bienvenue, Awa », connectée en tant que conducteur ; menu Accueil + Déconnexion | |
| B2 | Connexion par téléphone `77 900 00 01` (Awa) | Même résultat | |
| B3 | Mauvais mot de passe | « Identifiant ou mot de passe incorrect » | |
| B4 | 5 mauvais mots de passe de suite (Moussa) | 6ᵉ essai : encadré orange « Trop de tentatives — Réessayez dans 15 minutes » ⚠️ bloque Moussa 15 min | |
| B5 | Connecté, appuyer sur F5 | Toujours connecté (pas de retour à la connexion) | |
| B6 | « Déconnexion » | Retour à l'écran de connexion ; F5 ne reconnecte pas | |
| B7 | Connexion Admin | Arrivée sur `/admin` « connecté en tant qu'administrateur » | |
| B8 | Déconnecté, ouvrir directement `http://localhost:4200/accueil` | Redirection vers la connexion, puis retour sur l'accueil après connexion | |

## C. Mot de passe oublié

| ID | Étapes | Résultat attendu | ✓ |
|---|---|---|---|
| C1 | « Mot de passe oublié ? », saisir **votre** email, « Envoyer le code » | Étape 2 sur 3 seule à l'écran : « Code à 6 chiffres envoyé à d*****@gmail.com » ; email reçu | |
| C2 | Saisir un email inconnu | Même passage à l'étape 2 (on ne révèle pas si le compte existe) ; « Modifier » ramène à l'étape 1 | |
| C3 | Étape 2 : code faux | Vérifié dès le 6ᵉ chiffre : « Code incorrect », tentatives restantes ; on reste à l'étape 2 | |
| C4 | Bon code, puis nouveau mot de passe (indicateur « Sécurisé ») | Étape 3 « Code vérifié » ; après « Réinitialiser », retour à la connexion avec « Mot de passe modifié » ; connexion OK avec le nouveau | |
| C5 | Après C4, une session ouverte ailleurs (autre navigateur) | Elle est déconnectée au prochain rafraîchissement du jeton | |
| C6 | Après C4, ouvrir votre boîte mail | Email « Votre mot de passe a été modifié » (date et heure, que faire si ce n'est pas vous) | |
| C7 | Email inconnu, puis un code quelconque à l'étape 2 | « Code incorrect », 4 tentatives restantes : exactement comme pour un vrai compte | |
| C8 | Redemander un code 6 fois de suite (attendre 60 s entre chaque) | Le 6ᵉ est refusé : « Trop de codes demandés. Réessayez dans … » ; on reste à l'étape 1 | |

## D. Connexion Google

| ID | Étapes | Résultat attendu | ✓ |
|---|---|---|---|
| D1 | Écran de connexion | Bouton **officiel** Google (G en couleurs). Sinon : bloqueur de pub ou script Google bloqué | |
| D2 | Première connexion Google avec un compte Gmail non inscrit | Écran « Votre numéro » → saisie du numéro et du sexe → code par email → accueil | |
| D3 | Deuxième connexion Google | Connexion directe, sans code | |

## E. Affichage

| ID | Étapes | Résultat attendu | ✓ |
|---|---|---|---|
| E1 | Fenêtre étroite (ou téléphone) | Onglets en bas de l'écran ; formulaires sur une colonne | |
| E2 | Grand écran | Menu en haut de l'écran | |
| E3 | Écrans d'authentification sur grand écran | Panneau vert de présentation à gauche | |

## F. Mon profil (01)

Avec votre compte (passager) ou celui d'Awa, menu **Profil**.

| ID | Étapes | Résultat attendu | ✓ |
|---|---|---|---|
| F1 | Ouvrir « Profil » | Photo (ou initiales), nom, « Membre depuis … », À propos, Préférences, Contacts d'urgence, menu du compte | |
| F2 | Icône appareil photo → choisir une image (JPEG/PNG, < 5 Mo) | La photo s'affiche tout de suite et reste après F5 | |
| F3 | Choisir un fichier PDF ou une image > 5 Mo comme photo | Message d'erreur, la photo ne change pas | |
| F4 | Crayon « À propos » → modifier prénom et présentation → Enregistrer | Nouveau nom en haut de page, présentation entre guillemets ; conservés après F5 | |
| F5 | Basculer « Animaux acceptés », puis F5 | L'interrupteur garde sa nouvelle position | |
| F6 | « Ajouter un contact » : nom, `77 123 45 12`, lien « Frère » | Contact affiché « +221 77 123 45 12 », pastille « Frère » | |
| F7 | Ajouter un contact avec **votre propre** numéro | « Indiquez le numéro d'un proche, pas le vôtre » | |
| F8 | Ajouter 3 contacts | Le bouton « Ajouter un contact » disparaît | |
| F9 | Corbeille d'un contact → confirmer | Le contact disparaît | |
| F10 | « Changer le mot de passe » avec un ancien mot de passe faux | « Mot de passe incorrect » sous le champ | |
| F11 | Même écran avec le bon ancien mot de passe | « Mot de passe modifié » ; email d'alerte reçu ; une session ouverte dans un autre navigateur est déconnectée | |
| F12 | « Désactiver mon compte » → mot de passe + case cochée → Désactiver | Retour à la connexion avec « Compte désactivé » | |
| F13 | Se reconnecter avec ce compte | Connexion réussie : le compte est réactivé | |

## G. Véhicules et documents (02)

Profil → « Mes véhicules et documents ». Un compte passager devient conducteur en ajoutant un véhicule.

| ID | Étapes | Résultat attendu | ✓ |
|---|---|---|---|
| G1 | Ouvrir l'écran avec un compte sans véhicule | Bandeau bleu « Vous pourrez publier des trajets dès que… » ; « Aucun véhicule » ; permis et pièce d'identité « À fournir » | |
| G2 | « Ajouter un véhicule » : `dk 1234 ab`, Toyota, Corolla, 2018, 7 CV, 5 places, Essence | Retour à la liste : « DK-1234-AB », « En attente de validation » ; une carte grise « À fournir » apparaît | |
| G3 | Ajouter un véhicule avec une immatriculation déjà utilisée | « Un véhicule avec cette immatriculation est déjà enregistré » | |
| G4 | Après G2, Profil | Statut « Validation des documents en cours » sous le nom | |
| G5 | Crayon du véhicule → ajouter une photo | La photo apparaît dans le formulaire et sur la carte du véhicule | |
| G6 | « Envoyer le document » sur le permis (photo ou PDF) | Pastille « En attente », « envoyé le … » ; compteur « 0/3 validé » | |
| G7 | « Renvoyer le document » sur une pièce en attente | Toujours une seule pièce « En attente » (la nouvelle remplace l'ancienne) | |
| G8 | « Voir le fichier » | Le document s'ouvre dans un nouvel onglet | |
| G9 | Awa : crayon de la Toyota (carte grise validée) | Bandeau « seules la consommation et l'usure… » ; immatriculation, marque, etc. grisées | |
| G10 | Crayon d'un véhicule non validé → « Retirer ce véhicule » → confirmer | Le véhicule et sa carte grise disparaissent de la liste | |

---

---

## Non testable dans l'interface pour l'instant

- **Validation des documents par l'administrateur** (module 07) : sans elle, les pièces restent « En attente ». Pour
  voir l'affichage « Refusé » ou « Validé », on peut modifier `document.statut_validation` en base.

## Limites connues (ne pas signaler comme anomalies)

- Les comptes en `@covoitia.sn` / `@covoitia.local` n'ont pas de vraie boîte mail : leurs codes sont dans la console du backend.
- Après connexion, l'accueil est volontairement vide : les fonctionnalités sont en cours de reconstruction.
- Les compteurs de la maquette *Mon profil* (trajets proposés, avis reçus) ne sont pas affichés : modules 03 et 05.
- Awa est encore « Conducteur vérifié » sans pièce d'identité validée : son statut date d'avant la nouvelle règle.
