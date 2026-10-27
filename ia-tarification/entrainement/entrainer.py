"""
Entraîne le modèle de consommation sur les données officielles ADEME « Car Labelling ».

    python -m entrainement.entrainer            # télécharge les données (si absentes) puis entraîne
    python -m entrainement.entrainer --rafraichir   # force un nouveau téléchargement

Entrées du modèle : marque, énergie, puissance fiscale.
Cible : consommation mixte homologuée (WLTP), en L/100 km (kWh/100 km pour les électriques).
Produit : modele/consommation.json (XGBoost) et modele/metadonnees.json (catégories, métriques).
"""

import argparse
import json
from datetime import date
from pathlib import Path

import numpy as np
import pandas as pd
import xgboost as xgb
from sklearn.model_selection import KFold, train_test_split

from app.donnees import ENERGIES, ENERGIES_ADEME, normaliser_marque

URL_ADEME = (
    "https://data.ademe.fr/data-fair/api/v1/datasets/ademe-car-labelling/lines?size=10000&format=csv"
)
RACINE = Path(__file__).resolve().parent.parent
FICHIER_DONNEES = RACINE / "donnees" / "ademe-car-labelling.csv"
DOSSIER_MODELE = RACINE / "modele"

PARAMETRES = dict(
    n_estimators=400,
    max_depth=5,
    learning_rate=0.05,
    subsample=0.9,
    colsample_bytree=0.9,
    min_child_weight=2,
    enable_categorical=True,
    tree_method="hist",
    random_state=42,
)


def telecharger(rafraichir: bool) -> pd.DataFrame:
    if rafraichir or not FICHIER_DONNEES.exists():
        FICHIER_DONNEES.parent.mkdir(exist_ok=True)
        print(f"Téléchargement des données ADEME -> {FICHIER_DONNEES}")
        pd.read_csv(URL_ADEME).to_csv(FICHIER_DONNEES, index=False)
    return pd.read_csv(FICHIER_DONNEES)


def preparer(brut: pd.DataFrame) -> pd.DataFrame:
    """Une ligne par véhicule : marque, energie, puissance_fiscale, consommation (cible)."""
    df = pd.DataFrame({
        "marque": brut["Marque"].map(normaliser_marque),
        "energie": brut["Energie"].map(ENERGIES_ADEME),
        "puissance_fiscale": pd.to_numeric(brut["Puissance fiscale"], errors="coerce"),
    })
    thermique = (brut["Conso vitesse mixte Min"] + brut["Conso vitesse mixte Max"]) / 2
    electrique = (brut["Conso elec Min"] + brut["Conso elec Max"]) / 2 / 10  # Wh/km -> kWh/100 km
    df["consommation"] = np.where(df["energie"] == "ELECTRIQUE", electrique, thermique)

    df = df.dropna()
    # Valeurs aberrantes (erreurs de saisie) : hors de plages physiquement plausibles.
    df = df[(df["consommation"] > 1) & (df["consommation"] < 40) & (df["puissance_fiscale"].between(1, 80))]
    return df.reset_index(drop=True)


def avec_marque_inconnue(df: pd.DataFrame) -> pd.DataFrame:
    """
    Ajoute une copie des lignes sans la marque : le modèle apprend à prédire à partir de l'énergie et de la
    puissance seules, ce qui sert pour les marques absentes des données ADEME (fréquentes au Sénégal).
    """
    return pd.concat([df, df.assign(marque=None)], ignore_index=True)


def ajuster(df: pd.DataFrame, marques: list[str]) -> xgb.XGBRegressor:
    complet = avec_marque_inconnue(df)
    modele = xgb.XGBRegressor(**PARAMETRES)
    modele.fit(en_entrees(complet, marques), complet["consommation"])
    return modele


def en_entrees(df: pd.DataFrame, marques: list[str]) -> pd.DataFrame:
    return pd.DataFrame({
        "marque": pd.Categorical(df["marque"], categories=marques),
        "energie": pd.Categorical(df["energie"], categories=list(ENERGIES)),
        "puissance_fiscale": df["puissance_fiscale"].astype(float),
    })


def mae_validation_croisee(df: pd.DataFrame, marques: list[str]) -> float:
    erreurs = []
    for entrainement, test in KFold(n_splits=5, shuffle=True, random_state=42).split(df):
        modele = ajuster(df.iloc[entrainement], marques)
        prediction = modele.predict(en_entrees(df.iloc[test], marques))
        erreurs.append(np.mean(np.abs(prediction - df["consommation"].iloc[test])))
    return float(np.mean(erreurs))


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--rafraichir", action="store_true", help="retélécharger les données ADEME")
    args = parser.parse_args()

    df = preparer(telecharger(args.rafraichir))
    marques = sorted(df["marque"].unique())
    print(f"{len(df)} véhicules exploitables, {len(marques)} marques")
    print(df.groupby("energie")["consommation"].describe()[["count", "mean", "min", "max"]].round(2))

    # Référence naïve : moyenne par énergie. Le modèle doit faire nettement mieux.
    train, test = train_test_split(df, test_size=0.2, random_state=42)
    naif = test["energie"].map(train.groupby("energie")["consommation"].mean())
    mae_naif = float(np.mean(np.abs(naif - test["consommation"])))

    modele = ajuster(train, marques)
    mae_test = float(np.mean(np.abs(modele.predict(en_entrees(test, marques)) - test["consommation"])))
    sans_marque = test.assign(marque=None)
    mae_sans_marque = float(np.mean(np.abs(modele.predict(en_entrees(sans_marque, marques)) - test["consommation"])))
    mae_cv = mae_validation_croisee(df, marques)
    print(f"MAE référence (moyenne par énergie) : {mae_naif:.3f}")
    print(f"MAE XGBoost (test 20 %)             : {mae_test:.3f}")
    print(f"MAE XGBoost, marque inconnue        : {mae_sans_marque:.3f}")
    print(f"MAE XGBoost (validation croisée x5) : {mae_cv:.3f}")

    # Modèle final entraîné sur toutes les données.
    final = ajuster(df, marques)
    DOSSIER_MODELE.mkdir(exist_ok=True)
    final.save_model(DOSSIER_MODELE / "consommation.json")
    version = f"xgb-ademe-{date.today().isoformat()}"
    metadonnees = {
        "version": version,
        "source": URL_ADEME,
        "nombreVehicules": len(df),
        "marques": marques,
        "energies": list(ENERGIES),
        "unites": {e: ("kWh/100km" if e == "ELECTRIQUE" else "L/100km") for e in ENERGIES},
        "metriques": {"maeReference": round(mae_naif, 3), "maeTest": round(mae_test, 3),
                      "maeMarqueInconnue": round(mae_sans_marque, 3), "maeValidationCroisee": round(mae_cv, 3)},
        "parametres": {k: v for k, v in PARAMETRES.items() if k != "enable_categorical"},
    }
    (DOSSIER_MODELE / "metadonnees.json").write_text(json.dumps(metadonnees, indent=2, ensure_ascii=False),
                                                     encoding="utf-8")
    print(f"Modèle {version} enregistré dans {DOSSIER_MODELE}")


if __name__ == "__main__":
    main()
