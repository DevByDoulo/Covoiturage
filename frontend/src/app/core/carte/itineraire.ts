import { HttpClient } from '@angular/common/http';
import { Injectable, inject } from '@angular/core';
import { Observable, map } from 'rxjs';
import { Coordonnee, decoderPolyline } from '../../shared/carte/polyline';

/** À pied (passager qui rejoint le point de prise en charge) ou en voiture (conducteur). */
export type ModeDeplacement = 'pied' | 'voiture';

/** Une manœuvre à annoncer : où elle a lieu et ce qu'il faut dire. */
export interface Etape {
  latitude: number;
  longitude: number;
  /** Phrase à lire, ex. « Tournez à droite sur Rue 14 ». */
  instruction: string;
  /** Vrai pour la dernière étape (arrivée). */
  arrivee: boolean;
  /** Longueur du tronçon qui suit la manœuvre, jusqu'à la suivante. */
  distanceM: number;
}

export interface Itineraire {
  distanceM: number;
  dureeS: number;
  trace: Coordonnee[];
  /** Manœuvres dans l'ordre, la première étant le départ. */
  etapes: Etape[];
}

/** Réponse OSRM (seulement ce qui est lu). */
interface ReponseOsrm {
  code: string;
  routes?: {
    distance: number;
    duration: number;
    geometry: string;
    legs: { steps: EtapeOsrm[] }[];
  }[];
}

export interface EtapeOsrm {
  name: string;
  distance: number;
  maneuver: { type: string; modifier?: string; exit?: number; location: [number, number] };
}

/**
 * Serveurs OSRM publics de l'association FOSSGIS (données OpenStreetMap, sans clé, CORS autorisé) : profils
 * à pied et en voiture. Service gratuit sans garantie : en production, prévoir un serveur OSRM à soi ou Google.
 */
const SERVEURS: Record<ModeDeplacement, string> = {
  pied: 'https://routing.openstreetmap.de/routed-foot/route/v1/driving',
  voiture: 'https://routing.openstreetmap.de/routed-car/route/v1/driving',
};

/** 08 — Itinéraire détaillé (tracé + manœuvres en français) pour le guidage vocal. */
@Injectable({ providedIn: 'root' })
export class ItineraireService {
  private readonly http = inject(HttpClient);

  calculer(depart: Coordonnee, arrivee: Coordonnee, mode: ModeDeplacement): Observable<Itineraire> {
    const points = `${depart.longitude},${depart.latitude};${arrivee.longitude},${arrivee.latitude}`;
    return this.http
      .get<ReponseOsrm>(`${SERVEURS[mode]}/${points}`, {
        params: { overview: 'full', geometries: 'polyline', steps: 'true' },
      })
      .pipe(
        map((r) => {
          const route = r.routes?.[0];
          if (r.code !== 'Ok' || !route) throw new Error('Aucun itinéraire trouvé jusqu’au point de départ.');
          return {
            distanceM: route.distance,
            dureeS: route.duration,
            trace: decoderPolyline(route.geometry),
            etapes: etapesAnnoncees(route.legs.flatMap((l) => l.steps)),
          };
        }),
      );
  }
}

/** Garde les manœuvres utiles à annoncer (les sorties de rond-point sont déjà dites à l'entrée). */
export function etapesAnnoncees(etapes: EtapeOsrm[]): Etape[] {
  const resultat: Etape[] = [];
  for (const e of etapes) {
    if (e.maneuver.type === 'exit roundabout' || e.maneuver.type === 'exit rotary') {
      // Le tronçon après la sortie s'ajoute à l'étape du rond-point.
      if (resultat.length) resultat[resultat.length - 1].distanceM += e.distance;
      continue;
    }
    resultat.push({
      longitude: e.maneuver.location[0],
      latitude: e.maneuver.location[1],
      instruction: instructionFr(e),
      arrivee: e.maneuver.type === 'arrive',
      distanceM: e.distance,
    });
  }
  return resultat;
}

const DIRECTIONS: Record<string, string> = {
  left: 'tournez à gauche',
  right: 'tournez à droite',
  'slight left': 'serrez à gauche',
  'slight right': 'serrez à droite',
  'sharp left': 'tournez franchement à gauche',
  'sharp right': 'tournez franchement à droite',
  straight: 'continuez tout droit',
  uturn: 'faites demi-tour',
};

const ORDINAUX = ['', 'première', 'deuxième', 'troisième', 'quatrième', 'cinquième', 'sixième'];

/** Phrase française d'une manœuvre OSRM, ex. « Tournez à gauche sur Rue 14 ». */
export function instructionFr(e: EtapeOsrm): string {
  const { type, modifier, exit } = e.maneuver;
  const sur = e.name ? ` sur ${e.name}` : '';
  const direction = DIRECTIONS[modifier ?? 'straight'] ?? 'continuez';
  let phrase: string;
  switch (type) {
    case 'depart':
      phrase = `Partez${sur}`;
      break;
    case 'arrive':
      return 'Vous êtes arrivé au point de rendez-vous';
    case 'roundabout':
    case 'rotary':
      phrase = exit && exit < ORDINAUX.length
        ? `Au rond-point, prenez la ${ORDINAUX[exit]} sortie${sur}`
        : `Au rond-point, continuez${sur}`;
      break;
    case 'fork':
      phrase = `À l'embranchement, ${modifier?.includes('left') ? 'restez à gauche' : 'restez à droite'}${sur}`;
      break;
    case 'end of road':
      phrase = `Au bout de la route, ${direction}${sur}`;
      break;
    case 'new name':
    case 'continue':
      phrase = modifier === 'uturn' ? `Faites demi-tour${sur}` : `Continuez${sur}`;
      break;
    default: // turn, merge, on ramp, off ramp, notification
      phrase = `${direction}${sur}`;
  }
  return phrase.charAt(0).toUpperCase() + phrase.slice(1);
}

// ------------------------------------------------------------------ Distances

const RAYON_TERRE_M = 6_371_000;
const rad = (d: number) => (d * Math.PI) / 180;

/** Distance à vol d'oiseau en mètres. */
export function distanceM(a: Coordonnee, b: Coordonnee): number {
  const dLat = rad(b.latitude - a.latitude);
  const dLng = rad(b.longitude - a.longitude);
  const h = Math.sin(dLat / 2) ** 2 + Math.cos(rad(a.latitude)) * Math.cos(rad(b.latitude)) * Math.sin(dLng / 2) ** 2;
  return 2 * RAYON_TERRE_M * Math.asin(Math.sqrt(h));
}

/** Distance en mètres entre un point et une ligne brisée (projection plane locale, suffisante en ville). */
export function distanceAuTraceM(p: Coordonnee, trace: Coordonnee[]): number {
  if (trace.length === 0) return Infinity;
  if (trace.length === 1) return distanceM(p, trace[0]);
  const kx = RAYON_TERRE_M * Math.cos(rad(p.latitude)) * (Math.PI / 180);
  const ky = RAYON_TERRE_M * (Math.PI / 180);
  const xy = (c: Coordonnee) => [(c.longitude - p.longitude) * kx, (c.latitude - p.latitude) * ky];
  let min = Infinity;
  for (let i = 1; i < trace.length; i++) {
    const [ax, ay] = xy(trace[i - 1]);
    const [bx, by] = xy(trace[i]);
    const dx = bx - ax;
    const dy = by - ay;
    const longueur2 = dx * dx + dy * dy;
    const t = longueur2 === 0 ? 0 : Math.max(0, Math.min(1, -(ax * dx + ay * dy) / longueur2));
    min = Math.min(min, Math.hypot(ax + t * dx, ay + t * dy));
  }
  return min;
}

/** « 350 mètres », « 1,2 kilomètre » : forme parlée d'une distance (arrondie pour l'oreille). */
export function distanceParlee(m: number): string {
  if (m < 1000) {
    const arrondi = m < 100 ? Math.max(10, Math.round(m / 10) * 10) : Math.round(m / 50) * 50;
    return `${arrondi} mètres`;
  }
  const km = Math.round(m / 100) / 10;
  return `${String(km).replace('.', ',')} kilomètre${km >= 2 ? 's' : ''}`;
}
