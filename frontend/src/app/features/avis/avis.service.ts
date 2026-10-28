import { HttpClient } from '@angular/common/http';
import { Injectable, inject } from '@angular/core';
import { Observable } from 'rxjs';
import { environment } from '../../../environments/environment';
import { Avis, AvisADonner, Reputation } from './avis.models';

/** API du module 05 : noter après un voyage, avis à donner, réputation publique. */
@Injectable({ providedIn: 'root' })
export class AvisService {
  private readonly http = inject(HttpClient);
  private readonly api = environment.apiUrl;

  aDonner(): Observable<AvisADonner[]> {
    return this.http.get<AvisADonner[]>(`${this.api}/moi/avis-a-donner`);
  }

  evaluer(idReservation: number, note: number, commentaire: string | null): Observable<Avis> {
    return this.http.post<Avis>(`${this.api}/reservations/${idReservation}/evaluation`, { note, commentaire });
  }

  reputation(idUtilisateur: number): Observable<Reputation> {
    return this.http.get<Reputation>(`${this.api}/utilisateurs/${idUtilisateur}/avis`);
  }
}
