import { HttpClient, HttpParams } from '@angular/common/http';
import { Injectable, inject } from '@angular/core';
import { Observable } from 'rxjs';
import { environment } from '../../../environments/environment';
import { Page, UtilisateurLigne } from '../admin/admin.service';
import { Decision, MotifSignalement, Signalement, SignalementRequete, StatutSignalement } from './signalements.models';

/** Vue du back-office d'un signalement. */
export interface SignalementAdmin {
  id: number;
  signaleur: UtilisateurLigne;
  signale: UtilisateurLigne;
  motif: MotifSignalement;
  description: string | null;
  statut: StatutSignalement;
  decisionAdmin: string | null;
  admin: string | null;
  idTrajet: number | null;
  trajet: string | null;
  totalContreSignale: number;
  dateSignalement: string;
  dateTraitement: string | null;
}

/** API du module 10 : signaler une personne, suivre mes signalements, modérer (administrateur). */
@Injectable({ providedIn: 'root' })
export class SignalementsService {
  private readonly http = inject(HttpClient);
  private readonly api = environment.apiUrl;

  signaler(requete: SignalementRequete): Observable<Signalement> {
    return this.http.post<Signalement>(`${this.api}/signalements`, requete);
  }

  mes(): Observable<Signalement[]> {
    return this.http.get<Signalement[]>(`${this.api}/signalements/mes`);
  }

  liste(statut: StatutSignalement | '', idUtilisateur: number | null, page: number): Observable<Page<SignalementAdmin>> {
    let params = new HttpParams().set('page', page).set('taille', 20);
    if (statut) params = params.set('statut', statut);
    if (idUtilisateur) params = params.set('utilisateur', idUtilisateur);
    return this.http.get<Page<SignalementAdmin>>(`${this.api}/admin/signalements`, { params });
  }

  decider(id: number, decision: Decision, message: string | null): Observable<SignalementAdmin> {
    return this.http.patch<SignalementAdmin>(`${this.api}/admin/signalements/${id}`, { decision, message });
  }
}
