# CoVoitIA — Plateforme de covoiturage avec estimation tarifaire par IA

Projet de fin d'études : application web et mobile de covoiturage (Sénégal) avec un prix par passager
calculé à partir du véhicule réel, du trajet réel et des conditions du jour.

## Organisation du dépôt

| Dossier | Contenu | Technologies |
|---|---|---|
| [`backend/Convoiturage`](backend/Convoiturage) | API REST : comptes, véhicules, trajets, réservations, paiement, notifications, administration | Spring Boot 4, Java 21, PostgreSQL 16 + PostGIS, Flyway |
| [`frontend`](frontend) | Application web passager, conducteur et back-office | Angular 21 |

À venir : service de prix IA (FastAPI, XGBoost) et application mobile (Flutter).

## Démarrage rapide

1. **Base de données** — PostgreSQL 16 + PostGIS installés sur le poste, puis une fois :
   `psql -U postgres -p <port> -f backend/Convoiturage/db/init-local.sql`
   et copie de `backend/Convoiturage/application-local.example.yml` en `application-local.yml` (port du poste).
2. **Backend** — dans `backend/Convoiturage` : `./mvnw spring-boot:run -Dspring-boot.run.profiles=dev` → http://localhost:8080
3. **Frontend** — dans `frontend` : `npm install` puis `npm start` → http://localhost:4200

Détails dans le README de chaque dossier.

## Tests

- Backend : `./mvnw test` (dont un parcours complet sur la base locale `covoiturage_test`)
- Frontend : `npm test`
