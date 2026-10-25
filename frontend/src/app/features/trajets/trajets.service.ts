import { HttpClient, HttpParams } from '@angular/common/http';
import { Injectable, inject } from '@angular/core';
import { Observable } from 'rxjs';
import { environment } from '../../../environments/environment';
import {
  AlerteRecherche,
  CreationAlerte,
  CriteresRecherche,
  DemandeEstimation,
  EstimationReponse,
  ModificationTrajet,
  PublicationTrajet,
  Trajet,
  VehiculeConducteur,
} from './trajets.models';

/** Accès à l'API des trajets : publication et gestion (F4), recherche et alertes (F5). */
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

  // ---- F5 Recherche

  /** Recherche publique ; les critères vides ne sont pas envoyés. */
  rechercher(criteres: CriteresRecherche): Observable<Trajet[]> {
    let params = new HttpParams();
    for (const [cle, valeur] of Object.entries(criteres)) {
      if (valeur !== undefined && valeur !== null && valeur !== '') params = params.set(cle, String(valeur));
    }
    return this.http.get<Trajet[]>(`${this.api}/trajets/recherche`, { params });
  }

  mesAlertes(): Observable<AlerteRecherche[]> {
    return this.http.get<AlerteRecherche[]>(`${this.api}/moi/alertes`);
  }

  creerAlerte(alerte: CreationAlerte): Observable<AlerteRecherche> {
    return this.http.post<AlerteRecherche>(`${this.api}/moi/alertes`, alerte);
  }

  supprimerAlerte(id: number): Observable<void> {
    return this.http.delete<void>(`${this.api}/moi/alertes/${id}`);
  }

  /** Véhicules du conducteur, pour choisir celui du trajet. L'écran de gestion relève de F2. */
  mesVehicules(): Observable<VehiculeConducteur[]> {
    return this.http.get<VehiculeConducteur[]>(`${this.api}/moi/vehicules`);
  }
}
