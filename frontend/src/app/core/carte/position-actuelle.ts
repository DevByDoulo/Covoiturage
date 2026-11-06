import { Injectable } from '@angular/core';
import { Observable } from 'rxjs';

/** Position de l'appareil, avec sa précision en mètres (rayon du cercle d'incertitude). */
export interface Position {
  latitude: number;
  longitude: number;
  precisionM: number;
  /** Direction de déplacement en degrés (0 = nord), si l'appareil la connaît. */
  cap?: number;
  /** Vitesse en m/s, si l'appareil la connaît. */
  vitesse?: number;
}

/** Au-delà, la position vient du réseau (Wi-Fi, antenne) plutôt que du GPS : à vérifier par l'utilisateur. */
export const PRECISION_APPROXIMATIVE_M = 500;

/**
 * 08 — Position actuelle de l'appareil (API de géolocalisation du navigateur). Le navigateur demande
 * l'autorisation à l'utilisateur ; elle n'est disponible que sur une page sécurisée (HTTPS ou localhost).
 */
@Injectable({ providedIn: 'root' })
export class PositionActuelle {
  localiser(): Observable<Position> {
    return localiserAvec(typeof navigator === 'undefined' ? undefined : navigator.geolocation);
  }

  /** Suivi continu (guidage, partage de position) : une valeur à chaque déplacement ; s'arrête au désabonnement. */
  suivre(): Observable<Position> {
    return suivreAvec(typeof navigator === 'undefined' ? undefined : navigator.geolocation);
  }
}

export function suivreAvec(geo: Geolocation | undefined): Observable<Position> {
  return new Observable<Position>((abonne) => {
    if (!geo) {
      abonne.error(new Error('Votre navigateur ne permet pas de suivre votre position.'));
      return;
    }
    const id = geo.watchPosition(
      (p) =>
        abonne.next({
          latitude: p.coords.latitude,
          longitude: p.coords.longitude,
          precisionM: Math.round(p.coords.accuracy),
          cap: p.coords.heading ?? undefined,
          vitesse: p.coords.speed ?? undefined,
        }),
      (e) => abonne.error(new Error(messageErreur(e.code))),
      { enableHighAccuracy: true, timeout: 30_000, maximumAge: 2_000 },
    );
    return () => geo.clearWatch(id);
  });
}

/** Séparée du service pour être testée avec une fausse géolocalisation. */
export function localiserAvec(geo: Geolocation | undefined): Observable<Position> {
  return new Observable<Position>((abonne) => {
    if (!geo) {
      abonne.error(new Error("Votre navigateur ne permet pas de connaître votre position. Saisissez l'adresse."));
      return;
    }
    geo.getCurrentPosition(
      (p) => {
        abonne.next({ latitude: p.coords.latitude, longitude: p.coords.longitude, precisionM: Math.round(p.coords.accuracy) });
        abonne.complete();
      },
      (e) => abonne.error(new Error(messageErreur(e.code))),
      { enableHighAccuracy: true, timeout: 15_000, maximumAge: 60_000 },
    );
  });
}

function messageErreur(code: number): string {
  switch (code) {
    case 1: // PERMISSION_DENIED
      return "Accès à votre position refusé. Autorisez-le dans les réglages du navigateur, ou saisissez l'adresse.";
    case 3: // TIMEOUT
      return "Votre position n'a pas pu être trouvée à temps. Réessayez, ou saisissez l'adresse.";
    default: // POSITION_UNAVAILABLE
      return "Votre position est introuvable pour le moment (GPS ou réseau). Saisissez l'adresse.";
  }
}
