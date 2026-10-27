"""Normalisation partagée entre l'entraînement et le service (marques, énergies)."""

import re
import unicodedata

# Énergies de l'API, alignées sur l'enum TypeEnergie du backend Spring Boot.
ENERGIES = ("ESSENCE", "DIESEL", "HYBRIDE", "ELECTRIQUE")

# Libellés ADEME -> énergie de l'API. Les hybrides rechargeables (« HR ») sont écartés :
# leur consommation homologuée suppose une batterie rechargée, ce qui fausse le carburant réel.
ENERGIES_ADEME = {
    "ESSENCE": "ESSENCE",
    "SUPERETHANOL": "ESSENCE",
    "ESS+G.P.L.": "ESSENCE",
    "GAZOLE": "DIESEL",
    "ESS+ELEC HNR": "HYBRIDE",
    "GAZ+ELEC HNR": "HYBRIDE",
    "ELECTRIC": "ELECTRIQUE",
}

# Variantes courantes saisies par les conducteurs -> forme normalisée des libellés ADEME.
ALIAS_MARQUES = {
    "MERCEDESBENZ": "MERCEDES",
    "LAMBORGHINI": "LAMBORGHIN",
    "ROLLSROYCE": "ROLLSROYC",
    "VW": "VOLKSWAGEN",
    "LANDROVERRANGEROVER": "LANDROVER",
}


def normaliser_marque(marque: str | None) -> str | None:
    """« B.M.W. » -> « BMW », « Citroën » -> « CITROEN », « Mercedes-Benz » -> « MERCEDES »."""
    if not marque:
        return None
    sans_accents = unicodedata.normalize("NFKD", marque).encode("ascii", "ignore").decode()
    cle = re.sub(r"[^A-Z0-9]", "", sans_accents.upper())
    return ALIAS_MARQUES.get(cle, cle) or None
