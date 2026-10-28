import { HttpClient } from '@angular/common/http';
import { Injectable, inject, signal } from '@angular/core';
import { Observable, tap } from 'rxjs';
import { environment } from '../../../environments/environment';
import { PointTrajet } from '../trajets/trajets.models';

export interface AlerteRecherche {
  id: number;
  depart: PointTrajet;
  arrivee: PointTrajet;
  date: string;
  rayonKm: number;
  prixMax: number | null;
  dateCreation: string;
}

export interface CreationAlerte {
  depart: PointTrajet;
  arrivee: PointTrajet;
  date: string;
  rayonKm?: number;
  prixMax?: number;
}

/**
 * Alertes de recherche (`/api/moi/alertes`) : le passager est prévenu par une notification dès qu'un trajet
 * correspondant est publié. La liste est partagée entre la page Rechercher et le bloc « Mes alertes ».
 */
@Injectable({ providedIn: 'root' })
export class AlertesService {
  private readonly http = inject(HttpClient);
  private readonly api = `${environment.apiUrl}/moi/alertes`;

  readonly alertes = signal<AlerteRecherche[] | null>(null);

  charger(): void {
    this.http.get<AlerteRecherche[]>(this.api).subscribe({ next: (l) => this.alertes.set(l), error: () => this.alertes.set([]) });
  }

  creer(alerte: CreationAlerte): Observable<AlerteRecherche> {
    return this.http.post<AlerteRecherche>(this.api, alerte).pipe(
      tap((a) => this.alertes.update((l) => [...(l ?? []), a].sort((x, y) => x.date.localeCompare(y.date)))),
    );
  }

  supprimer(id: number): Observable<void> {
    return this.http.delete<void>(`${this.api}/${id}`).pipe(tap(() => this.alertes.update((l) => l?.filter((a) => a.id !== id) ?? null)));
  }
}
