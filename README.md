# YOBALEMAsn — Plateforme de covoiturage avec estimation tarifaire par IA

Projet de fin d'études : application web et mobile de covoiturage (Sénégal) avec un prix par passager
calculé à partir du véhicule réel, du trajet réel et des conditions du jour.

## Organisation du dépôt

| Dossier | Contenu | Technologies |
|---|---|---|
| [`backend/Convoiturage`](backend/Convoiturage) | API REST (aujourd'hui : inscription, connexion, profil) | Spring Boot 4, Java 21, PostgreSQL 16 + PostGIS, Flyway |
| [`frontend`](frontend) | Application web passager, conducteur et back-office (aujourd'hui : écrans d'authentification) | Angular 21 |
| [`ia-tarification`](ia-tarification) | Service de prix IA : consommation prédite (données ADEME) et facteur météo | Python, FastAPI, XGBoost, Open-Meteo |
| [`docs`](docs/README.md) | Maquettes des écrans et diagrammes UML (PowerAMC) | PNG, `.moo` |

Le dépôt repart de l'authentification ; chaque fonctionnalité est reconstruite par son responsable (voir `CLAUDE.md`).
L'ancienne version complète du lot 1 reste disponible sous l'étiquette Git `archive/lot1-complet`.
À venir : application mobile (Flutter).

## Démarrage rapide

1. **Base de données** — PostgreSQL 16 + PostGIS installés sur le poste, puis une fois :
   `psql -U postgres -p <port> -f backend/Convoiturage/db/init-local.sql`
   et copie de `backend/Convoiturage/application-local.example.yml` en `application-local.yml` (port du poste).
2. **Backend** — dans `backend/Convoiturage` : `./mvnw spring-boot:run -Dspring-boot.run.profiles=dev` → http://localhost:8080
3. **Service IA** (facultatif ; éteint, le prix est calculé par la formule seule) — dans `ia-tarification` :
   `pip install -r requirements.txt` puis `uvicorn app.main:app --port 8000`
4. **Frontend** — dans `frontend` : `npm install` puis `npm start` → http://localhost:4200

Détails dans le README de chaque dossier.

## Tests

- Backend : `./mvnw test` (dont un parcours d'authentification complet sur la base locale `covoiturage_test`)
- Frontend : `npm test`
- Service IA : `python -m pytest` (dans `ia-tarification`)
