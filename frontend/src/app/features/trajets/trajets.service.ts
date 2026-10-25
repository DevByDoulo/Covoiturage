import { HttpClient } from '@angular/common/http';
import { Injectable, inject } from '@angular/core';
import { Observable } from 'rxjs';
import { environment } from '../../../environments/environment';
import {
  DemandeEstimation,
  EstimationReponse,
  ModificationTrajet,
  PublicationTrajet,
  Trajet,
  VehiculeConducteur,
} from './trajets.models';

/** Accès à l'API des trajets (module F4). */
@Injectable({ providedIn: 'root' })
export class TrajetsService {
  private readonly http = inject(HttpClient);
  private readonly api = environment.apiUrl;

  estimer(demande: DemandeEstimation): Observable<EstimationReponse> {
    return this.http.post<EstimationReponse>(`${this.api}/trajets/estimation`, demande);
  }

  publier(publication: PublicationTrajet): Observable<Trajet> {
    return this.http.post<Trajet>(`${this.api}/trajets`, publication);
  }

  detail(id: number): Observable<Trajet> {
    return this.http.get<Trajet>(`${this.api}/trajets/${id}`);
  }

  mesTrajets(): Observable<Trajet[]> {
    return this.http.get<Trajet[]>(`${this.api}/moi/trajets`);
  }

  modifier(id: number, modification: ModificationTrajet): Observable<Trajet> {
    return this.http.put<Trajet>(`${this.api}/trajets/${id}`, modification);
  }

  annuler(id: number, motif: string | null): Observable<Trajet> {
    return this.http.post<Trajet>(`${this.api}/trajets/${id}/annuler`, { motif });
  }

  demarrer(id: number): Observable<Trajet> {
    return this.http.post<Trajet>(`${this.api}/trajets/${id}/demarrer`, {});
  }

  terminer(id: number): Observable<Trajet> {
    return this.http.post<Trajet>(`${this.api}/trajets/${id}/terminer`, {});
  }

  /** Véhicules du conducteur, pour choisir celui du trajet. L'écran de gestion relève de F2. */
  mesVehicules(): Observable<VehiculeConducteur[]> {
    return this.http.get<VehiculeConducteur[]>(`${this.api}/moi/vehicules`);
  }
}
