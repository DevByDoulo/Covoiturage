"""
Facteur météo appliqué à la consommation, à partir des prévisions horaires Open-Meteo
(https://open-meteo.com, gratuit, sans clé).

    facteur = 1 + climatisation + pluie + vent     (borné à FACTEUR_MAX)

- climatisation : +0,8 % par degré au-delà de 26 °C (plafond +12 %) — la clim tourne en continu par forte chaleur ;
- pluie         : +3 % dès 0,5 mm/h, +7 % au-delà de 4 mm/h (chaussée mouillée, vitesse irrégulière) ;
- vent          : +3 % au-delà de 35 km/h (résistance de l'air).
Hors de l'horizon des prévisions (16 jours), en cas d'erreur ou si Open-Meteo ne répond pas en 1,5 s,
le facteur vaut 1 (source INDISPONIBLE). Cette attente reste inférieure à celle du backend (2 s,
app.ia.delai) : une météo lente ne fait pas perdre la consommation prédite.
"""

import logging
import time
from dataclasses import dataclass
from datetime import datetime

import httpx

URL_OPEN_METEO = "https://api.open-meteo.com/v1/forecast"
FACTEUR_MAX = 1.25
DUREE_CACHE_S = 30 * 60
# Attente maximale d'Open-Meteo : 0,5 s pour se connecter + 1 s pour la réponse = 1,5 s.
# (Un délai httpx unique s'appliquerait à chaque étape et pourrait atteindre le double.)
DELAI_METEO = httpx.Timeout(1.0, connect=0.5)

log = logging.getLogger(__name__)


@dataclass(frozen=True)
class Meteo:
    facteur: float
    source: str  # OPEN_METEO ou INDISPONIBLE
    temperature_c: float | None = None
    precipitation_mm: float | None = None
    vent_kmh: float | None = None


INDISPONIBLE = Meteo(facteur=1.0, source="INDISPONIBLE")


def facteur(temperature_c: float | None, precipitation_mm: float | None, vent_kmh: float | None) -> float:
    total = 1.0
    if temperature_c is not None and temperature_c > 26:
        total += min(0.12, (temperature_c - 26) * 0.008)
    if precipitation_mm is not None:
        if precipitation_mm > 4:
            total += 0.07
        elif precipitation_mm >= 0.5:
            total += 0.03
    if vent_kmh is not None and vent_kmh > 35:
        total += 0.03
    return round(min(FACTEUR_MAX, total), 3)


class ServiceMeteo:
    def __init__(self, client: httpx.Client | None = None):
        self._client = client or httpx.Client(timeout=DELAI_METEO)
        self._cache: dict[tuple, tuple[float, Meteo]] = {}

    def meteo(self, latitude: float, longitude: float, depart: datetime) -> Meteo:
        # Prévisions à ~10 km près et à l'heure près : suffisant pour un trajet et réutilisable en cache.
        cle = (round(latitude, 1), round(longitude, 1), depart.date().isoformat(), depart.hour)
        en_cache = self._cache.get(cle)
        if en_cache and time.monotonic() - en_cache[0] < DUREE_CACHE_S:
            return en_cache[1]
        resultat, durable = self._interroger(*cle)
        # Une panne ou un délai dépassé est passager : on réessaiera à la demande suivante.
        if durable:
            self._cache[cle] = (time.monotonic(), resultat)
        return resultat

    def _interroger(self, latitude: float, longitude: float, jour: str, heure: int) -> tuple[Meteo, bool]:
        """Météo, et si le résultat peut être mis en cache (prévision obtenue ou date hors horizon)."""
        try:
            reponse = self._client.get(URL_OPEN_METEO, params={
                "latitude": latitude,
                "longitude": longitude,
                "hourly": "temperature_2m,precipitation,wind_speed_10m",
                "start_date": jour,
                "end_date": jour,
                "timezone": "Africa/Dakar",
            })
            if reponse.status_code == 400:  # date hors de l'horizon des prévisions
                return INDISPONIBLE, True
            reponse.raise_for_status()
            horaire = reponse.json()["hourly"]
            temperature = horaire["temperature_2m"][heure]
            precipitation = horaire["precipitation"][heure]
            vent = horaire["wind_speed_10m"][heure]
        except (httpx.HTTPError, KeyError, IndexError, ValueError) as e:
            log.warning("Météo indisponible (%s, %s, %s %sh) : %r", latitude, longitude, jour, heure, e)
            return INDISPONIBLE, False
        if temperature is None:
            return INDISPONIBLE, True
        return Meteo(facteur=facteur(temperature, precipitation, vent), source="OPEN_METEO",
                     temperature_c=temperature, precipitation_mm=precipitation, vent_kmh=vent), True
