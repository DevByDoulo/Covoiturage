"""Chargement du modèle XGBoost entraîné (entrainement/entrainer.py) et prédiction de consommation."""

import json
from dataclasses import dataclass
from datetime import date
from pathlib import Path

import pandas as pd
import xgboost as xgb

from app.donnees import ENERGIES, normaliser_marque

DOSSIER_MODELE = Path(__file__).resolve().parent.parent / "modele"

# Les véhicules vieillissent : +1 %/an au-delà de 10 ans, plafonné à +20 % (même règle que MoteurFormule).
AGE_SANS_USURE = 10
USURE_PAR_AN = 0.01
USURE_MAX = 0.20


@dataclass(frozen=True)
class Prediction:
    consommation: float
    unite: str
    marque_connue: bool
    facteur_age: float


class ModeleConsommation:
    def __init__(self, dossier: Path = DOSSIER_MODELE):
        self.metadonnees = json.loads((dossier / "metadonnees.json").read_text(encoding="utf-8"))
        self.version: str = self.metadonnees["version"]
        self._marques: list[str] = self.metadonnees["marques"]
        self._booster = xgb.Booster()
        self._booster.load_model(dossier / "consommation.json")

    def predire(self, marque: str | None, energie: str, puissance_fiscale: int, annee: int | None) -> Prediction:
        if energie not in ENERGIES:
            raise ValueError(f"Énergie inconnue : {energie}")
        cle = normaliser_marque(marque)
        connue = cle in self._marques
        entrees = pd.DataFrame({
            # Marque absente des données ADEME : valeur manquante, XGBoost suit alors la branche par défaut.
            "marque": pd.Categorical([cle if connue else None], categories=self._marques),
            "energie": pd.Categorical([energie], categories=list(ENERGIES)),
            "puissance_fiscale": [float(puissance_fiscale)],
        })
        brute = float(self._booster.predict(xgb.DMatrix(entrees, enable_categorical=True))[0])
        facteur_age = self.facteur_age(annee)
        return Prediction(
            consommation=round(brute * facteur_age, 2),
            unite=self.metadonnees["unites"][energie],
            marque_connue=connue,
            facteur_age=facteur_age,
        )

    @staticmethod
    def facteur_age(annee: int | None) -> float:
        if annee is None:
            return 1.0
        age = max(0, date.today().year - annee)
        return round(1 + min(USURE_MAX, max(0, age - AGE_SANS_USURE) * USURE_PAR_AN), 3)
