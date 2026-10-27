import { HttpClient } from '@angular/common/http';
import { Injectable, inject } from '@angular/core';
import { Observable } from 'rxjs';
import { environment } from '../../../environments/environment';
import {
  CodeEmbarquement,
  EmbarquementConfirme,
  LignePaiement,
  MoyenDisponible,
  MoyenPaiement,
  Recu,
  Reservation,
  SessionPaiement,
} from './reservations.models';

/** API du module 04 : réservations (passager et conducteur), paiements, historique et reçus. */
@Injectable({ providedIn: 'root' })
export class ReservationsService {
  private readonly http = inject(HttpClient);
  private readonly api = environment.apiUrl;

  // ---- Passager

  reserver(idTrajet: number, nombrePlaces: number, moyenPaiement: MoyenPaiement): Observable<Reservation> {
    return this.http.post<Reservation>(`${this.api}/trajets/${idTrajet}/reservations`, { nombrePlaces, moyenPaiement });
  }

  mesReservations(): Observable<Reservation[]> {
    return this.http.get<Reservation[]>(`${this.api}/moi/reservations`);
  }

  annuler(id: number, motif: string | null): Observable<Reservation> {
    return this.http.post<Reservation>(`${this.api}/reservations/${id}/annuler`, { motif });
  }

  codeEmbarquement(id: number): Observable<CodeEmbarquement> {
    return this.http.get<CodeEmbarquement>(`${this.api}/reservations/${id}/embarquement`);
  }

  /** Ouvre le paiement en ligne (ou passe aux espèces si moyen = ESPECES). */
  payer(id: number, moyen?: MoyenPaiement): Observable<SessionPaiement> {
    return this.http.post<SessionPaiement>(`${this.api}/reservations/${id}/paiement`, moyen ? { moyen } : {});
  }

  // ---- Conducteur

  reservationsDuTrajet(idTrajet: number): Observable<Reservation[]> {
    return this.http.get<Reservation[]>(`${this.api}/trajets/${idTrajet}/reservations`);
  }

  accepter(id: number): Observable<Reservation> {
    return this.http.post<Reservation>(`${this.api}/reservations/${id}/accepter`, {});
  }

  refuser(id: number, motif: string | null): Observable<Reservation> {
    return this.http.post<Reservation>(`${this.api}/reservations/${id}/refuser`, { motif });
  }

  confirmerEmbarquement(idTrajet: number, code: string): Observable<EmbarquementConfirme> {
    return this.http.post<EmbarquementConfirme>(`${this.api}/trajets/${idTrajet}/embarquement`, { code });
  }

  // ---- Facturation

  moyens(): Observable<MoyenDisponible[]> {
    return this.http.get<MoyenDisponible[]>(`${this.api}/paiements/moyens`);
  }

  historique(): Observable<LignePaiement[]> {
    return this.http.get<LignePaiement[]>(`${this.api}/moi/paiements`);
  }

  recu(reference: string): Observable<Recu> {
    return this.http.get<Recu>(`${this.api}/paiements/${encodeURIComponent(reference)}/recu`);
  }
}
