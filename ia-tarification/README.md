# YOBALEMAsn — Service de tarification IA (FastAPI, XGBoost)

Microservice appelé par le backend Spring Boot (`MoteurIA`) pour affiner le prix d'un trajet :

- **consommation du véhicule** prédite par un modèle **XGBoost** entraîné sur les données officielles
  [ADEME Car Labelling](https://data.ademe.fr/datasets/ademe-car-labelling) (marque, énergie, puissance fiscale),
  corrigée selon l'âge du véhicule ;
- **facteur météo** au point et à l'heure de départ, d'après les prévisions [Open-Meteo](https://open-meteo.com)
  (chaleur → climatisation, pluie, vent).

Le prix en FCFA reste calculé par Spring Boot (`MoteurFormule`, coefficients de l'administrateur).
Si ce service est éteint, en erreur ou trop lent (2 s), le backend calcule le prix avec la formule seule.

```
Spring Boot                                   ia-tarification (ce dossier)
TrajetService.calculer()  ── POST /v1/estimations ──►  XGBoost (ADEME) → consommation
  MoteurIA                ◄── conso + météo ───────   Open-Meteo     → facteur météo
    └► MoteurFormule (FCFA, coefficients admin)
  erreur / délai dépassé → formule seule
```

## Démarrer

Python 3.12 ou plus récent.

```powershell
cd ia-tarification
python -m venv .venv
.venv\Scripts\activate
pip install -r requirements.txt
uvicorn app.main:app --port 8000
```

- Documentation interactive : http://localhost:8000/docs
- Santé et métriques du modèle : http://localhost:8000/sante

En profil `dev`, le backend appelle `http://localhost:8000` (variable `IA_TARIFICATION_URL` pour changer).

## API

`POST /v1/estimations`

```json
{
  "marque": "Toyota",
  "typeEnergie": "ESSENCE",
  "puissanceFiscale": 7,
  "annee": 2018,
  "latitude": 14.6928,
  "longitude": -17.4467,
  "dateHeureDepart": "2026-11-02T08:30:00"
}
```

Réponse :

```json
{
  "consommation": 6.09,
  "unite": "L/100km",
  "marqueConnue": true,
  "facteurAge": 1.0,
  "meteo": { "facteur": 1.064, "source": "OPEN_METEO", "temperatureC": 34.0, "precipitationMm": 0.0, "ventKmh": 12.0 },
  "versionModele": "xgb-ademe-2026-10-27"
}
```

- `typeEnergie` : `ESSENCE`, `DIESEL`, `HYBRIDE` ou `ELECTRIQUE` (consommation en kWh/100 km pour ce dernier).
- `marque` facultative ; une marque absente des données ADEME est estimée d'après l'énergie et la puissance.
- `annee` facultative : +1 %/an au-delà de 10 ans, plafonné à +20 %.
- Météo : `facteur = 1 + clim + pluie + vent`, borné à 1,25 — clim +0,8 %/°C au-delà de 26 °C (max +12 %),
  pluie +3 % (≥ 0,5 mm/h) ou +7 % (> 4 mm/h), vent +3 % (> 35 km/h). Au-delà de l'horizon des prévisions
  (16 jours), ou si Open-Meteo ne répond pas en **1,5 s** au plus (0,5 s de connexion + 1 s de réponse) :
  facteur 1, `source = INDISPONIBLE`. Ce délai reste sous celui du backend (2 s) pour que la consommation
  prédite arrive toujours. Les prévisions sont gardées 30 min en cache par zone (~10 km) et par heure ;
  les pannes passagères ne le sont pas.

## Modèle

Entraînement (télécharge les données ADEME dans `donnees/`, non versionné) :

```powershell
python -m entrainement.entrainer              # --rafraichir pour retélécharger les données
```

Le modèle produit (`modele/consommation.json`) et ses métadonnées (`modele/metadonnees.json` : version,
marques, métriques) sont versionnés : le service fonctionne sans réentraîner.

| Données | Valeur |
|---|---|
| Véhicules exploitables | 3 352 (30 marques ; hybrides rechargeables exclus) |
| Cible | consommation mixte homologuée WLTP (moyenne min/max) |
| Erreur moyenne (MAE), test 20 % | 0,36 L/100 km |
| MAE, validation croisée ×5 | 0,35 L/100 km |
| MAE, marque inconnue | 0,53 L/100 km |
| Référence naïve (moyenne par énergie) | 0,82 L/100 km |

Pour qu'il sache traiter les marques inconnues, le modèle est aussi entraîné sur une copie des données sans la marque.

## Tests

```powershell
python -m pytest
```

Open-Meteo est simulé dans les tests (aucun appel réseau).
