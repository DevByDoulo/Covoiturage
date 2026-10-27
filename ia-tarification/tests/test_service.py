"""Tests du service : normalisation, modèle entraîné, facteur météo et API (Open-Meteo simulé)."""

from datetime import datetime

import httpx
import pytest
from fastapi.testclient import TestClient

from app import meteo as module_meteo
from app.donnees import normaliser_marque
from app.main import app
from app.meteo import ServiceMeteo
from app.modele import ModeleConsommation


def faux_open_meteo(temperature=34.0, precipitation=0.0, vent=12.0, statut=200) -> httpx.Client:
    def repondre(requete: httpx.Request) -> httpx.Response:
        if statut != 200:
            return httpx.Response(statut, json={"error": True, "reason": "hors horizon"})
        return httpx.Response(200, json={"hourly": {
            "temperature_2m": [temperature] * 24,
            "precipitation": [precipitation] * 24,
            "wind_speed_10m": [vent] * 24,
        }})
    return httpx.Client(transport=httpx.MockTransport(repondre))


@pytest.fixture
def client():
    with TestClient(app) as c:
        app.state.meteo = ServiceMeteo(client=faux_open_meteo())
        yield c


DEMANDE = {
    "marque": "Toyota", "typeEnergie": "ESSENCE", "puissanceFiscale": 7, "annee": 2020,
    "latitude": 14.6928, "longitude": -17.4467, "dateHeureDepart": "2026-11-02T08:30:00",
}


# ------------------------------------------------------------------ normalisation

@pytest.mark.parametrize("brute, attendue", [
    ("B.M.W.", "BMW"), ("bmw", "BMW"), ("Citroën", "CITROEN"), ("Mercedes-Benz", "MERCEDES"),
    ("Land Rover", "LANDROVER"), ("", None), (None, None),
])
def test_normalise_les_marques(brute, attendue):
    assert normaliser_marque(brute) == attendue


# ------------------------------------------------------------------ modèle

def test_le_modele_predit_des_consommations_plausibles():
    modele = ModeleConsommation()
    essence = modele.predire("Peugeot", "ESSENCE", 6, None)
    diesel = modele.predire("Peugeot", "DIESEL", 6, None)
    electrique = modele.predire("Renault", "ELECTRIQUE", 4, None)

    assert 3 < essence.consommation < 12 and essence.unite == "L/100km"
    assert 3 < diesel.consommation < 12
    assert 10 < electrique.consommation < 30 and electrique.unite == "kWh/100km"
    assert essence.marque_connue


def test_plus_de_puissance_consomme_plus():
    modele = ModeleConsommation()
    assert modele.predire("Renault", "ESSENCE", 12, None).consommation > \
        modele.predire("Renault", "ESSENCE", 4, None).consommation


def test_une_marque_inconnue_reste_estimee():
    prediction = ModeleConsommation().predire("Marque Imaginaire", "DIESEL", 8, None)
    assert not prediction.marque_connue
    assert 3 < prediction.consommation < 15


def test_les_vehicules_anciens_consomment_plus():
    assert ModeleConsommation.facteur_age(datetime.now().year - 5) == 1.0
    assert ModeleConsommation.facteur_age(datetime.now().year - 15) == 1.05
    assert ModeleConsommation.facteur_age(1980) == 1.2


# ------------------------------------------------------------------ météo

def test_facteur_meteo():
    assert module_meteo.facteur(24, 0, 10) == 1.0
    assert module_meteo.facteur(36, 0, 10) == 1.08       # clim : 10 °C au-delà de 26 × 0,8 %
    assert module_meteo.facteur(45, 0, 10) == 1.12       # plafond clim
    assert module_meteo.facteur(24, 2, 10) == 1.03       # pluie modérée
    assert module_meteo.facteur(24, 10, 50) == 1.10      # forte pluie + vent
    assert module_meteo.facteur(None, None, None) == 1.0


def test_meteo_hors_horizon_ou_en_erreur():
    depart = datetime(2027, 6, 1, 9)
    assert ServiceMeteo(client=faux_open_meteo(statut=400)).meteo(14.7, -17.4, depart).source == "INDISPONIBLE"
    assert ServiceMeteo(client=faux_open_meteo(statut=503)).meteo(14.7, -17.4, depart).facteur == 1.0


def test_meteo_mise_en_cache():
    appels = []

    def repondre(requete):
        appels.append(requete)
        return httpx.Response(200, json={"hourly": {"temperature_2m": [30.0] * 24, "precipitation": [0] * 24,
                                                    "wind_speed_10m": [5] * 24}})
    service = ServiceMeteo(client=httpx.Client(transport=httpx.MockTransport(repondre)))
    depart = datetime(2026, 11, 2, 8, 30)
    service.meteo(14.6928, -17.4467, depart)
    service.meteo(14.6931, -17.4470, depart)  # même zone, même heure
    assert len(appels) == 1


def test_attente_meteo_limitee_a_1_5_s():
    delai = module_meteo.DELAI_METEO
    assert delai.connect + delai.read == 1.5


def test_delai_depasse_sans_mise_en_cache():
    appels = []

    def repondre(requete):
        appels.append(requete)
        if len(appels) == 1:
            raise httpx.ReadTimeout("Open-Meteo trop lent", request=requete)
        return httpx.Response(200, json={"hourly": {"temperature_2m": [36.0] * 24, "precipitation": [0] * 24,
                                                    "wind_speed_10m": [5] * 24}})
    service = ServiceMeteo(client=httpx.Client(transport=httpx.MockTransport(repondre)))
    depart = datetime(2026, 11, 2, 8, 30)

    assert service.meteo(14.6928, -17.4467, depart).source == "INDISPONIBLE"
    # Panne passagère : la demande suivante réinterroge Open-Meteo au lieu de servir l'échec en cache.
    assert service.meteo(14.6928, -17.4467, depart).facteur == 1.08
    assert len(appels) == 2


# ------------------------------------------------------------------ API

def test_sante(client):
    corps = client.get("/sante").json()
    assert corps["statut"] == "UP"
    assert corps["versionModele"].startswith("xgb-ademe-")


def test_estimation(client):
    reponse = client.post("/v1/estimations", json=DEMANDE)
    assert reponse.status_code == 200
    corps = reponse.json()
    assert corps["unite"] == "L/100km"
    assert corps["marqueConnue"] is True
    assert corps["meteo"] == {"facteur": 1.064, "source": "OPEN_METEO", "temperatureC": 34.0,
                              "precipitationMm": 0.0, "ventKmh": 12.0}
    assert corps["versionModele"].startswith("xgb-ademe-")


def test_estimation_sans_marque(client):
    demande = {**DEMANDE, "marque": None, "typeEnergie": "DIESEL"}
    assert client.post("/v1/estimations", json=demande).json()["marqueConnue"] is False


def test_rejette_une_demande_invalide(client):
    assert client.post("/v1/estimations", json={**DEMANDE, "typeEnergie": "CHARBON"}).status_code == 422
    assert client.post("/v1/estimations", json={**DEMANDE, "puissanceFiscale": 0}).status_code == 422
