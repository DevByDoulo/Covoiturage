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
| `GOOGLE_MAPS_API_KEY` | Itinéraires Google Routes (sinon distance à vol d'oiseau × 1,25) |
| `IA_TARIFICATION_URL`, `IA_TARIFICATION_DELAI` | Service `ia-tarification` (vide : prix par la formule seule ; délai 2 s) |
| `WAVE_API_KEY`, `WAVE_SECRET_WEBHOOK` | Wave Business (vides : Wave non proposé) |
| `PAIEMENT_URL_RETOUR` | Adresse **HTTPS** du site, où Wave renvoie le passager après paiement |

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
├── utilisateur   profil, préférences, photo, contacts d'urgence, jeton FCM
├── vehicule      véhicules (photo), documents : permis, pièce d'identité, carte grise par véhicule
├── notification  notifications (application, push FCM, email/SMS si importantes), rappel avant le départ
└── admin         back-office : statistiques, validation des documents, utilisateurs, blocage, journal des décisions
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
| POST/GET/PUT/DELETE | `/api/moi/vehicules[/{id}]` ; POST `/api/moi/vehicules/{id}/photo` | connecté |
| GET | `/api/moi/notifications?page&taille`, `/api/moi/notifications/non-lues` ; POST `/api/moi/notifications/{id}/lue`, `/lues` | connecté |
| POST, GET | `/api/moi/alertes` — créer (départ, arrivée, date, rayon, prix max) / lister ses alertes de recherche à venir ; DELETE `/api/moi/alertes/{id}` | passager |
| GET | `/api/admin/statistiques` ; `/api/admin/documents?type&recherche&plusAnciensDabord&page` (file de validation) ; `/api/admin/utilisateurs?recherche&statut&page` ; `/api/admin/utilisateurs/{id}` (fiche) | admin |
| POST | `/api/admin/documents/{id}/valider`, `/refuser` (`motif`) ; `/api/admin/utilisateurs/{id}/bloquer`, `/bannir` (`motif`), `/reactiver` | admin |
| POST/GET | `/api/moi/documents` (multipart : `type` = PERMIS_CONDUIRE, PIECE_IDENTITE ou CARTE_GRISE, `idVehicule` pour la carte grise, `fichier`) ; GET `/api/documents/{id}/fichier` (propriétaire ou admin) | connecté |
| GET | `/api/trajets/recherche?latDepart&lngDepart&latArrivee&lngArrivee&date[&places&rayonKm&prixMax&noteMin&femmesUniquement&heureMin&heureMax&conducteur]`, `/api/trajets/{id}` | public |
| POST | `/api/trajets/estimation`, `/api/trajets` ; PUT `/api/trajets/{id}` ; POST `/api/trajets/{id}/annuler`, `/demarrer`, `/terminer` ; GET `/api/moi/trajets` | conducteur |
| POST | `/api/trajets/{id}/reservations` (`nombrePlaces`, `moyenPaiement`) ; GET `/api/moi/reservations` ; POST `/api/reservations/{id}/annuler` ; GET `/api/reservations/{id}/embarquement` (PIN/QR) | passager |
| GET | `/api/trajets/{id}/reservations` ; POST `/api/reservations/{id}/accepter`, `/refuser` ; POST `/api/trajets/{id}/embarquement` (`code`) | conducteur |
| GET | `/api/paiements/moyens` ; POST `/api/reservations/{id}/paiement` (passager, renvoie `urlPaiement`) ; GET `/api/moi/paiements` ; GET `/api/paiements/{reference}/recu` | connecté |
| POST | `/api/paiements/webhooks/wave` (signé `Wave-Signature`) | public |

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
- **Véhicules** : déclarer un véhicule fait passer le compte en `CONDUCTEUR` (rafraîchir le jeton). Avant validation
  tout est modifiable ; après, seules la consommation et l'usure. Un véhicule retiré puis redéclaré est réactivé.
- **Documents** : JPEG, PNG ou PDF (type lu dans le fichier), 5 Mo ; un nouvel envoi remplace la pièce encore en attente
  du même emplacement. Conducteur validé = permis + pièce d'identité validés + au moins un véhicule actif dont la carte
  grise est validée (`VehiculeService.recalculerStatutConducteur`, à appeler après chaque décision de l'admin — module 07).
- **Notifications** : chaque événement (demande, acceptation, refus, annulation de réservation, trajet modifié ou
  annulé, embarquement, décision de l'admin) crée une notification avec un lien vers l'écran concerné ; les
  importantes (réservation confirmée, trajet annulé ou modifié, nouvelle demande, document, compte) partent aussi
  par email, ou par SMS sans email. Rappel 1 h avant le départ, une seule fois.
- **Administration** : refus d'un document, blocage et bannissement exigent un motif, communiqué à l'utilisateur
  (email, sinon SMS) et enregistré dans `action_admin` ; un admin ne peut agir ni sur lui-même ni sur un autre admin ;
  bloquer ou bannir ferme toutes les sessions. Une pièce déjà traitée ne peut plus l'être (409).
- **Trajets** : départ ≥ 30 min après publication, flexibilité 15–30 min, places ≤ places du véhicule − 1, conducteur
  validé ; « femmes uniquement » réservé aux conductrices. Recherche PostGIS : le tracé passe à moins de `rayonKm`
  du départ et de l'arrivée du passager, dans le bon sens.
- **Prix** (module 12) : `MoteurIA` (consommation prédite par `ia-tarification` + facteur météo) puis `MoteurFormule`
  (`(carburant + usure + péages) / (places + 1)`, arrondi à 50 FCFA, plancher 500, fourchette ±10 %) ; consommation
  déclarée > prédite > estimée ; repli sur la formule seule si l'IA ne répond pas en 2 s.
- **Réservations** (module 04) : paiement créé dès la demande avec le moyen choisi ; mode automatique ou manuel ;
  verrou pessimiste contre la sur-réservation ; une seule réservation active par passager et par trajet ; annulation
  jusqu'au départ (places remises en vente). Embarquement par PIN 6 chiffres ou QR : un paiement non réglé en ligne
  est alors encaissé en espèces par le conducteur. Événements `ReservationEvenements` pour les notifications (06).
- **Paiements** (module 04) : espèces ; **Wave** (API Checkout, webhook signé HMAC-SHA256, anti-rejeu 5 min,
  idempotent) ; Orange Money à brancher (`OrangeMoneyFournisseur`, API Sonatel non publique). **Aucune commission ;
  annulation avant le départ = remboursement intégral** (relancé toutes les 10 min si l'opérateur échoue ; un
  paiement arrivé après l'annulation est remboursé). Règles provisoires, à confirmer avec l'encadrant.
- **Jetons** : accès JWT 30 min ; refresh opaque 30 jours, haché, rotation à chaque usage, réutilisation détectée → toutes les sessions coupées.
