# YOBALEMAsn — détail des fonctionnalités réalisées

Historique détaillé de chaque module (branches, tables, API, écrans, règles). Déplacé hors de `CLAUDE.md` le
10/11/2026 pour que ce fichier, lu à chaque session, reste court. **Le compléter à chaque fonctionnalité.**

## Modules

Le 27/10/2026, la répartition a changé et le dépôt **repart de l'authentification**. Tout le reste a été retiré
du code ; l'ancienne version complète (backend du lot 1, écrans Trajets et Recherche avec carte Leaflet,
alertes de recherche, prix par formule, réservations, notifications, back-office) reste consultable et
récupérable sous l'**étiquette Git `archive/lot1-complet`** (`git show archive/lot1-complet:<chemin>`, ou
`git checkout archive/lot1-complet -- <dossier>` pour reprendre un module).

**Fait :**
- Backend (`auth`, `utilisateur`, `common`, `admin`) : inscription avec code par email (ou SMS), connexion
  email/téléphone/Google, jetons JWT + refresh (rotation), blocage après 5 échecs, mot de passe oublié en
  3 étapes (code vérifié, puis jeton de 10 min ; comptes inconnus non révélés ; quotas de codes par compte et
  par IP ; alerte au titulaire après changement) ; profil, préférences, photo (`/api/moi`) ; compte admin
  créé au démarrage.
- **01 Gestion des utilisateurs** (branche `01-utilisateurs`) : écran *Mon profil* (`features/profil`) — photo,
  À propos, préférences de trajet (enregistrées à chaque bascule), contacts d'urgence (table `contact_urgence`,
  3 au plus), changer / définir le mot de passe (`/profil/mot-de-passe`), désactiver le compte
  (`/profil/desactivation`, réactivé à la connexion suivante). Les compteurs de la maquette (trajets, avis)
  viendront avec les modules 03 et 05.
- **02 Gestion des véhicules** (branche `02-vehicules`, partie de `01-utilisateurs`) : module backend `vehicule`
  (repris de l'archive et adapté) — véhicules avec photo, documents permis / **pièce d'identité** / carte grise
  (migration V2026_10_27_1100) ; écran *Véhicules et documents* (`features/vehicules`) : liste, ajout et
  modification, envoi et renvoi des pièces, motif de refus. La validation des pièces par l'admin relève du
  module 07 : appeler `VehiculeService.recalculerStatutConducteur` après chaque décision.
- Frontend : connexion (case **« Rester connecté »**, décochée par défaut : jeton de rafraîchissement en
  `sessionStorage`, session terminée à la fermeture de l'onglet ; cochée : `localStorage`, 30 jours — branche
  `web-rester-connecte`), inscription, vérification du code, mot de passe oublié (3 écrans successifs),
  téléphone après Google ; espace connecté (`features/espace`, barre de navigation + déconnexion) et page
  d'accueil simple (`/accueil`) ; l'administrateur arrive sur le back-office (`/admin`).
- **Design de la connexion** (branche `connexion-design`, design seulement, inspiré de la page de connexion d'Uber) :
  donnée de route `epure` sur `/auth/connexion` → `AuthLayout` affiche un bandeau vert foncé avec le logo (lien vers
  `/accueil`) et une colonne blanche centrée de 410 px, sans le panneau de présentation (les autres écrans
  d'authentification gardent leur cadre). Écran (`connexion.scss`, propre à la connexion) : titre-question « Indiquez
  votre numéro de téléphone ou votre adresse e-mail », champs gris pleins de 56 px sans pictogramme (libellés pour
  lecteurs d'écran, erreurs reliées par `aria-describedby`), « Rester connecté » et « Mot de passe oublié ? » sur
  une ligne, bouton vert « Continuer », séparateur « ou », bouton Google rectangulaire (nouvelle entrée `forme` de
  `BoutonGoogle` ; le bouton officiel de Google n'est pas restylable), bouton gris « Créer un compte », mention
  en petit. Le fonctionnement ne change pas : identifiant + mot de passe, Google, `retour`, alertes.
- **Inscription avec Google seulement, en plusieurs étapes** (branche `inscription-google`, partie de
  `connexion-design`, site seulement, backend inchangé), une question par écran comme Uber, dans le même cadre
  épuré (donnée de route `epure` sur `/auth/inscription`, `/auth/google/telephone` et `/auth/verification`) :
  1. `/auth/inscription` : « Créez votre compte avec Google », liste des 5 étapes, bouton Google « S'inscrire avec
     Google » (nouvelle entrée `texte` de `BoutonGoogle`), « J'ai déjà un compte » (garde `retour`). **Le formulaire
     e-mail + mot de passe est retiré du site** (l'appli mobile garde le sien ; `POST /api/auth/inscription` reste dans
     l'API). Compte Google déjà inscrit → connecté directement ; prénom, nom et e-mail repris de Google.
  2. à 4. `/auth/google/telephone` (`GoogleTelephone`, une étape à la fois, « Retour » et « Étape n sur 5 », focus
     placé sur le titre à chaque étape) : numéro (+221, vérifié par SMS ; « Bienvenue Awa ! » grâce au prénom lu dans
     l'idToken par `google-jeton.ts`, affichage seulement), sexe (obligatoire désormais, gros boutons radio),
     conditions (liens vers les deux textes, case « J'ai 18 ans ou plus et j'accepte… » obligatoire) → `POST
     /api/auth/google` avec téléphone + sexe. Numéro refusé (déjà associé à un compte) : retour à l'étape 2, message
     gardé à part (`erreurTelephone`, sinon effacé à la recréation du champ) jusqu'à ce que le numéro change.
  5. `/auth/verification?inscription=1` : code reçu par SMS, « Étape 5 sur 5 » ; l'en-tête de page est remplacé par
     un lien « Retour ».
  Textes légaux (version du 18/11/2026, même jour) : conditions (inscription sur le site avec un compte Google) et
  confidentialité (données transmises par Google : prénom, nom, e-mail, identifiant).
- **Connexion et inscription avec Apple** (branche `connexion-apple`, partie de `inscription-google`, site + API) :
  - **Backend** : migration `V2026_11_19_2130__connexion_apple.sql` (colonne `utilisateur.apple_id`, unique, effacée à
    l'anonymisation) ; `AppleTokenVerifier` vérifie l'identityToken (RS256, clés publiques
    `https://appleid.apple.com/auth/keys` via `NimbusJwtDecoder`, émetteur `https://appleid.apple.com`, expiration,
    audience ∈ `app.apple.client-ids` = variable `APPLE_CLIENT_ID`, liste séparée par des virgules ; vide → 503
    « La connexion Apple n'est pas configurée »). `POST /api/auth/apple` (`AppleRequete` : idToken, prénom et nom
    facultatifs — Apple ne les donne qu'au premier accès et pas dans le jeton —, téléphone, sexe).
  - **Règles communes Google / Apple** (`AuthService.connecterAvecCompteExterne`) : compte retrouvé par
    `google_id` / `apple_id`, sinon par email vérifié (liaison avec un compte existant, qui a déjà son numéro → connecté
    directement), sinon créé. **Pas de session tant que le compte n'a pas de numéro** : réponse `TELEPHONE_REQUIS`, puis
    le numéro fourni déclenche l'envoi d'un code, la session ne s'ouvre qu'après ce code ; numéro d'un autre compte →
    409 sur `telephone`. Apple sans nom transmis : « Utilisateur Apple » (comme « Utilisateur Google »).
  - **Site** : `shared/ui/bouton-apple.ts` (« Continuer / S'inscrire avec Apple », bibliothèque officielle « Sign in
    with Apple JS » chargée au premier clic, fenêtre popup, `scope: 'name email'` ; fenêtre fermée → rien ; non
    configuré → message « pas encore activée »), sur la connexion et l'inscription (style gris épuré).
    `environment.apple = { clientId, redirectUri }` (vides). `SessionService.compteExterne` (Google ou Apple, en
    mémoire) remplace `idTokenGoogle` ; `connexionApple()` ; `terminerInscriptionExterne(telephone, sexe)`. Les étapes
    2 à 4 passent de `/auth/google/telephone` à **`/auth/telephone`** (ancienne adresse redirigée) ; « Bienvenue Fatou ! »
    avec le prénom donné par Apple. Textes « par SMS » retirés des étapes : voir la remarque ci-dessous.
  - **À configurer (compte Apple Developer payant)** : un Services ID (= `APPLE_CLIENT_ID` et
    `environment.apple.clientId`), le domaine du site et l'adresse de retour (HTTPS, `environment.apple.redirectUri`) ;
    Apple refuse `localhost` : la connexion Apple ne se teste que sur le site déployé. Pour écrire aux adresses relais
    `@privaterelay.appleid.com`, déclarer le domaine d'envoi des emails chez Apple. Appli mobile : pas encore (iOS :
    connexion native, bundle ID à ajouter à `APPLE_CLIENT_ID`).
  - **Remarque (code de vérification)** : `OtpService.canalPour` envoie le code **par email** dès que le compte a un
    email et que l'envoi d'emails est configuré. Pour une inscription Google ou Apple, le code part donc à l'adresse
    du compte : le numéro est obligatoire mais pas vérifié par SMS tant que le fournisseur SMS n'est pas choisi.
  - Textes légaux (version du **19/11/2026**) : inscription avec Google ou Apple, données transmises par Apple
    (identifiant, email réel ou relais, prénom et nom au premier accès).
- **Inscription et connexion par téléphone, au même niveau que Google et e-mail** (branche `inscription-telephone`,
  site + API + mobile). Aucune méthode n'est imposée ; le numéro reste obligatoire pour les comptes Google, Apple et
  e-mail (décision du 19/11/2026 : codes OTP rattachés au numéro, contact entre membres, SMS).
  - **Backend** (aucune migration) : `POST /api/auth/telephone/code` (`{telephone}`, numéros +221 seulement, code
    **toujours par SMS** même si le compte a un email, réponse identique que le numéro ait un compte ou non),
    `POST /api/auth/telephone/verifier` (`{telephone, code}` → `CONNECTE` pour un numéro déjà connu, sans doublon,
    numéro marqué vérifié, suppression en cours annulée ; sinon nouvelle étape **`PROFIL_REQUIS`** avec
    `jetonInscription`), `POST /api/auth/telephone/terminer` (`{jeton, prenom, nom, sexe, motDePasse?}` → compte
    `ACTIF`, `telephone_verifie`, mot de passe facultatif, 201 + `CONNECTE`). `JetonInscription` : jeton opaque signé
    HMAC (clé des JWT) contenant le numéro, 15 minutes, rien en base ; rejoué → 409 (le compte existe déjà).
    Réutilise `OtpService` (table `otp_code`, objet `VERIFICATION_TELEPHONE`, 6 chiffres, 5 min, 5 essais, renvoi
    après 60 s, 5 codes/heure et 10/jour par numéro) et `LimiteurParIp` (20 demandes et 30 vérifications par heure
    et par IP). Une **inscription abandonnée** avec ce numéro (compte `EN_ATTENTE_OTP` jamais vérifié) est reprise par
    celui qui prouve posséder le numéro, sans rien garder (email, mot de passe, Google/Apple effacés) : empêche de
    réserver le numéro de quelqu'un d'autre. `SmsSender` : le code n'est écrit dans les journaux (`[SMS simulé]`)
    qu'en profils `dev` et `test` ; ailleurs, tant qu'aucun fournisseur n'est branché, `SmsNonConfigure` journalise
    l'envoi sans le contenu.
  - **Site** : `/auth/connexion` et `/auth/inscription` affichent le même **écran de départ** (`features/auth/entree`) :
    champ +221 et « Continuer », « Rester connecté », « ou », Google, **Apple seulement si `environment.apple` est
    renseigné** (`appleConfigure()`, sinon le bouton est masqué ; code Apple conservé), lien « Autres options (e-mail
    et mot de passe) ». Puis `/auth/verification` (mode `telephone` dans `VerificationEnCours`, renvoi par
    `/telephone/code`) ; numéro inconnu → **`/auth/profil`** (`Inscription`, parcours `telephone`, « Étape 3 à 6
    sur 6 » : prénom et nom, sexe, mot de passe facultatif avec « Passer », conditions → compte créé et connecté ;
    jeton en sessionStorage `covoitia.inscription`). **« Autres options »** = `/auth/autres-options` (ancien
    formulaire de connexion identifiant + mot de passe, retour de « mot de passe oublié ») et
    **`/auth/inscription-email`** (parcours `email` : e-mail et mot de passe, prénom et nom, numéro, sexe, conditions,
    puis code « Étape 6 sur 6 » via `POST /api/auth/inscription` inchangé ; champ refusé → retour à son étape).
    `?inscription=` de `/auth/verification` porte désormais le nombre d'étapes (5 Google, 6 e-mail).
  - **Mobile** : `ConnexionPage` devient l'écran de départ (numéro + « Continuer », « ou », Google, « Autres options »),
    `AutresOptionsPage` (`/autres-options` : e-mail + mot de passe, mot de passe oublié, « Créer un compte avec une
    adresse e-mail » → ancienne `InscriptionPage`, sans bouton Google), `ProfilTelephonePage` (`/inscription/profil`,
    jeton en mémoire : prénom, nom, sexe, mot de passe facultatif, conditions), `DemandeVerification.parTelephone`.
    Pas de bouton Apple dans l'appli, rien à masquer.
  - Textes légaux (version du **20/11/2026**) : numéro de téléphone comme identifiant de connexion, code par SMS
    (empreinte seule conservée, limites), email et mot de passe facultatifs pour un compte créé par numéro.
- **Habillage « photo plein écran » des écrans d'authentification** (branche `connexion-photo`, site seulement,
  **design seulement** : parcours, méthodes et textes inchangés ; remplace le bandeau vert et la colonne blanche de
  `connexion-design`). Modèle : capture de référence de Doulo (20/11/2026) — formulaire **posé directement sur la
  photo, sans cadre**, texte blanc, champs blancs arrondis, gros bouton plein largeur avec flèche.
  - **Cadre** (`auth-layout.ts`, tous les écrans sous `/auth` : départ, autres options, inscription, profil,
    vérification, téléphone après Google/Apple, mot de passe oublié ; la donnée de route `epure` n'existe plus) : photo
    plein écran dans une `<picture>` (`fond-connexion.webp`, et `fond-connexion-mobile.webp` en portrait de moins de
    768 px ; `fetchpriority="high"`, `width`/`height` fixes — 1376×768 pour la photo actuelle —, `alt` vide, pas de
    bibliothèque) et **voile sombre dégradé** (≈ 64 % → 76 % en vertical sur téléphone ; ≈ 72 % → 66 % de gauche à droite
    sur grand écran). ≥ 960 px : logo (pastille blanche, lisible sur toute photo) et accroche à gauche, **fine ligne
    blanche verticale**, formulaire à droite ; téléphone : logo en haut, formulaire centré, pleine largeur.
  - **Écrans** : titre blanc centré, **libellés blancs visibles** au-dessus des champs (plus de `sr-only`), champs
    blancs de 54 px à coins de 14 px avec pictogramme (e-mail, cadenas, prénom/nom, drapeau +221), « Rester connecté » et
    mentions en blanc, liens blancs soulignés, séparateur « ou continuer avec » en traits blancs, **Google et Apple en
    pastilles rondes** (nouvelle entrée `variante="icone"` de `BoutonGoogle` — bouton officiel `type: 'icon'`,
    `shape: 'circle'` — et de `BoutonApple`, libellé gardé en `aria-label`), erreurs de champ en pastille claire, boutons
    secondaires transparents à bord blanc, **bouton principal orange de la charte avec texte sombre** (8:1 ; blanc sur
    orange échoue AA) et flèche (remplace le rouge de la maquette ; variable `--principal` dans `auth-photo.scss` pour
    changer de couleur en une ligne). Mot de passe oublié : « Retour » + titre comme les autres écrans, étapes à plat.
  - **Ordre des écrans de connexion** (changement de la même branche, en plus du design) : `/auth/connexion` affiche
    d'abord **e-mail (ou numéro) + mot de passe**, puis « ou continuer avec » Google (et Apple s'il est configuré), puis
    « Autres options » = numéro + code SMS (`/auth/connexion-telephone`, même écran `Entree`) et le lien vers
    l'inscription ; `/auth/inscription` commence au contraire par le numéro, avec « Autres options » = e-mail et mot de
    passe (`/auth/autres-options`). `Connexion` reçoit la donnée de route `principal` ; « Retour » de la vérification
    ramène à `/auth/connexion-telephone` pour un code par SMS. Tests : `connexion.spec.ts`, `entree.spec.ts`.
  - **Carte d'inscription** (maquette « Create new account » de Doulo, 20/11/2026 ; `auth-carte.scss`, 2e feuille de
    `AuthLayout` pour rester sous le budget de style) : sur les écrans d'inscription (donnée de route `carte` sur
    `/auth/inscription`, `/auth/inscription-email`, `/auth/profil`, `/auth/telephone`, et `/auth/verification?inscription=N`
    seulement quand c'est le code d'une inscription — `AuthLayout.activer()`), le formulaire est dans une **carte vert
    foncé translucide** (80 %, flou 18 px, bord blanc à 16 %, coins de 24 px ; fond opaque si `prefers-reduced-transparency`
    ou sans `backdrop-filter`), champs sombres avec **pictogramme à droite** (`order` CSS) et bord orange au focus,
    titres alignés à gauche, « Déjà membre ? Se connecter » à droite. À gauche (≥ 960 px) : « REJOIGNEZ GRATUITEMENT »,
    « Voyagez ensemble, <orange>au juste prix</orange>. » et un court texte, à la place de l'accroche. **Accent : orange de
    la charte** (la maquette est bleue) ; texte orange éclairci `#ffb84d` sur la photo (≥ 3,8:1, grand texte). Différence
    avec la maquette : libellés au-dessus des champs, pas flottants dans le champ ; parcours par étapes conservé (un seul
    formulaire demanderait de changer le backend). La connexion garde le formulaire posé sur la photo.
  - **Images** : `frontend/public/fond-connexion.webp` est fournie (fresque, 1376×768, recompressée de 750 à 60 Ko, WebP
    qualité 72) ; `fond-connexion-mobile.webp` reste à fournir (conseillé : 828×1600,
    ≤ 120 Ko pour le mobile), servies à la racine du site (`public/` : pas de `src/assets` dans ce projet) ; redémarrer
    `ng serve` après un ajout. **Tant qu'elles manquent** : l'événement `error` retire la `<picture>` et le dégradé vert
    de la charte (`#0c6b3f` → `#084a2b`) reste en fond (test dans `auth-layout.spec.ts`).
  - **Style partagé** : `features/auth/auth-photo.scss`, appliqué **une seule fois** par `AuthLayout`
    (`ViewEncapsulation.None`, tout sous `.auth-photo` / `.auth-panneau`) pour toutes les pages ; il remplace
    `auth-epure.scss`, `auth-commun.scss` et `google-telephone.scss`. Les écrans ne gardent que leurs particularités.
    Budget `anyComponentStyle` : avertissement relevé de 4 à **7,5 ko** (la feuille unique fait ~7,2 ko ; erreur à 8 ko).
  - **Accessibilité** : libellés visibles, contour de focus blanc de 3 px, halo blanc sur les champs, `prefers-reduced-motion`
    (pas d'animation d'apparition). Contraste du texte blanc sur la vraie photo sous le voile : ≥ 5,8:1 (calculé sur
    les pixels de la photo, zone du formulaire) ; bouton orange / texte sombre 8:1 ; erreurs de champ en pastille claire
    (rouge sur blanc 5,2:1).
  - Vérifié dans le navigateur intégré (1280 px et 375 px, avec la vraie photo ; l'image mobile de test n'est pas commitée).
- **Textes légaux** (branche `pages-legales`) : pages publiques `/conditions` et `/confidentialite`
  (`features/legal`, cadre commun `page-legale.ts` : contact `CONTACT_LEGAL`, date `VERSION_LEGALE`), liens depuis
  l'inscription, le pied des écrans de connexion, le profil, et dans l'appli mobile (`LiensLegaux`, qui ouvre le
  site). Éditeur présenté comme projet de fin d'études (ISEP Diamniadio), loi sénégalaise n° 2008-12, CDP.
  Mise à jour du 10/11/2026 (branche `legal-position-mobile`) : partage de position **en arrière-plan** depuis l'appli
  mobile (suivi du conducteur pendant le trajet, arrêt à la fin du trajet, position supprimée ensuite) ajouté aux
  conditions (§10) et à la confidentialité (§3 et §6) ; `VERSION_LEGALE` = « 10 novembre 2026 ».
  **À mettre à jour** (texte et date de version) à chaque fonctionnalité qui collecte ou transmet des données, ou
  qui change les règles (commission, annulation). La suppression des comptes est automatisée (voir ci-dessous).
- **Suppression de compte (RGPD)** (branche `suppression-compte`) : backend `sn.isep.Convoiturage.suppression`
  (`SuppressionCompteService`, `AnonymisationService`, `AnonymisationPlanifiee`), migration V2026_11_13_1500
  (colonnes `date_suppression_demandee` et `date_anonymisation` ; statuts `SUPPRESSION_DEMANDEE` et `SUPPRIME` ; objet
  OTP `CONFIRMATION_SUPPRESSION`). **API** : `POST /api/moi/suppression` (`{motDePasse, code}`) et
  `POST /api/moi/suppression/code` (envoie le code des comptes sans mot de passe, c.-à-d. Google). Confirmation par
  mot de passe (compté dans le limiteur de connexion) ou par code email/SMS ; compte administrateur refusé (403).
  **Refus 409** (propriété `obstacles` + message clair) tant que l'utilisateur a un trajet à venir ou en cours en tant que
  conducteur (`PUBLIE`, `COMPLET`, `EN_COURS`), une réservation `ACCEPTEE` à venir, ou un paiement **en ligne**
  `EN_ATTENTE` / `REMBOURSEMENT_DEMANDE` (les espèces sont suivies par la réservation) ; les réservations `EN_ATTENTE`
  sont annulées automatiquement. **Délai de grâce de 30 jours** : statut `SUPPRESSION_DEMANDEE`, jetons révoqués,
  compte invisible (recherche et alertes ne retiennent que `ACTIF`, profil public 404) ; **se reconnecter (mot de passe ou
  Google) annule** la suppression (réponse `suppressionAnnulee: true`, pas de `DELETE` : la session est déjà fermée).
  **Anonymisation** : `AnonymisationPlanifiee` (`@Scheduled`, tous les jours à 3 h Dakar, un compte par transaction)
  efface identité (prénom « Utilisateur », nom « Supprimé »), email, téléphone, identifiant Google, mot de passe, photo
  et fichiers, présentation, documents et fichiers, photos de véhicules, contacts d'urgence, préférences, alertes,
  jetons push, notifications, sessions, codes OTP, position, `paiement.numero_telephone`, texte des messages envoyés
  (« [message supprimé] ») ; **conserve** paiements et réservations, trajets, véhicules (désactivés, immatriculation
  `SUPPR-<id>`), avis (note et commentaire), signalements, journal d'administration. Les fichiers ne sont effacés
  qu'après validation de la base. **Emails** (SMS à défaut) via `AlertesSecurite` : demande (avec date), annulation,
  suppression définitive. **Site** : « Supprimer mon compte » dans le profil → `/profil/suppression`
  (`features/profil/suppression-compte.ts`, mot de passe ou code), message sur la connexion après la demande, bandeau
  « Suppression annulée » dans l'espace connecté. **Mobile** : `lib/features/profil/suppression_compte.dart`
  (`/profil/suppression`, `Session.supprimerCompte`, message sur la connexion, bandeau à la reconnexion).
  **Textes légaux** : confidentialité §6 (suppression, 30 jours, effacé / conservé, paiements 10 ans) et §9, conditions
  (compte) ; `VERSION_LEGALE` reste « 13 novembre 2026 » (date de la modification). Tests :
  `SuppressionCompteParcoursTest` (refus, annulation par reconnexion, anonymisation, compte Google par code),
  `profil.service.spec.ts`, `suppression_compte_test.dart`.
- La base garde **toutes les tables** du diagramme de classes (migration V1, à ne jamais modifier) : chaque
  module les reprend ou les fait évoluer par de nouvelles migrations datées.
- **12 Calcul automatique du prix** (branche `12-prix`) : module backend `tarification` (repris de l'archive :
  `MoteurFormule`, coefficients `parametre_tarification` ; sans l'entité `Tarification`, liée à `Trajet`, qui
  reviendra avec le module 03) + `MoteurIA` : appelle `ia-tarification` (`POST /v1/estimations`) puis la
  formule ; repli sur la formule seule si erreur, réponse incohérente ou plus de 2 s (`app.ia.delai`), et pause
  de 30 s après un échec. Consommation : déclarée > prédite par l'IA > estimée ; la météo s'applique toujours.
  Service `ia-tarification` : XGBoost sur ADEME Car Labelling (MAE 0,35 L/100 km), Open-Meteo attendu 1,5 s au
  plus. En dev, `IA_TARIFICATION_URL` vaut `http://localhost:8000` ; en test, formule seule. À brancher dans
  `TrajetService` (module 03) : `moteur.estimer(new DemandeEstimation(...))`.
- **03 Gestion des trajets** (branche `03-trajets`, partie de `12-prix`) : module backend `trajet` repris de
  l'archive (publication avec escales, estimation du prix via `MoteurTarification`, modification, annulation,
  démarrer/terminer, « mes trajets », recherche PostGIS publique, détail public ; itinéraire Google Routes si
  `GOOGLE_MAPS_API_KEY`, sinon vol d'oiseau ×1,25). `pom.xml` : `hibernate-spatial` remis. Écrans Angular
  `features/trajets` (publier avec carte Leaflet et détail du prix IA, détail, mes trajets) et
  `features/recherche` ; Leaflet ajouté (`package.json`, `angular.json`). Les **alertes de recherche** sont décrites
  plus bas (branche `alertes-recherche`).
- **Accueil public** (branche `accueil-public`, site seulement, backend inchangé), façon BlaBlaCar : un visiteur sans
  compte cherche des trajets et voit leur détail ; la connexion n'est demandée qu'au moment d'agir.
  - **Routes** (`app.routes.ts`) : groupe public `PublicLayout` placé avant l'espace connecté, retenu par
    `canMatch: [visiteurMatch]` (pas de session) : `/accueil` (`AccueilPublic`), `/rechercher` et `/trajets/:id`
    (`idTrajetMatch` : identifiant numérique seulement, pour laisser `/trajets/publier` et `/trajets/mes-trajets`).
    Un utilisateur connecté ne passe pas `visiteurMatch` et retrouve les mêmes chemins dans son espace ; `/` redirige
    vers `/accueil` (donc vers l'accueil de l'espace une fois connecté, `/admin` pour l'administrateur). Toute autre
    page (publier, guidage, messages…) passe par `connecteGuard` → `/auth/connexion?retour=…`.
  - **Accueil** (`features/public`) : titre, grande barre de recherche, « Trajets populaires » (liste fixe Dakar →
    Thiès, Mbour, Saint-Louis, Touba, Kaolack et Thiès → Dakar, **sans prix** : l'API n'a pas de statistiques et
    l'estimation est réservée aux conducteurs car elle demande un véhicule ; un clic lance la recherche du jour),
    panneau de confiance (conducteurs vérifiés, paiement Wave, messagerie interne, signalement), bloc « Vous avez une
    voiture ? Partagez vos frais » → Publier. En-tête public : logo (pictogramme seul sous 430 px), Rechercher, Publier,
    Se connecter / S'inscrire (avec `retour` vers la page en cours, sauf depuis l'accueil), « Mon espace » si connecté ;
    pied de page avec les textes légaux, lien d'évitement « Aller au contenu ».
  - **Barre de recherche commune** `features/recherche/barre-recherche.ts` (départ, arrivée, inverser, date,
    passagers, bouton ; valeurs en liaison à double sens chez le parent, filtres projetés) : utilisée par
    Rechercher (colonne) et par l'accueil (ligne à partir de 960 px). `parametres-recherche.ts` construit les
    paramètres d'URL de la recherche. Les filtres de Rechercher passent de `formControlName` à `[formControl]`.
  - **Version visiteur** : Rechercher masque « Mes alertes » et remplace « Créer une alerte » par « Se connecter pour
    créer une alerte » (retour sur la même recherche) ; le détail remplace Réserver par une carte « Se connecter pour
    réserver / S'inscrire », « Écrire à … » par « Se connecter pour écrire à … » (retour `/trajets/<id>`), masque le
    guidage vocal ; carte, itinéraire, prix, véhicule, préférences et avis restent visibles.
  - **Retour après connexion** : `SessionService.memoriserRetour()` (sessionStorage `covoitia.retour`, adresse
    interne seulement via `core/auth/retour.ts`) sur les écrans Connexion et Inscription (une visite sans `retour`
    l'efface), puis `pageApresConnexion()` (utilisé une seule fois) après connexion, code de vérification, Google et
    « Votre numéro » Google. Les liens Connexion ⇄ Inscription gardent `retour` ; `invitesGuard` envoie un utilisateur
    déjà connecté vers le retour prévu.
  - **Intercepteur** : un 401 sans jeton envoyé (visiteur) ne déclenche plus « session expirée » ni la redirection
    vers la connexion. Textes légaux : « Retour à l'accueil » pour un visiteur.
  - **API vérifiée, sans changement** : `GET /api/trajets/recherche`, `/api/trajets/{id}`, `/api/utilisateurs/{id}`
    et `/avis` étaient déjà publics (`SecurityConfig`). Un visiteur reçoit le conducteur en prénom + initiale, photo,
    note et préférences, le véhicule en marque, modèle, année, énergie et photo : ni téléphone, ni email, ni
    documents, ni immatriculation, ni tarification interne (réservée au conducteur du trajet). Remarque : le détail
    par identifiant reste public pour tous les statuts (annulé, terminé), motif d'annulation compris.
- **06 Notifications** (branche `06-notifications`, partie de `07-administration`) : module backend `notification`
  (repris de l'archive) — `NotificationService.notifier(destinataire, type, priorite, titre, contenu, lien)` :
  enregistrée dans `notification` (lien vers l'écran, migration V2026_10_28_0900), push FCM vers tous les appareils
  de l'utilisateur (voir « Notifications push » ci-dessous), et **email (sinon SMS) si `Priorite.IMPORTANTE`**.
  `NotificationsActivite` écoute `ReservationEvenements`, `TrajetModifie` et `AvisPublie` (« Nouvel avis : 4/5 », lien
  vers `/profil`, qui affiche les avis reçus) avant validation de la transaction ;
  `RappelsTrajet` prévient conducteur et passagers 1 h avant le départ (toutes les 5 min, sans doublon) ; les
  décisions de l'admin passent aussi par là. Écrans : cloche avec compteur dans l'en-tête (rafraîchi toutes les
  30 s) et `/notifications`.
- **Notifications push** (branche `push-notifications`, complète le module 06 ; projet Firebase `yobalemasn-9a0a4`) :
  table `appareil` (un jeton FCM par téléphone ou navigateur, `plateforme` ANDROID / IOS / WEB, unique, 10 par compte
  au plus) et `utilisateur.push_active` (migration V2026_11_13_1000, qui reprend l'ancienne colonne `fcm_token`,
  désormais inutilisée). API : `POST /api/moi/appareils` `{jeton, plateforme}` (idempotent ; un jeton connu d'un autre
  compte passe à l'utilisateur courant), `DELETE /api/moi/appareils/{jeton}` (déconnexion), `GET`/`PUT
  /api/moi/notifications/preferences` `{pushActive}` ; `PUT /api/moi/fcm-token` gardé pour compatibilité. Toute
  notification créée par `NotificationService.notifier` (réservation, acceptation, message, trajet, position partagée,
  rappel, alerte, avis, décisions de l'admin…) part en push si `pushActive` : un événement par appareil, envoyé
  **après validation de la transaction et en arrière-plan** (`@Async` + `@TransactionalEventListener` ; rien si la
  transaction est annulée, une panne FCM ne bloque rien). Données : `type`, `lien`, `notificationId`. Android : canal
  `yobalema_notifications` ; navigateur : message « données seules » affiché par le service worker. Jeton refusé par
  FCM (`UNREGISTERED`, `INVALID_ARGUMENT`, `SENDER_ID_MISMATCH`) → supprimé (`PushSender.Resultat.JETON_INVALIDE`).
  Clé du compte de service : `app.firebase.credentials-path` dans `application-local.yml` ou `FIREBASE_CREDENTIALS_PATH`
  (fichier hors du dépôt) ; absente ou illisible → push journalisés (`[PUSH simulé]`) ; toujours simulés en test.
  **Site** : `features/notifications/push.service.ts` (Firebase chargé à la demande), `public/firebase-messaging-sw.js`
  (affiche le push si aucun onglet n'est visible, ouvre le lien au clic ; onglet visible → cloche rafraîchie), bloc
  « Notifications push » en haut de `/notifications` (préférence du compte + bouton « Activer sur ce navigateur », la
  permission devant suivre un clic). Jeton réenregistré à l'ouverture de l'espace connecté si la permission est déjà
  accordée, retiré à la déconnexion (`SessionService.avantDeconnexion`). **À compléter** : `environment.firebase`
  (`apiKey`, `appId` de l'application Web Firebase, `vapidKey`) ; tant que c'est vide, le bloc affiche « pas encore
  disponibles ». **Appli mobile** : `lib/core/push.dart` (`ServicePush`, `PlateformeFirebase`, `destinationPour`) —
  après connexion, permission Android 13+ (`POST_NOTIFICATIONS`), jeton enregistré et renouvelé (`onTokenRefresh`) ;
  à la déconnexion, `DELETE` puis `deleteToken` ; tap sur un push (appli fermée ou en arrière-plan) → écran du lien
  (liens du site sans équivalent → Notifications) ; appli à l'écran → bandeau « Ouvrir ». Interrupteur « Notifications
  push » dans le Profil (`features/notifications/preferences_push.dart`). `android/app/google-services.json` n'est
  **pas commité** (`.gitignore`) : à copier depuis la console Firebase ; sans lui, l'appli se construit sans push.
  iOS non configuré (clé APNs et `GoogleService-Info.plist` à ajouter).
- **Alertes de recherche** (branche `alertes-recherche`, complète le module 03) : package backend `recherche` repris
  de l'archive (table `alerte_recherche`, migration V2026_10_25_1600) — `/api/moi/alertes` (créer, lister, supprimer ;
  10 alertes à venir au plus). À la publication d'un trajet (`TrajetPublie`, après validation de la transaction,
  sans jamais faire échouer la publication), chaque alerte du même jour dont le départ et l'arrivée sont proches
  du tracé, dans le bon sens, reçoit une notification `ALERTE_TRAJET` (lien vers le trajet ; prix max et
  « femmes uniquement » respectés). Écran : bouton « Créer une alerte » sous les résultats de Rechercher et bloc
  « Mes alertes » (`features/alertes`).
  **Appli mobile** (branche `mobile-alertes`) : mêmes écrans dans `mobile/lib/features/alertes` (`AlertesService`,
  `BoutonCreerAlerte` sous les résultats de Rechercher, `BlocMesAlertes`) ; pas de rayon ni de prix max côté mobile
  (valeurs par défaut du serveur).
- **07 Administration** (branche `07-administration`) : back-office `/admin` avec son propre cadre (menu latéral,
  `features/admin`) — tableau de bord (statistiques), **validation des documents** (file filtrable, aperçu du
  fichier, informations à vérifier, valider / refuser avec motif obligatoire ; `recalculerStatutConducteur`
  appelé à chaque décision), liste et **fiche utilisateur** (véhicules, documents, historique), **bloquer /
  bannir** avec motif obligatoire et **débloquer** (sessions fermées). Chaque décision est enregistrée dans
  `action_admin` et envoyée à l'utilisateur par email (ou SMS) via `AvisUtilisateurs` ; `utilisateur.derniere_connexion`
  est mis à jour à chaque émission de jetons (migration V2026_10_27_1500). Le raccourci de développement
  `POST /api/dev/moi/valider-conducteur` (module 03) a été retiré : l'admin valide désormais les documents.
- **04 Facturation** (branche `04-facturation`) : comprend aussi les **réservations** (non attribuées dans la
  répartition ; reprises de l'archive). Package `reservation` (demande avec moyen de paiement, acceptation/refus,
  annulation, embarquement PIN/QR, événements `ReservationEvenements` à écouter par le module 06) et package
  `facturation` (`FournisseurPaiement` : **Wave réel** via l'API Checkout + webhook signé
  `/api/paiements/webhooks/wave` ; `OrangeMoneyFournisseur` **non branché** : l'API Sonatel n'est documentée qu'aux
  comptes du portail developer.orange-sonatel.com ; historique `/api/moi/paiements`, reçus). Règles **provisoires,
  à confirmer avec l'encadrant** : aucune commission, remboursement intégral de toute annulation avant le départ.
  Wave exige HTTPS (clés `WAVE_API_KEY`, `WAVE_SECRET_WEBHOOK`, `PAIEMENT_URL_RETOUR`) : en local, tunnel ngrok.
  Écrans : réserver (détail d'un trajet), demandes et embarquement (conducteur), `/reservations`, `/paiements`, reçu.
  **QR code d'embarquement sur le site** (branche `web-qr-embarquement`) : le passager voit le QR sous son code
  (`shared/ui/qr-code.ts`, bibliothèque `qrcode` chargée à la demande) ; le conducteur peut le scanner
  (`shared/ui/scanner-qr.ts` : caméra arrière, `BarcodeDetector` du navigateur sinon `jsqr` chargé à la demande ;
  bouton affiché seulement si une caméra est accessible, c'est-à-dire en HTTPS ou sur localhost).
  **PayDunya** (branche `04-paydunya`) : agrégateur qui relaie **Wave et Orange Money Sénégal** (`PayDunyaClient`,
  `PayDunyaFournisseur`, un bean par moyen dans `PayDunyaConfig`). Clés `PAYDUNYA_MASTER_KEY`, `PAYDUNYA_PRIVATE_KEY`,
  `PAYDUNYA_TOKEN`, `PAYDUNYA_MODE` (`test` = sandbox, sans argent réel). Facture « paiement avec redirection »
  limitée au canal choisi ; IPN `/api/paiements/webhooks/paydunya` (formulaire, `data[hash]` = SHA-512 de la clé
  principale), envoyé seulement si `PAIEMENT_URL_API` (adresse publique de l'API) est renseignée ; dans tous les cas,
  l'état est redemandé à PayDunya (`checkout-invoice/confirm`) et vérifié au retour du passager
  (`POST /api/paiements/{ref}/verifier`). Remboursement par déboursement vers le portefeuille du passager : production
  seulement (en test, le paiement reste « remboursement demandé »). Si Wave direct est aussi configuré, il passe avant
  PayDunya pour Wave (pas de frais d'intermédiaire). `paiement.fournisseur` vaut `PAYDUNYA`, `WAVE`… 
- **05 Évaluations et avis** (branche `05-avis`) : package `avis`, table `evaluation` (migration
  V2026_10_28_1400, classe EVALUATION). Après un voyage effectué (réservation `TERMINEE`), le passager note son
  conducteur et le conducteur note ce passager : 1 à 5 étoiles + commentaire, une fois par sens, dans les 14 jours
  suivant le départ ; chaque avis recalcule `utilisateur.note_moyenne` (filtre « note minimale » de la recherche).
  API `POST /api/reservations/{id}/evaluation`, `GET /api/moi/avis-a-donner`, `GET /api/utilisateurs/{id}/avis`
  (public). Événement `AvisEvenements.AvisPublie`, notifié à la personne notée (module 06). Écrans `features/avis` : bloc
  « Donnez votre avis » (Mes réservations, Mes trajets), réputation du conducteur (détail d'un trajet).
  Les **signalements** (classe SIGNALEMENT) sont décrits plus bas (module 10). Le profil (module 01) peut afficher
  `GET /api/utilisateurs/{id}/avis` pour son compteur d'avis.
- **10 Signalements** (branche `signalements`) : package backend `signalement`, table `signalement` (migration
  V2026_11_10_1400, classe SIGNALEMENT : motif, description, statut, décision de l'administrateur, dates, signaleur,
  personne visée, administrateur, trajet facultatif). La même migration ajoute `AVERTISSEMENT` et `SIGNALEMENT_CLASSE`
  au journal `action_admin`. **Règles** : on ne signale que quelqu'un avec qui on a partagé un trajet (réservation
  acceptée ou terminée, passager ↔ conducteur ; `ReservationRepository.ontPartageUnTrajet`), jamais soi-même ni un
  administrateur ; un seul signalement ouvert (`EN_ATTENTE` / `EN_COURS`) par couple signaleur → signalé (index unique
  partiel) ; 5 signalements par jour et par signaleur au plus (constante `SignalementService.MAX_PAR_JOUR`, 429) ;
  motifs `COMPORTEMENT`, `CONDUITE_DANGEREUSE`, `NON_PRESENTATION`, `ANNULATION_TARDIVE`, `FRAUDE_DOCUMENTS`,
  `HARCELEMENT`, `AUTRE` (description de 500 caractères, obligatoire pour `AUTRE`) ; pas de pièce jointe ni de
  suspension automatique (la décision reste humaine). **Modération** : `PRENDRE_EN_CHARGE` (→ `EN_COURS`) puis une
  décision motivée : `CLASSER_SANS_SUITE` (→ `REJETE`), `AVERTIR` (notification importante au signalé), `BLOQUER` ou
  `BANNIR` (réutilisent `AdminService`, qui trace, ferme les sessions et prévient) — ces trois dernières donnent
  `TRAITE`. Chaque décision est inscrite dans l'historique du compte signalé (`AdminService.tracerDecision`) et le
  signaleur reçoit une notification `SIGNALEMENT_TRAITE` ; il ne voit jamais le détail de la décision, et le signalé ne
  voit jamais l'identité du signaleur. API : `POST /api/signalements`, `GET /api/signalements/mes`, et pour les
  administrateurs `GET /api/admin/signalements` (filtres `statut`, `utilisateur`, pagination),
  `GET /api/admin/signalements/{id}`, `PATCH /api/admin/signalements/{id}` (`{decision, message}`).
  **Site** (`features/signalements`) : lien « Signaler … » (`BoutonSignaler`) dans Mes réservations (conducteur) et
  dans les demandes reçues par le conducteur (passagers) → `/signaler/:idUtilisateur?trajet=&nom=` (motif +
  description) ; `/signalements` (Mes signalements). **Back-office** : `/admin/signalements` (menu « Signalements »,
  filtre par statut, prise en charge, décision motivée) et lien « Voir les signalements visant cet utilisateur » sur la
  fiche utilisateur (`?utilisateur=`). **Mobile** (`lib/features/signalements/signalements.dart`) : bouton « Signaler … »
  sur Mes réservations et sur les passagers d'un trajet du conducteur, formulaire, « Mes signalements » depuis le
  Profil ; la modération reste sur le site. Tests : `SignalementsParcoursTest`, `signalements.models.spec.ts`,
  `test/signalements_test.dart`.
- **09 Messagerie** (fonctionnalité facultative, branche `09-messagerie`) : package `messagerie`, tables `conversation`
  (une par trajet et par passager ; le conducteur est celui du trajet) et `message` (migration V2026_10_29_1000).
  Un passager écrit au conducteur d'un trajet à venir (même sans réserver) ou d'un trajet réservé ; le conducteur
  écrit aux passagers qui ont réservé ; on peut écrire jusqu'à 7 jours après le départ (ensuite lecture seule) ;
  30 messages au plus par 10 minutes. API `POST /api/trajets/{id}/conversation`, `/api/moi/conversations` (liste,
  `/non-lus`, `/{id}` qui marque lus, `/{id}/messages`). Événement `MessageEnvoye` → notification `MESSAGE_RECU`
  (une seule non lue par conversation). Écrans `features/messages` : icône Messages avec compteur dans l'en-tête,
  `/messages`, `/messages/:id` (rafraîchi toutes les 5 s), bouton « Écrire à … » (détail d'un trajet, Mes
  réservations, demandes reçues par le conducteur).
- **Messages vocaux** (branche `messages-vocaux`, complète le module 09, site + mobile) : migration V2026_11_18_1000
  (`message.type` TEXTE / VOCAL, `fichier_audio`, `type_mime_audio`, `duree_ms`, `forme_onde`, `date_ecoute` ;
  `contenu` devient facultatif avec une contrainte CHECK ; `signalement.id_message`). **Contrôles serveur**
  (`AnalyseAudio`, sans dépendance) : format reconnu aux octets (WebM, Ogg Opus/Vorbis, MP4/M4A, AAC ADTS ; piste vidéo
  refusée) et **durée lue dans le fichier** (dernier horodatage WebM — MediaRecorder n'écrit pas la durée —, dernière
  page Ogg, `mvhd` ou fragments MP4, trames AAC) ; refus sous 1 s ou au-delà de 5 min (+1 s de tolérance) ; taille
  maximale `app.messagerie.vocal.taille-max` (3 Mo) ; forme d'onde facultative (64 niveaux 0-100 au plus). Fichiers dans
  `<app.stockage.repertoire>/vocaux` (hors du dépôt, nom UUID), effacés si la transaction échoue. **API** :
  `POST /api/moi/conversations/{id}/vocaux` (multipart `fichier`, `formeOnde`), `GET …/messages/{idMessage}/audio`
  (deux participants seulement, 404 pour les autres ; requêtes Range → 206), `POST …/messages/{idMessage}/ecoute`
  (destinataire : « écouté » + lu). `MessageDto` : `type`, `dureeMs`, `formeOnde`, `audioDisponible`, `ecoute`.
  Aperçus (liste, notification, push) : « 🎤 Message vocal (0:23) » (`Message.apercu`). **Signalements** :
  `idMessage` facultatif dans `POST /api/signalements` (message reçu de la personne visée, même sans réservation
  commune) ; le back-office affiche le message et écoute le vocal par `GET /api/admin/signalements/{id}/audio`.
  **Anonymisation** : fichiers audio effacés après validation, message « [message supprimé] ». **Tâche planifiée**
  `NettoyageVocaux` (3 h 30, Dakar) : fichier effacé 180 jours après le départ du trajet (`conservation`, « vocal
  expiré ») et fichiers orphelins de plus d'une heure supprimés. **Site** (`features/messages`) : `vocal.ts`
  (`EnregistreurVocal` sur une `PlateformeAudio` simulable : MediaRecorder WebM Opus ou MP4 sous Safari, niveaux Web
  Audio, minuteur, refus du micro / navigateur incompatible / HTTP expliqués, moins d'1 s ignoré, envoi automatique à
  5 min), champ vide → bouton micro, clic → enregistrement avec Annuler / Envoyer ; `bulle-vocale.ts` (lecture du
  fichier chargé en blob avec le jeton, forme d'onde cliquable et pilotable au clavier, 1x / 1,5x / 2x, micro bleu
  « écouté », un seul vocal à la fois) ; drapeau « Signaler ce message » sur les messages reçus (`/signaler/:id?message=`).
  **Mobile** : `lib/features/messages/vocal.dart` (`ControleurVocal` : maintenir pour enregistrer, glisser à gauche
  pour annuler, vers le haut pour verrouiller avec Supprimer / Pause / Envoyer, relâcher pour envoyer),
  `audio_plateforme.dart` (`record` : AAC/M4A 48 kbit/s mono ; `just_audio` : lecture d'une copie temporaire
  téléchargée par `Api.telecharger`, effacée à la fermeture), `vocal_widgets.dart` (bulle, bandeaux) ; appui long sur
  un message reçu → « Signaler ce message ». Permissions `RECORD_AUDIO` et `NSMicrophoneUsageDescription`.
  **Textes légaux** du 18/11/2026 (messages vocaux, accès, 6 mois de conservation, effacement). Tests :
  `MessagesVocauxParcoursTest`, `AnalyseAudioTest`, `vocal.spec.ts`, `messages.service.spec.ts`,
  `test/vocal_test.dart`. Limite connue : un vocal WebM enregistré sur le site ne se lit pas sur iOS (AVPlayer).
- **08 Géolocalisation** (fonctionnalité facultative, branche `08-geolocalisation`) : la carte, la recherche de lieu,
  le départ et l'arrivée posés sur la carte, le tracé et la distance existaient déjà (modules 03 et 12). Ajouts :
  service `core/carte/position-actuelle.ts` (API de géolocalisation du navigateur : HTTPS ou localhost, autorisation de
  l'utilisateur, messages en cas de refus / délai / indisponibilité) ; bouton « Ma position » sur le champ Départ
  (`ChampLieu` avec `[maPosition]="true"`, Publier et Rechercher) qui retrouve l'adresse (Nominatim) et prévient si la
  position est approximative (> 500 m) ; lien « Itinéraire vers le point de départ (Google Maps) » sur le détail d'un
  trajet, pour le passager. **Guidage vocal** (branche `web-guidage-vocal`) : écran `/trajets/:id/guidage`
  (`features/trajets/guidage`) — passager vers son point de prise en charge, conducteur vers le départ ; à pied ou
  en voiture ; position suivie (`PositionActuelle.suivre`, `watchPosition`), itinéraire et manœuvres OSRM des
  serveurs FOSSGIS `routing.openstreetmap.de` (sans clé, CORS ; à remplacer en production), consignes en français
  (`core/carte/itineraire.ts`), logique d'annonce et de recalcul hors tracé dans `core/carte/guide.ts` (testée),
  synthèse vocale du navigateur (`core/voix.ts`, coupable, choix mémorisé), écran gardé allumé (Wake Lock).
  La carte (`shared/carte/carte.ts`) a des marqueurs `moi` / `voiture` et un mode `[suivre]`.
  **Suivi du conducteur en temps réel** (branche `suivi-temps-reel`) : package backend `suivi`, table
  `position_conducteur` (migration V2026_11_06_2130, une ligne par trajet : la dernière position). Le conducteur
  partage à partir d'une heure avant le départ jusqu'à la fin (`POST /api/trajets/{id}/position`, `DELETE` pour
  arrêter) ; seuls lui et les passagers `ACCEPTEE` lisent (`GET`, 204 si rien depuis 30 min). Position effacée à
  l'arrêt, à `TrajetTermine` / `TrajetAnnule`, et purgée après 30 min ; au premier envoi, notification
  `POSITION_PARTAGEE` aux passagers (lien `/trajets/{id}/suivi`). Écrans `features/suivi` : bloc « Position en
  direct » du conducteur (détail de son trajet ; service global `PartagePosition`, au plus un envoi toutes les
  5 s, position différée envoyée à la fin du délai) et page passager `/trajets/:id/suivi` (interrogée toutes les
  5 s, voiture sur la carte, distance à vol d'oiseau et heure estimée, annonces vocales à 2 km, 1 km, 500 m,
  200 m puis « … est au point de rendez-vous ») ; lien « Suivre … en direct » dans Mes réservations.
- **Application mobile** (branche `mobile-passager`, dossier `mobile/`, voir [`mobile/README.md`](mobile/README.md)) :
  Flutter, même API que le site. Premier lot = parcours passager : connexion / inscription / code, recherche sur
  carte (`flutter_map` + OpenStreetMap, Nominatim, « Ma position »), détail et réservation, mes réservations (code
  d'embarquement PIN + QR, paiement PayDunya, annulation), notifications, profil en lecture. Lancer :
  `flutter run -d web-server --web-port 5000` (navigateur), `flutter run` (émulateur Android, API sur `10.0.2.2`),
  ou `--dart-define=API_URL=http://<IP du PC>:8080/api` pour un vrai téléphone. **Parcours conducteur** (branche
  `mobile-conducteur`, onglet « Conduire », `lib/features/conducteur`) : mes trajets, publier (estimation IA, curseur
  dans la fourchette ; jusqu'à 5 escales), mon trajet (accepter / refuser, embarquement par QR code `mobile_scanner` ou
  PIN, démarrer / terminer / annuler). **Messagerie** (branche `mobile-messagerie`, `lib/features/messages`) : icône
  Messages avec compteur, conversations rafraîchies toutes les 5 s, boutons « Écrire à … ». **Avis** (branche
  `mobile-avis`, `lib/features/avis`) : « Donnez votre avis » (Mes réservations, Mes trajets), réputation (détail
  d'un trajet, Profil). **Guidage vocal et suivi en direct** (branche `mobile-guidage-suivi`) : mêmes écrans que le
  site (`lib/features/guidage`, `lib/features/suivi`, logique `lib/core/guide.dart` et `itineraire.dart` portée du
  site et testée), voix `flutter_tts`, écran allumé `wakelock_plus` ; le partage du conducteur continue appli en
  arrière-plan (Android : service au premier plan avec notification ; iOS : `UIBackgroundModes` `location`).
  **Mot de passe oublié** (branche `mobile-mot-de-passe-oublie`, `lib/features/auth/mot_de_passe_oublie.dart`) : lien « Mot de passe oublié ? » sous la connexion, puis les 3 étapes du site (email ou téléphone → code à 6 chiffres, 5 essais, renvoi après le délai → nouveau mot de passe, même règle que l’inscription) via `Session` (`/api/auth/mot-de-passe/oublie`, `/verifier-code`, `/reinitialiser`) ; retour à la connexion avec un message de confirmation.
  **Paiements et reçus** (branche `mobile-paiements`, `lib/features/paiements/paiements.dart`) : entrée « Mes paiements » dans le Profil → `/paiements` (historique `/api/moi/paiements` : paiements comme passager en −, encaissements comme conducteur en + avec total encaissé, moyen, statut, référence ; tirer pour rafraîchir) et `/paiements/:reference/recu` (reçu `/api/paiements/{ref}/recu`, mêmes rubriques que le site, bandeau « Remboursé intégralement le … »), seulement pour les paiements réussis ou remboursés. À la place de « Imprimer / PDF » du site : bouton « Copier le reçu » (texte à coller dans un message ; pas de dépendance PDF).
  **Modification du profil** (branche `mobile-profil`, `lib/features/profil/modifier_profil.dart`) : bouton « Modifier mon profil » dans le Profil → `/profil/modifier`, comme l'en-tête et le bloc « À propos » du site : photo (galerie ou appareil photo via `image_picker`, réduite à 1024 px et réencodée en JPEG, 5 Mo au plus, envoyée tout de suite en multipart à `POST /api/moi/photo` via `Api.envoyerFichier`), prénom, nom et présentation (500 caractères) enregistrés par `PUT /api/moi` (`Session.modifierProfil`, sexe renvoyé inchangé, présentation vide → `null`) ; erreurs du serveur affichées sous le bon champ. Email et téléphone affichés sans pouvoir les modifier : ni le site ni l'API ne le permettent (ce sont les identifiants de connexion ; un changement demanderait une nouvelle vérification par code). La présentation s'affiche dans le Profil. iOS : `NSPhotoLibraryUsageDescription` ajouté.
  **Test sur téléphone Android** (branche `mobile-test-telephone`) : icône d'application (repère vert du logo, icône adaptative Android 8+ et monochrome, générée par `mobile/tool/generer_icone.py`), nom « YOBALEMAsn » (déjà dans le manifeste), script `mobile/tool/lancer-telephone.ps1` qui détecte l'IP Wi-Fi du PC et lance `flutter run --dart-define=API_URL=… --dart-define=SITE_URL=…` (aucune adresse dans le dépôt), liste de contrôle [`docs/test-telephone-android.md`](test-telephone-android.md) (connexion, réservation, QR d'embarquement, guidage vocal, partage de position écran éteint). Le pare-feu Windows doit autoriser le port 8080.
  **Signalements** (branche `signalements`) : voir le module 10.
  **Connexion avec Google** (branche `mobile-google`, `lib/core/google.dart` + `lib/features/auth/google.dart`) : bouton « Continuer avec Google » (séparateur « ou ») sur la connexion et l'inscription. Le package `google_sign_in` (7.x, `authenticate()`, puis déconnexion de Google pour pouvoir choisir un autre compte la fois suivante) fournit l'idToken, envoyé à `POST /api/auth/google` (`Session.connexionGoogle`, **même endpoint que le site, backend inchangé**) qui renvoie la session habituelle. `serverClientId` = ID client **Web** (celui du site), donc l'audience de l'idToken est bien le `GOOGLE_CLIENT_ID` vérifié par `GoogleTokenVerifier` (tokeninfo) ; le client Android n'est reconnu que par le paquet `sn.isep.yobalema` + SHA-1. Les ID clients passent par `--dart-define=GOOGLE_SERVER_CLIENT_ID=…` (et `GOOGLE_IOS_CLIENT_ID` plus tard), jamais dans le dépôt ; `tool/lancer-telephone.ps1` reprend la variable d'environnement du même nom. Cas gérés par `continuerAvecGoogle` (testé sans le plugin via l'interface `ServiceGoogle`) : annulation (rien d'affiché), compte connu → connecté, compte inconnu → `TELEPHONE_REQUIS` → écran `/google/telephone` (numéro + sexe, idToken gardé en mémoire seulement, numéro déjà pris affiché sous le champ) → code de vérification comme à l'inscription, erreur réseau / jeton refusé / plugin mal configuré → message dans le bandeau. Non disponible dans la version navigateur ; iOS à configurer (client iOS + schéma d'URL). Étapes Google Cloud et `gradlew signingReport` : `mobile/README.md`.
  **Escales à la publication** (branche `mobile-escales`, `lib/core/escales.dart` + `lib/features/conducteur/publier.dart`) : « Ajouter une escale » (5 au maximum, comme `@Size(max = 5)` de l'API), chaque escale avec recherche de lieu, « Ma position » ou toucher de la carte (puces « La carte place : Départ / Escale n / Arrivée »), monter / descendre / supprimer ; les escales partent dans `escales` de `/trajets/estimation` et `/trajets` (mêmes endpoints que le site) et comptent dans l'estimation. Le détail d'un trajet et « Mon trajet » les affichaient déjà (carte + liste). **Non existant côté site et API, donc non fait** : prix par tronçon, recherche et réservation d'un segment (le site ne propose pas non plus de choisir l'escale de prise en charge, bien que `idEscaleRamassage` existe dans l'API de réservation).
  Reste : push.
- Tests : `./mvnw test` → 68 tests (dont `InscriptionTelephoneParcoursTest`, `ConnexionExterneParcoursTest`, `AppleTokenVerifierTest`, `MessagesVocauxParcoursTest`, `AnalyseAudioTest`, `SuppressionCompteParcoursTest`, `SignalementsParcoursTest`, `ParcoursCompletTest`, `SuiviPositionParcoursTest`, `TrajetsParcoursTest`, `AlertesRechercheParcoursTest`,
  `ReservationsPaiementsParcoursTest`, `AvisParcoursTest`, `MessagerieParcoursTest`, `PayDunyaParcoursTest`,
  `WaveFournisseurTest`, `PayDunyaFournisseurTest`) ; `npm test` → 125 tests (dont guards, retour après connexion,
  intercepteur visiteur, `BarreRecherche`, paramètres de recherche, inscription Google en étapes, écran de départ par
  numéro et bouton Apple masqué, étapes du profil) ; `flutter test` dans `mobile` → 84 tests ;
  `python -m pytest` dans `ia-tarification` → 20 tests. Dans les tests d'intégration, utiliser des numéros de
  téléphone uniques : ils partagent la base, et l'immatriculation de test reprend les 4 derniers chiffres.

