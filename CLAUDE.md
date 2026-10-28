# YOBALEMAsn — contexte pour Claude Code

Fichier lu automatiquement par Claude Code au début de chaque session. Il résume l'état du projet,
les décisions déjà prises et les pièges connus, pour que n'importe quel membre de l'équipe puisse
reprendre le travail. **Le mettre à jour à la fin de chaque lot de travail.**

## Le projet

PFE : plateforme de covoiturage (Sénégal, prix en FCFA) avec estimation du prix par IA.
Acteurs : passager, conducteur (doit faire valider permis + carte grise par un admin), administrateur,
module IA (microservice sans interface). L'équipe parle français : code métier, messages et commits en français.

| Dossier | Rôle | Stack |
|---|---|---|
| `backend/Convoiturage` | API REST | Spring Boot 4.1, Java 21, PostgreSQL 16 + PostGIS, Flyway, JWT |
| `frontend` | Web passager / conducteur / back-office | Angular 21 |
| `ia-tarification` | Service de prix : consommation prédite (ADEME) + facteur météo (Open-Meteo) | FastAPI, XGBoost |
| *(à créer)* `mobile/` | Application mobile | Flutter |

Les maquettes (PNG) et les diagrammes UML (PowerAMC `.moo`) sont dans [`docs/`](docs/README.md) ;
le diagramme de classes de référence est `docs/conception/CoVoiturage_Diagramme_Classe_nouveau.moo`.
Les tables et entités suivent **les noms du diagramme de classes** (`utilisateur`, `trajet`, `id_trajet`,
`reservation`…). Pour un nouvel écran, partir de la maquette correspondante dans `docs/maquettes/`.

## État au 27/10/2026

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
- Frontend : connexion, inscription, vérification du code, mot de passe oublié (3 écrans successifs),
  téléphone après Google ; espace connecté (`features/espace`, barre de navigation + déconnexion) et page
  d'accueil simple (`/accueil`) ; l'administrateur arrive sur le back-office (`/admin`).
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
- **06 Notifications** (branche `06-notifications`, partie de `07-administration`) : module backend `notification`
  (repris de l'archive) — `NotificationService.notifier(destinataire, type, priorite, titre, contenu, lien)` :
  enregistrée dans `notification` (lien vers l'écran, migration V2026_10_28_0900), push FCM si l'appareil a
  envoyé son jeton (`FIREBASE_CREDENTIALS_PATH`, sinon journalisé), et **email (sinon SMS) si `Priorite.IMPORTANTE`**.
  `NotificationsActivite` écoute `ReservationEvenements` et `TrajetModifie` (avant validation de la transaction) ;
  `RappelsTrajet` prévient conducteur et passagers 1 h avant le départ (toutes les 5 min, sans doublon) ; les
  décisions de l'admin passent aussi par là. Écrans : cloche avec compteur dans l'en-tête (rafraîchi toutes les
  30 s) et `/notifications`. Reste : push dans le navigateur (projet Firebase à créer).
- **Alertes de recherche** (branche `alertes-recherche`, complète le module 03) : package backend `recherche` repris
  de l'archive (table `alerte_recherche`, migration V2026_10_25_1600) — `/api/moi/alertes` (créer, lister, supprimer ;
  10 alertes à venir au plus). À la publication d'un trajet (`TrajetPublie`, après validation de la transaction,
  sans jamais faire échouer la publication), chaque alerte du même jour dont le départ et l'arrivée sont proches
  du tracé, dans le bon sens, reçoit une notification `ALERTE_TRAJET` (lien vers le trajet ; prix max et
  « femmes uniquement » respectés). Écran : bouton « Créer une alerte » sous les résultats de Rechercher et bloc
  « Mes alertes » (`features/alertes`).
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
- Tests : `./mvnw test` → 31 tests (dont `ParcoursCompletTest`, `TrajetsParcoursTest`, `AlertesRechercheParcoursTest`,
  `ReservationsPaiementsParcoursTest`, `WaveFournisseurTest`) ; `npm test` → 27 tests ; `python -m pytest` dans
  `ia-tarification` → 20 tests.

## Répartition du travail (2 développeurs, depuis le 27/10/2026)

Chacun porte des fonctionnalités **complètes**, du backend à l'écran Angular, dans l'ordre indiqué.
Avant de commencer une tâche, vérifier à qui elle revient ; ne pas modifier le code d'une fonctionnalité
de l'autre sans le prévenir.

| Ordre | Doulo (@doulodevpro) | Abdoulaye (@abdoulayewade2) |
|---|---|---|
| 1 | **01 Gestion des utilisateurs** — profil, préférences, photo (backend fait, écrans à faire) | **12 Calcul automatique du prix** — formule puis service IA (FastAPI, XGBoost) |
| 2 | **02 Gestion des véhicules** — véhicules, permis et carte grise | **03 Gestion des trajets** — publication, recherche, carte |
| 3 | **07 Administration** — validation des documents, comptes, statistiques | **04 Facturation** |
| 4 | **06 Notifications** — in-app, push, email/SMS | **05 Évaluations et avis** |

**Non attribué :** application mobile Flutter. L'authentification (déjà faite) est commune : la faire
évoluer en prévenant l'autre.

Pour démarrer un module, regarder d'abord ce qui existait dans `archive/lot1-complet` (par exemple
`backend/Convoiturage/src/main/java/sn/isep/Convoiturage/trajet`, `frontend/src/app/features/trajets`).

**Packages backend :** garder la structure existante `sn.isep.Convoiturage.<module>` (`utilisateur`,
`auth`, `admin`…). Un nouveau module = un nouveau package au même niveau (ex. `vehicule`, `trajet`,
`tarification`, `facturation`, `avis`, `notification`).

**Fichiers partagés, sources de conflits fréquents :** `frontend/src/app/app.routes.ts`, `styles.scss`,
`shared/ui/icone.ts`, `pom.xml`, `SecurityConfig.java`. Y faire des modifications courtes, et fusionner
souvent par petites pull requests.

**Décisions encore ouvertes (à trancher avec l'encadrant) :** commission de la plateforme, règles
d'annulation et de remboursement, prix réels du carburant (valeurs indicatives dans la migration V1),
fournisseur SMS réel.

## Lancer le projet en local (sans Docker)

Prérequis : Java 21+, Maven, Node.js 22+, PostgreSQL 16 + PostGIS 3.x.

1. Une fois : `psql -U postgres -p <port> -f backend/Convoiturage/db/init-local.sql`, puis copier
   `backend/Convoiturage/application-local.example.yml` en `application-local.yml` avec le port du poste.
2. Backend, dans `backend/Convoiturage` : `mvn spring-boot:run -Dspring-boot.run.profiles=dev` → http://localhost:8080
3. Frontend, dans `frontend` : `npm install` puis `npm start` → http://localhost:4200

En profil `dev` : les codes partent **par email** si `spring.mail` est configuré dans `application-local.yml`
(sinon ils sont écrits dans la console du backend, ligne `[SMS simulé]`), et un admin est créé au démarrage
(identifiants dans `application-dev.yml`).

## Conventions

**Backend** (`sn.isep.Convoiturage`, monolithe modulaire : `common`, `auth`, `utilisateur`, `vehicule`,
`trajet`, `tarification`, `reservation`, `notification`, `admin`) :
- Le schéma est géré **uniquement par Flyway** (`db/migration`, `ddl-auto: validate`). Toute modification
  = nouveau fichier **nommé par date et heure** pour éviter les collisions entre les deux développeurs :
  `V2026_10_25_1430__messagerie.sql` (année_mois_jour_heureminute). Ne jamais modifier une migration déjà
  poussée. `out-of-order` est activé en dev/test : une migration plus ancienne fusionnée après une plus
  récente est quand même appliquée.
- Entités JPA avec Lombok ; DTO en `record` regroupés dans des classes `XxxDtos` ; jamais d'entité renvoyée
  directement par un contrôleur.
- Erreurs métier : `ApiException` (→ ProblemDetail). `.surChamp("email")` place l'erreur sous le bon champ
  côté interface ; `.avec("tentativesRestantes", n)` ajoute une information.
- Utilisateur courant : `SecurityUtils.utilisateurCourantId()`. Rôles via `@PreAuthorize` + vérification
  d'appartenance dans les services (mon trajet, ma réservation).
- Pas de dépendance circulaire entre modules : passer par des événements Spring (ex. `TrajetPublie`).
- Module prix : injecter l'interface `MoteurTarification` (bean principal : `MoteurIA` si `app.ia.url` est
  renseignée, sinon `MoteurFormule`), jamais une implémentation directement.

**Frontend** :
- Composants autonomes, signaux, sans zone.js, `ChangeDetectionStrategy.OnPush`, formulaires réactifs typés.
- Appels API : `environment.apiUrl` ; erreurs lues avec `lireErreur()` (`core/api/erreur-api.ts`) ;
  session et jetons dans `SessionService` (intercepteur + guards dans `core/auth`).
- Styles communs (champs, boutons, cartes, couleurs) dans `src/styles.scss` ; budget de 4 ko de style par
  composant. Icônes : ajouter le tracé dans `shared/ui/icone.ts`. Interface mobile-first, fidèle aux maquettes.

**Git** :
- Jamais de travail directement sur `main`. Une branche par fonctionnalité, nommée d'après la répartition :
  `01-utilisateurs`, `02-vehicules`, `03-trajets`, `12-prix`…
- Chaque matin, avant de commencer : `git checkout main`, `git pull`, puis rebaser ou fusionner `main` dans sa branche.
- Fusion dans `main` par pull request, **relue par l'autre** développeur.
- Avant chaque commit : `./mvnw test` (backend) et `npm test` + `npx ng build` (frontend).
- Messages de commit en français : `feat: …`, `fix: …`, `docs: …`.

## Pièges connus

- **Nom de l'application : YOBALEMAsn** (« YOBALEMA » en vert, « sn » en orange). L'ancien nom « CoVoitIA »
  subsiste volontairement dans des identifiants techniques invisibles pour l'utilisateur : variables
  `COVOITIA_*`, `issuer` du JWT, clés de stockage du navigateur (`covoitia.refresh`…), préfixe du QR code
  d'embarquement, package `sn.isep.Convoiturage`, et la migration V1 (ne jamais la modifier). Les renommer
  casserait la configuration des postes et les sessions sans rien changer à l'écran.
- **Vérification des comptes** : un code reçu par **email** valide `emailVerifie`, un code reçu par **SMS**
  valide `telephoneVerifie` (jamais l'un pour l'autre). `Utilisateur.estVerifie()` = au moins l'un des deux.

- **Spring Boot 4** : starters renommés ou séparés (`spring-boot-starter-webmvc`, `-restclient`, `-flyway`,
  `-security-oauth2-resource-server`, `-webmvc-test`). Sans `spring-boot-starter-restclient`, l'application
  ne démarre pas. Jackson 3 (`tools.jackson`), mais les annotations restent `com.fasterxml.jackson.annotation`.
- **Variables d'environnement d'autres projets** : un poste peut définir `DB_URL`, `JWT_SECRET`,
  `SPRING_PROFILES_ACTIVE=mysql,…`. C'est pourquoi nos variables sont préfixées `COVOITIA_` et le profil est
  forcé avec `-Dspring-boot.run.profiles=dev`. Si le backend cherche un pilote MySQL, c'est ce problème.
- **Docker** a été abandonné en local (plantages répétés de Docker Desktop sur des sockets orphelins).
  `compose.yaml` reste disponible en option ; les tests n'en dépendent plus.
- **Port PostgreSQL** : chez Doulo, PostgreSQL 16 est sur **5433** (PostgreSQL 18 occupe le 5432).
- La console PowerShell affiche mal les accents de `psql` (« prÃªtes ») : c'est seulement l'affichage.
- Les avertissements git « LF will be replaced by CRLF » sont normaux sous Windows.
- Sans `GOOGLE_CLIENT_ID`, le bouton Google affiche un message d'information.
- Les limites anti-abus (5 échecs de connexion, quotas de codes par IP) sont en mémoire : suffisant pour
  une instance ; derrière un proxy, activer `server.forward-headers-strategy: framework`.

Documentation détaillée : `README.md` (racine), `backend/Convoiturage/README.md` (endpoints, règles
métier, variables), `frontend/README.md`.
