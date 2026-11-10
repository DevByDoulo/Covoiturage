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
| `mobile` | Application mobile Android / iOS (passager et conducteur) | Flutter 3.41 |

Les maquettes (PNG) et les diagrammes UML (PowerAMC `.moo`) sont dans [`docs/`](docs/README.md) ;
le diagramme de classes de référence est `docs/conception/CoVoiturage_Diagramme_Classe_nouveau.moo`.
Les tables et entités suivent **les noms du diagramme de classes** (`utilisateur`, `trajet`, `id_trajet`,
`reservation`…). Pour un nouvel écran, partir de la maquette correspondante dans `docs/maquettes/`.

## État du projet (10/11/2026)

Le détail de chaque module (tables, API, écrans, règles, branches) est dans
**[`docs/fonctionnalites.md`](docs/fonctionnalites.md)** : le lire avant de toucher à un module. Le compléter à
chaque fonctionnalité ; ici, ne garder qu'une ligne par module.

- **Fait (site + API)** : authentification (code email/SMS, Google, mot de passe oublié, « Rester connecté »),
  01 profil, 02 véhicules et documents, 03 trajets et recherche (PostGIS, carte Leaflet), alertes de recherche,
  12 prix (formule + service IA FastAPI/XGBoost), 04 réservations et paiements (Wave, PayDunya ; QR d'embarquement),
  05 avis, 06 notifications, 07 administration, 08 géolocalisation (Ma position, guidage vocal, suivi du conducteur
  en direct), 09 messagerie, 10 signalements (branche `signalements` : signaler après un trajet partagé, modération
  dans le back-office, aussi dans l'appli mobile), textes légaux (`/conditions`, `/confidentialite`).
- **Appli mobile Flutter** (`mobile/`, voir `mobile/README.md`) : parcours passager et conducteur, messagerie, avis,
  guidage vocal et suivi en direct. Mot de passe oublié fait (branche `mobile-mot-de-passe-oublie`), historique des paiements et reçus (branche `mobile-paiements`), modification du profil — photo, prénom, nom, présentation (branche `mobile-profil`). Reste : Google, push.
- **Pas fait** : push navigateur (Firebase), suppression automatique des comptes.
- Version complète d'avant le 27/10/2026 : étiquette Git `archive/lot1-complet`.
- **Tests** : `./mvnw test` (44), `npm test` (50) + `npx ng build`, `flutter test` dans `mobile` (36),
  `python -m pytest` dans `ia-tarification` (20). Tests d'intégration : numéros de téléphone uniques (base partagée).
- **Textes légaux** (`frontend/src/app/features/legal`) : à mettre à jour (texte + `VERSION_LEGALE`) à chaque
  fonctionnalité qui touche aux données ou aux règles. Version du 10/11/2026 : position en arrière-plan (mobile)
  mentionnée (branche `legal-position-mobile`).

## Répartition du travail (2 développeurs, depuis le 27/10/2026)

Répartition d'origine ci-dessous. **Depuis le 06/11/2026, tout le code se fait sur la machine de Doulo** : plus de
relecture croisée obligatoire ; ne prévenir Abdoulaye que s'il doit tester ou configurer quelque chose chez lui.

| Ordre | Doulo (@doulodevpro) | Abdoulaye (@abdoulayewade2) |
|---|---|---|
| 1 | **01 Gestion des utilisateurs** — profil, préférences, photo (backend fait, écrans à faire) | **12 Calcul automatique du prix** — formule puis service IA (FastAPI, XGBoost) |
| 2 | **02 Gestion des véhicules** — véhicules, permis et carte grise | **03 Gestion des trajets** — publication, recherche, carte |
| 3 | **07 Administration** — validation des documents, comptes, statistiques | **04 Facturation** |
| 4 | **06 Notifications** — in-app, push, email/SMS | **05 Évaluations et avis** |

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
`trajet`, `tarification`, `reservation`, `notification`, `admin`, `suivi`…) :
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
- Fusion dans `main` par pull request (créée par Doulo ; description préparée dans `../pr-*.md`).
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
- **Les tests lisent aussi `application-local.yml`** (importé par `application.yaml`) : toute clé de service ajoutée
  sur le poste (PayDunya, Wave…) peut changer leur résultat. `application-test.yml` neutralise les clés PayDunya ;
  faire de même pour tout nouveau service payant ou externe.
- **Port PostgreSQL** : chez Doulo, PostgreSQL 16 est sur **5433** (PostgreSQL 18 occupe le 5432).
- La console PowerShell affiche mal les accents de `psql` (« prÃªtes ») : c'est seulement l'affichage.
- Les avertissements git « LF will be replaced by CRLF » sont normaux sous Windows.
- Sans `GOOGLE_CLIENT_ID`, le bouton Google affiche un message d'information.
- Les limites anti-abus (5 échecs de connexion, quotas de codes par IP) sont en mémoire : suffisant pour
  une instance ; derrière un proxy, activer `server.forward-headers-strategy: framework`.

Documentation détaillée : `README.md` (racine), `backend/Convoiturage/README.md` (endpoints, règles
métier, variables), `frontend/README.md`.
