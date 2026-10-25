# YOBALEMAsn — Backend (Spring Boot 4, Java 21)

API REST de la plateforme de covoiturage. Lot 1 : authentification JWT + OTP, profils, véhicules,
validation des documents par l'administrateur, publication/recherche de trajets (PostGIS),
réservations, paiement en espèces avec code PIN/QR, notifications push, prix par formule de coût.

## Démarrer en local (sans Docker)

**Une seule fois par poste :**

1. Installer **PostgreSQL 16** pour Windows (installateur EDB, pgAdmin 4 inclus).
2. Installer **PostGIS** : `postgis-bundle-pg16x64-setup-3.x.x-1.exe` depuis
   https://download.osgeo.org/postgis/windows/pg16/ (clic droit → *Exécuter en tant qu'administrateur*,
   décocher « Create spatial database »).
3. Créer l'utilisateur et les bases `covoiturage` / `covoiturage_test` (mot de passe `postgres` demandé) :
   ```powershell
   & "C:\Program Files\PostgreSQL\16\bin\psql.exe" -U postgres -p 5432 -f db\init-local.sql
   ```
4. Copier `application-local.example.yml` en `application-local.yml` et y mettre le port de votre PostgreSQL
   (5432 par défaut, 5433 si deux versions sont installées). Ce fichier n'est pas versionné.

**Ensuite :**

```bash
./mvnw spring-boot:run -Dspring-boot.run.profiles=dev     # API sur http://localhost:8080
```

- Le schéma est créé par **Flyway** (`src/main/resources/db/migration`). Toute évolution = nouveau fichier `V2__...sql`.
- Profil `dev` : les **SMS (OTP)** et les **push** sont écrits dans la console ; un compte admin est créé
  au démarrage (identifiants dans `application-dev.yml`).
- `-Dspring-boot.run.profiles=dev` force le profil même si une variable `SPRING_PROFILES_ACTIVE` d'un autre projet existe sur le poste.
- Docker reste possible en option : `docker compose up -d` lance PostgreSQL + PostGIS sur le port 5432.

### Variables d'environnement (prod)

| Variable | Rôle |
|---|---|
| `COVOITIA_DB_URL`, `COVOITIA_DB_USERNAME`, `COVOITIA_DB_PASSWORD` | Base PostgreSQL/PostGIS |
| `COVOITIA_JWT_SECRET` | Clé HMAC Base64 ≥ 32 octets (`openssl rand -base64 48`) |
| `CORS_ALLOWED_ORIGINS` | Origines autorisées, séparées par des virgules |
| `GOOGLE_MAPS_API_KEY` | Routes API (sinon distances estimées à vol d'oiseau × 1,25) |
| `GOOGLE_CLIENT_ID` | Vérification du « Se connecter avec Google » |
| `FIREBASE_CREDENTIALS_PATH` | JSON du compte de service Firebase (push FCM) |
| `ADMIN_EMAIL`, `ADMIN_PASSWORD`, `ADMIN_TELEPHONE` | Premier administrateur |

## Tests

```bash
./mvnw test
```
`ParcoursCompletTest` rejoue tout le parcours (inscription → validation admin → publication → recherche →
réservation → embarquement PIN) sur la base locale `covoiturage_test`, vidée automatiquement au début de chaque exécution
(PostgreSQL doit tourner, voir ci-dessus).

## Architecture (monolithe modulaire)

```
sn.isep.Convoiturage
├── common        sécurité JWT/CORS, erreurs (ProblemDetail), géo (PostGIS/JTS, polyline), stockage fichiers
├── auth          inscription, OTP SMS, connexion (email/téléphone, Google), refresh tokens, mot de passe oublié
├── utilisateur   profil, préférences, photo, jeton FCM
├── vehicule      véhicules, documents (permis, carte grise), validation
├── trajet        publication, modification, annulation, recherche géographique, itinéraire (Google Routes)
├── tarification  moteur de prix (interface MoteurTarification ; MoteurFormule au lot 1, service IA au lot 2)
├── reservation   réservations, paiement espèces, confirmation d'embarquement PIN/QR
├── notification  notifications in-app + push Firebase (après commit, asynchrone)
└── admin         file de validation, blocage/bannissement, statistiques, coefficients de prix
```
Les modules communiquent par services ou par **événements** (`TrajetEvenements`) pour éviter les dépendances circulaires.

## Rôles

- Inscription → `PASSAGER`. Déclarer un véhicule → `CONDUCTEUR` (le jeton doit être **rafraîchi** via `/api/auth/refresh`
  pour porter le nouveau rôle). Un conducteur est aussi passager.
- Publier un trajet exige `conducteurValide = true` : permis **et** carte grise validés manuellement par un admin.
- `/api/admin/**` exige `ADMIN`. Les rôles sont vérifiés à chaque requête (claim `roles` du JWT) et l'appartenance
  des ressources (mon trajet, ma réservation) est vérifiée dans les services.

## Principaux endpoints

| Méthode | Chemin | Accès |
|---|---|---|
| POST | `/api/auth/inscription`, `/otp/verifier`, `/otp/renvoyer`, `/connexion`, `/google`, `/refresh`, `/deconnexion` | public |
| POST | `/api/auth/mot-de-passe/oublie`, `/mot-de-passe/reinitialiser` | public |
| GET/PUT | `/api/moi`, `/api/moi/preferences`, POST `/api/moi/photo`, PUT `/api/moi/fcm-token` | connecté |
| GET | `/api/utilisateurs/{id}` (profil public) | public |
| POST/GET/PUT/DELETE | `/api/moi/vehicules[/{id}]` | connecté |
| POST/GET | `/api/moi/documents` (multipart : `type`, `idVehicule`, `fichier`) ; GET `/api/documents/{id}/fichier` | connecté |
| GET | `/api/trajets/recherche?latDepart&lngDepart&latArrivee&lngArrivee&date[&places&rayonKm&prixMax&noteMin&femmesUniquement&heureMin&heureMax&conducteur]` | public |
| GET | `/api/trajets/{id}` | public |
| POST | `/api/trajets/estimation`, `/api/trajets` ; PUT `/api/trajets/{id}` ; POST `/api/trajets/{id}/annuler`, `/demarrer`, `/terminer` ; GET `/api/moi/trajets` | conducteur |
| POST | `/api/trajets/{id}/reservations` ; GET `/api/moi/reservations` ; POST `/api/reservations/{id}/annuler` ; GET `/api/reservations/{id}/embarquement` | passager |
| GET | `/api/trajets/{id}/reservations` ; POST `/api/reservations/{id}/accepter`, `/refuser` ; POST `/api/trajets/{id}/embarquement` | conducteur |
| GET/POST | `/api/moi/notifications`, `/non-lues`, `/{id}/lue`, `/lues` | connecté |
| GET/POST/PUT | `/api/admin/statistiques`, `/documents`, `/documents/{id}/valider|refuser`, `/utilisateurs[/{id}/bloquer|bannir|reactiver]`, `/parametres-tarification[/{cle}]` | admin |

Les erreurs suivent le format ProblemDetail : `{"status":409,"detail":"Il ne reste que 1 place(s) sur ce trajet"}`
(+ `erreurs` par champ pour les validations).

## Règles métier implémentées

- **OTP** : 6 chiffres, 5 min, 5 essais, renvoi après 60 s, stocké haché (BCrypt).
- **Jetons** : accès JWT 30 min ; refresh opaque 30 jours, haché, rotation à chaque usage, réutilisation détectée → toutes les sessions coupées.
- **Trajet** : départ ≥ 30 min après publication, flexibilité 15–30 min, places ≤ places du véhicule − 1, « femmes uniquement » réservé aux conductrices (et aux passagères).
- **Prix** : `(carburant + usure + péages) / (places proposées + 1)`, arrondi à 50 FCFA, plancher 500 FCFA ; le conducteur choisit dans ±10 %.
  Coefficients modifiables par l'admin (`parametre_tarification`) sans redéploiement.
- **Réservation** : mode automatique (acceptée tout de suite) ou manuel ; verrou pessimiste contre la sur-réservation ;
  annulation possible jusqu'au départ (places remises en vente) ; une seule réservation active par passager et par trajet.
- **Embarquement** : PIN 6 chiffres unique par trajet + jeton QR (`covoitia:embarquement:<token>`) ; la validation par le conducteur
  confirme la prise en charge et marque le paiement espèces comme encaissé.
- **Fin de trajet** : passagers embarqués → `TERMINEE`, non embarqués → `ANNULEE`, demandes en attente → `REFUSEE`.
