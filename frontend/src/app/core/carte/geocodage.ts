import { HttpClient } from '@angular/common/http';
import { Injectable, inject } from '@angular/core';
import { Observable, catchError, defer, map, of, timer, switchMap } from 'rxjs';

/** Lieu choisi par l'utilisateur : libellé court + coordonnées. */
export interface Lieu {
  libelle: string;
  /** Précision affichée sous le libellé dans les suggestions (quartier, ville…). */
  detail?: string;
  latitude: number;
  longitude: number;
}

/**
 * Transformation adresse <-> coordonnées. Les écrans ne dépendent que de cette classe abstraite :
 * pour passer à Google (Places / Geocoding), il suffit de fournir une autre implémentation dans app.config.
 */
export abstract class Geocodage {
  abstract rechercher(texte: string): Observable<Lieu[]>;
  abstract adresseDe(latitude: number, longitude: number): Observable<string | null>;
}

interface ResultatNominatim {
  lat: string;
  lon: string;
  name?: string;
  display_name: string;
}

/**
 * Implémentation OpenStreetMap (Nominatim), sans clé. Politique d'usage de Nominatim :
 * 1 requête par seconde au maximum et pas d'autocomplétion à chaque frappe —
 * la recherche se lance donc à la validation du champ, et les appels sont espacés.
 */
@Injectable()
export class GeocodageNominatim extends Geocodage {
  private readonly http = inject(HttpClient);
  private readonly api = 'https://nominatim.openstreetmap.org';
  private prochainAppelPossible = 0;

  rechercher(texte: string): Observable<Lieu[]> {
    const q = texte.trim();
    if (q.length < 2) return of([]);
    return this.espacer(() =>
      this.http.get<ResultatNominatim[]>(`${this.api}/search`, {
        params: { q, format: 'jsonv2', countrycodes: 'sn', limit: 6, 'accept-language': 'fr' },
      }),
    ).pipe(
      map((resultats) => resultats.map(versLieu)),
      catchError(() => of([])),
    );
  }

  adresseDe(latitude: number, longitude: number): Observable<string | null> {
    return this.espacer(() =>
      this.http.get<ResultatNominatim>(`${this.api}/reverse`, {
        params: { lat: latitude, lon: longitude, format: 'jsonv2', zoom: 17, 'accept-language': 'fr' },
      }),
    ).pipe(
      map((r) => (r?.display_name ? versLieu(r).libelle : null)),
      catchError(() => of(null)),
    );
  }

  /** Respecte l'intervalle d'une seconde entre deux appels. */
  private espacer<T>(appel: () => Observable<T>): Observable<T> {
    return defer(() => {
      const attente = Math.max(0, this.prochainAppelPossible - Date.now());
      this.prochainAppelPossible = Date.now() + attente + 1100;
      return timer(attente).pipe(switchMap(appel));
    });
  }
}

function versLieu(r: ResultatNominatim): Lieu {
  const parties = r.display_name.split(',').map((p) => p.trim()).filter(Boolean);
  const libelle = (r.name || parties.slice(0, 2).join(', ')).slice(0, 200);
  const detail = parties
    .filter((p) => p !== r.name && p !== 'Sénégal')
    .slice(0, 3)
    .join(', ');
  return { libelle, detail, latitude: Number(r.lat), longitude: Number(r.lon) };
}
