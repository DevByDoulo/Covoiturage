"""
Service de tarification IA de YOBALEMAsn.

    uvicorn app.main:app --port 8000

POST /v1/estimations : consommation prédite (XGBoost, données ADEME) et facteur météo (Open-Meteo).
Le prix en FCFA reste calculé par le backend Spring Boot (MoteurFormule, coefficients de l'administrateur).
"""

from contextlib import asynccontextmanager
from datetime import datetime
from typing import Literal

from fastapi import FastAPI, HTTPException
from pydantic import BaseModel, ConfigDict, Field
from pydantic.alias_generators import to_camel

from app.meteo import ServiceMeteo
from app.modele import ModeleConsommation


class Schema(BaseModel):
    """JSON en camelCase, comme le reste de l'API (Spring Boot)."""
    model_config = ConfigDict(alias_generator=to_camel, populate_by_name=True)


class DemandeEstimation(Schema):
    marque: str | None = Field(default=None, max_length=60, examples=["Toyota"])
    type_energie: Literal["ESSENCE", "DIESEL", "HYBRIDE", "ELECTRIQUE"]
    puissance_fiscale: int = Field(ge=1, le=80, examples=[7])
    annee: int | None = Field(default=None, ge=1950, le=2100, examples=[2015])
    latitude: float = Field(ge=-90, le=90, examples=[14.6928])
    longitude: float = Field(ge=-180, le=180, examples=[-17.4467])
    date_heure_depart: datetime = Field(examples=["2026-11-02T08:30:00"])


class MeteoReponse(Schema):
    facteur: float
    source: Literal["OPEN_METEO", "INDISPONIBLE"]
    temperature_c: float | None
    precipitation_mm: float | None
    vent_kmh: float | None


class EstimationReponse(Schema):
    consommation: float = Field(description="Consommation prédite (hors météo), L/100 km ou kWh/100 km")
    unite: str
    marque_connue: bool = Field(description="False si la marque est absente des données ADEME")
    facteur_age: float
    meteo: MeteoReponse
    version_modele: str


@asynccontextmanager
async def cycle_de_vie(app: FastAPI):
    app.state.modele = ModeleConsommation()
    app.state.meteo = ServiceMeteo()
    yield


app = FastAPI(title="YOBALEMAsn — tarification IA", version="1.0.0", lifespan=cycle_de_vie)


@app.get("/sante")
def sante() -> dict:
    modele: ModeleConsommation = app.state.modele
    return {"statut": "UP", "versionModele": modele.version, "metriques": modele.metadonnees["metriques"]}


@app.post("/v1/estimations", response_model=EstimationReponse, response_model_by_alias=True)
def estimer(demande: DemandeEstimation) -> EstimationReponse:
    modele: ModeleConsommation = app.state.modele
    service_meteo: ServiceMeteo = app.state.meteo
    try:
        prediction = modele.predire(demande.marque, demande.type_energie, demande.puissance_fiscale, demande.annee)
    except ValueError as e:
        raise HTTPException(status_code=422, detail=str(e)) from e
    meteo = service_meteo.meteo(demande.latitude, demande.longitude, demande.date_heure_depart)
    return EstimationReponse(
        consommation=prediction.consommation,
        unite=prediction.unite,
        marque_connue=prediction.marque_connue,
        facteur_age=prediction.facteur_age,
        meteo=MeteoReponse(facteur=meteo.facteur, source=meteo.source, temperature_c=meteo.temperature_c,
                           precipitation_mm=meteo.precipitation_mm, vent_kmh=meteo.vent_kmh),
        version_modele=modele.version,
    )
