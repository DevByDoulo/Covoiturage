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
- Frontend : uniquement l'authentification (connexion, inscription, OTP, mot de passe oublié,
  téléphone après Google) + une page d'accueil provisoire.
- Tests : `./mvnw test` → 11 tests (dont `ParcoursCompletTest`, parcours complet sur PostGIS) ;
  `npm test` → 14 tests. Tout l'auth a été testé à la main entre le front et le back.

**À faire, dans l'ordre conseillé :**
1. Écrans Angular d'après les maquettes : *Mon profil* (préférences, photo), *Mes véhicules et documents*,
   back-office *Validation des documents* et *Fiche utilisateur*.
2. Écrans trajets : publication avec estimation du prix (`POST /api/trajets/estimation`), recherche avec carte
   (Google Maps), détail, mes trajets ; puis réservations, code d'embarquement (PIN/QR), notifications.
3. Lot 2 — service IA FastAPI : jeu de données synthétique à partir de la formule, XGBoost, appel depuis
   `MoteurTarification` avec repli sur `MoteurFormule`.
4. Ensuite : Wave / Orange Money (PayDunya ou CinetPay), chat, avis croisés, SOS et partage de position,
   alertes de recherche, application Flutter.

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
  = nouveau fichier `V2__...sql`, `V3__...sql` ; ne jamais modifier une migration déjà poussée.
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
- Une branche par fonctionnalité (`feature/profil`, `feature/vehicules`…), fusion dans `main` par pull request.
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
