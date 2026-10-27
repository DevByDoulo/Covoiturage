# YOBALEMAsn — Backend (Spring Boot 4, Java 21)

API REST de la plateforme de covoiturage. Aujourd'hui : inscription avec code (email ou SMS), connexion
(email/téléphone, Google), jetons JWT + refresh, mot de passe oublié, profil, préférences et photo, compte admin.
Les autres modules (véhicules, trajets, prix, réservations, notifications, administration) sont reconstruits par
leurs responsables ; l'ancienne version reste sous l'étiquette Git `archive/lot1-complet`.

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

- Le schéma est créé par **Flyway** (`src/main/resources/db/migration`). Toute évolution = nouveau fichier daté
  `V2026_10_27_1430__....sql`. La migration V1 crée déjà toutes les tables du diagramme de classes (trajets, véhicules…) :
  elles restent en base, prêtes à être reprises par les modules à venir.
- Profil `dev` : les **SMS (OTP)** sont écrits dans la console ; un compte admin est créé
  au démarrage (identifiants dans `application-dev.yml`).
- `-Dspring-boot.run.profiles=dev` force le profil même si une variable `SPRING_PROFILES_ACTIVE` d'un autre projet existe sur le poste.
- Docker reste possible en option : `docker compose up -d` lance PostgreSQL + PostGIS sur le port 5432.

### Variables d'environnement (prod)

| Variable | Rôle |
|---|---|
| `COVOITIA_DB_URL`, `COVOITIA_DB_USERNAME`, `COVOITIA_DB_PASSWORD` | Base PostgreSQL/PostGIS |
| `COVOITIA_JWT_SECRET` | Clé HMAC Base64 ≥ 32 octets (`openssl rand -base64 48`) |
| `CORS_ALLOWED_ORIGINS` | Origines autorisées, séparées par des virgules |
| `GOOGLE_CLIENT_ID` | Vérification du « Se connecter avec Google » |
| `ADMIN_EMAIL`, `ADMIN_PASSWORD`, `ADMIN_TELEPHONE` | Premier administrateur |

## Tests

```bash
./mvnw test
```
`ParcoursCompletTest` rejoue les parcours d'authentification (inscription et code, connexion, profil, refresh et
déconnexion, mot de passe oublié, quotas, blocage) sur la base locale `covoiturage_test`, vidée automatiquement au début
de chaque exécution (PostgreSQL doit tourner, voir ci-dessus).

## Architecture (monolithe modulaire)

```
sn.isep.Convoiturage
├── common        sécurité JWT/CORS, erreurs (ProblemDetail), téléphones, stockage fichiers
├── auth          inscription, codes OTP (email/SMS), connexion (email/téléphone, Google), refresh tokens, mot de passe oublié
├── utilisateur   profil, préférences, photo, jeton FCM
└── admin         création du premier administrateur au démarrage
```
Un nouveau module = un nouveau package au même niveau (`vehicule`, `trajet`, `notification`…). Pas de dépendance
circulaire entre modules : passer par des événements Spring.

## Rôles

- Inscription → `PASSAGER`. Rôles `CONDUCTEUR` et `ADMIN` prévus ; `/api/admin/**` exige `ADMIN`.
- Les rôles sont vérifiés à chaque requête (claim `roles` du JWT) : après un changement de rôle, le jeton doit être
  **rafraîchi** via `/api/auth/refresh`.

## Principaux endpoints

| Méthode | Chemin | Accès |
|---|---|---|
| POST | `/api/auth/inscription`, `/otp/verifier`, `/otp/renvoyer`, `/connexion`, `/google`, `/refresh`, `/deconnexion` | public |
| POST | `/api/auth/mot-de-passe/oublie` → `/mot-de-passe/verifier-code` (renvoie un `jeton` valable 10 min) → `/mot-de-passe/reinitialiser` (`jeton` + `nouveauMotDePasse`) | public |
| GET/PUT | `/api/moi`, `/api/moi/preferences`, POST `/api/moi/photo`, PUT `/api/moi/fcm-token` | connecté |
| GET/POST/DELETE | `/api/moi/contacts-urgence[/{id}]` (3 au plus) | connecté |
| PUT | `/api/moi/mot-de-passe` (`motDePasseActuel`, `nouveauMotDePasse` ; renvoie de nouveaux jetons) ; POST `/api/moi/desactivation` (`motDePasse`) | connecté |
| GET | `/api/utilisateurs/{id}` (profil public) | public |

Les erreurs suivent le format ProblemDetail : `{"status":409,"detail":"Cet email est déjà utilisé","champ":"email"}`
(+ `erreurs` par champ pour les validations).

## Règles métier implémentées

- **OTP** : 6 chiffres, 5 min, 5 essais, renvoi après 60 s, au plus 5 codes par heure et 10 par jour pour un
  même compte et un même usage (`app.otp.max-codes-par-*`), stocké haché (BCrypt).
- **Mot de passe oublié** : réponses identiques que le compte existe ou non (un code fictif, jamais envoyé, est
  enregistré sous une clé `?…` pour les comptes inconnus) ; au plus 20 demandes de code et 30 vérifications
  par heure et par IP (`LimiteurParIp`, derrière un proxy : `server.forward-headers-strategy: framework`) ;
  après le changement, toutes les sessions sont fermées et le titulaire est prévenu par email (ou SMS).
- **Compte** : changer le mot de passe exige l'ancien (sauf compte créé avec Google), ferme les autres sessions et
  prévient le titulaire ; la désactivation (mot de passe exigé) ferme toutes les sessions, et le compte est réactivé
  à la connexion suivante. Contacts d'urgence : 3 au plus, numéro normalisé, ni le sien ni un doublon.
- **Jetons** : accès JWT 30 min ; refresh opaque 30 jours, haché, rotation à chaque usage, réutilisation détectée → toutes les sessions coupées.
