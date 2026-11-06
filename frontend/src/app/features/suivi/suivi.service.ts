import { HttpClient } from '@angular/common/http';
import { Injectable, inject } from '@angular/core';
import { Observable, map } from 'rxjs';
import { environment } from '../../../environments/environment';

/** Position du conducteur telle que renvoyée par l'API (module suivi). */
export interface PositionConducteur {
  latitude: number;
  longitude: number;
  precisionM: number | null;
  cap: number | null;
  /** m/s */
  vitesse: number | null;
  dateMaj: string;
  /** Temps écoulé depuis le dernier envoi du conducteur. */
  ageSecondes: number;
}

export interface EnvoiPosition {
  latitude: number;
  longitude: number;
  precisionM?: number;
  cap?: number;
  vitesse?: number;
}

/** 08 — API du suivi en temps réel : /api/trajets/{id}/position. */
@Injectable({ providedIn: 'root' })
export class SuiviService {
  private readonly http = inject(HttpClient);
  private readonly api = environment.apiUrl;

  envoyer(idTrajet: number, position: EnvoiPosition): Observable<PositionConducteur> {
    return this.http.post<PositionConducteur>(`${this.api}/trajets/${idTrajet}/position`, position);
  }

  /** null : le conducteur ne partage pas (ou plus) sa position (réponse 204). */
  consulter(idTrajet: number): Observable<PositionConducteur | null> {
    return this.http
      .get<PositionConducteur>(`${this.api}/trajets/${idTrajet}/position`, { observe: 'response' })
      .pipe(map((r) => (r.status === 204 ? null : r.body)));
  }

  arreter(idTrajet: number): Observable<void> {
    return this.http.delete<void>(`${this.api}/trajets/${idTrajet}/position`);
  }
}
