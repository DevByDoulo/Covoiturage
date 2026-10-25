# CoVoitIA — contexte pour Claude Code

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
| *(à créer)* `ia/` | Service de prix | FastAPI, scikit-learn, XGBoost |
| *(à créer)* `mobile/` | Application mobile | Flutter |

Les maquettes (PNG) et les diagrammes UML (PowerAMC `.moo`) sont dans [`docs/`](docs/README.md) ;
le diagramme de classes de référence est `docs/conception/CoVoiturage_Diagramme_Classe_nouveau.moo`.
Les tables et entités suivent **les noms du diagramme de classes** (`utilisateur`, `trajet`, `id_trajet`,
`reservation`…). Pour un nouvel écran, partir de la maquette correspondante dans `docs/maquettes/`.

## État au 25/10/2026

**Fait (lot 1) :**
- Backend complet du lot 1 : inscription + OTP SMS, connexion email/téléphone/Google, refresh tokens,
  blocage après 5 échecs, mot de passe oublié ; profils et préférences ; véhicules et documents avec
  validation manuelle par l'admin ; trajets (escales, flexibilité 15–30 min, mode auto/manuel,
  « femmes uniquement ») ; recherche PostGIS ; prix par formule de partage des frais (±10 %) ;
  réservations ; paiement en espèces confirmé par PIN/QR ; notifications in-app + push Firebase ;
  back-office (file de validation, blocage/bannissement, statistiques, coefficients de prix).
- Frontend : authentification (connexion, inscription, OTP, mot de passe oublié, téléphone après Google),
  espace connecté (`features/espace`, barre de navigation) et **F4 Trajets** : publication avec carte,
  escales, estimation et ajustement du prix (`/trajets/publier`), mes trajets, détail avec modification,
  annulation, démarrage et fin (`/trajets/:id`).
- **Carte** : Leaflet + OpenStreetMap, sans clé. Seuls `shared/carte/carte.ts` (affichage) et
  `core/carte/geocodage.ts` (adresse ↔ coordonnées, Nominatim : 1 requête/s, recherche à la validation
  du champ, jamais à chaque frappe) connaissent le fournisseur. Pour passer à Google Maps, remplacer ces
  deux implémentations sans toucher aux écrans. `features/trajets/carte-trajet` est réutilisable pour F5.
- Tests : `./mvnw test` → 11 tests (dont `ParcoursCompletTest`, parcours complet sur PostGIS) ;
  `npm test` → 14 tests. Tout l'auth a été testé à la main entre le front et le back.

**À faire, dans l'ordre conseillé :**
1. Écrans Angular d'après les maquettes : *Mon profil* (préférences, photo), *Mes véhicules et documents*,
   back-office *Validation des documents* et *Fiche utilisateur*.
2. Écran de recherche avec carte (F5, réutiliser `app-carte` et `app-carte-trajet`) ; puis réservations,
   code d'embarquement (PIN/QR), notifications.
3. Lot 2 — service IA FastAPI : jeu de données synthétique à partir de la formule, XGBoost, appel depuis
   `MoteurTarification` avec repli sur `MoteurFormule`.
4. Ensuite : Wave / Orange Money (PayDunya ou CinetPay), chat, avis croisés, SOS et partage de position,
   alertes de recherche, application Flutter.

## Répartition du travail (2 développeurs)

Chacun porte des fonctionnalités **complètes**, du backend à l'écran Angular. Avant de commencer une tâche,
vérifier à qui elle revient ; ne pas modifier le code d'une fonctionnalité de l'autre sans le prévenir.

| Doulo | Son binôme |
|---|---|
| **F3 Service IA de prix** — dossier `ia/` (FastAPI, XGBoost) + branchement dans `MoteurTarification` | **F1 Utilisateurs** — écrans profil, préférences, photo (backend fait) |
| **F4 Trajets** — écrans publication (carte, escales, prix ±10 %), mes trajets (backend fait) | **F2 Véhicules et documents** — écrans conducteur (backend fait) |
| **F5 Recherche** — écran recherche + carte, détail ; alertes de recherche (à créer) | **F6 Réservations** — écrans passager et conducteur (backend fait) |
| **F8 Messagerie** — chat temps réel après demande de réservation (à créer) | **F7 Paiement** — PIN/QR à l'écran (backend fait), Wave / Orange Money (à créer) |
| **F9 Notifications** — push Angular, cloche, email/SMS selon l'urgence (base faite) | **F10 Avis** — notation croisée à l'aveugle (à créer) |
| **F11 Sécurité** — SOS, partage de position, signalements (à créer) | **F12 Administration** — écrans back-office (backend fait) |

**Non attribué :** application mobile Flutter (après les écrans web, à répartir de la même façon).

**Packages backend :** garder la structure existante `sn.isep.Convoiturage.<module>` (`utilisateur`,
`vehicule`, `trajet`, `reservation`, `notification`, `admin`…). Un nouveau module = un nouveau package
au même niveau (ex. `messagerie`, `securite`, `avis`, `paiement`).

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

En profil `dev` : **les codes OTP sont écrits dans la console du backend** (ligne `[SMS simulé]`), les push
sont seulement journalisés, et un admin est créé au démarrage (identifiants dans `application-dev.yml`).

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
- Pas de dépendance circulaire entre modules : passer par des événements (`TrajetEvenements`).
- Le prix passe toujours par l'interface `MoteurTarification` (le service IA viendra s'y brancher).

**Frontend** :
- Composants autonomes, signaux, sans zone.js, `ChangeDetectionStrategy.OnPush`, formulaires réactifs typés.
- Appels API : `environment.apiUrl` ; erreurs lues avec `lireErreur()` (`core/api/erreur-api.ts`) ;
  session et jetons dans `SessionService` (intercepteur + guards dans `core/auth`).
- Styles communs (champs, boutons, cartes, couleurs) dans `src/styles.scss` ; budget de 4 ko de style par
  composant. Icônes : ajouter le tracé dans `shared/ui/icone.ts`. Interface mobile-first, fidèle aux maquettes.

**Git** :
- Jamais de travail directement sur `main`. Une branche par fonctionnalité, nommée d'après la répartition :
  `F4-trajets`, `F3-ia-pricing`, `F1-utilisateurs`…
- Chaque matin, avant de commencer : `git checkout main`, `git pull`, puis rebaser ou fusionner `main` dans sa branche.
- Fusion dans `main` par pull request, **relue par l'autre** développeur.
- Avant chaque commit : `./mvnw test` (backend) et `npm test` + `npx ng build` (frontend).
- Messages de commit en français : `feat: …`, `fix: …`, `docs: …`.

## Pièges connus

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
- Sans `GOOGLE_MAPS_API_KEY`, les distances sont estimées à vol d'oiseau × 1,25 ; sans `GOOGLE_CLIENT_ID`,
  le bouton Google affiche un message d'information.

Documentation détaillée : `README.md` (racine), `backend/Convoiturage/README.md` (endpoints, règles
métier, variables), `frontend/README.md`.
