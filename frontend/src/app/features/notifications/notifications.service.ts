import { HttpClient, HttpParams } from '@angular/common/http';
import { Injectable, inject, signal } from '@angular/core';
import { Observable, tap } from 'rxjs';
import { environment } from '../../../environments/environment';

/** Types alignés sur sn.isep.Convoiturage.notification (module 06). */
export type TypeNotification =
  | 'RESERVATION_DEMANDEE'
  | 'RESERVATION_CONFIRMEE'
  | 'RESERVATION_REFUSEE'
  | 'RESERVATION_ANNULEE'
  | 'TRAJET_MODIFIE'
  | 'TRAJET_ANNULE'
  | 'RAPPEL_TRAJET'
  | 'EMBARQUEMENT_CONFIRME'
  | 'DOCUMENT_VALIDE'
  | 'DOCUMENT_REFUSE'
  | 'COMPTE_SUSPENDU'
  | 'COMPTE_REACTIVE'
  | 'ALERTE_TRAJET'
  | 'AVIS_RECU'
  | 'MESSAGE_RECU';

export interface Notification {
  id: number;
  type: TypeNotification;
  titre: string;
  contenu: string;
  /** Écran à ouvrir au clic (ex. « /trajets/12 »). */
  lien: string | null;
  lu: boolean;
  dateEnvoi: string;
}

export interface PageNotifications {
  content: Notification[];
  page: { number: number; totalPages: number; totalElements: number };
}

const INTERVALLE_MS = 30_000;

/** Notifications de l'utilisateur connecté et compteur des non lues (rafraîchi toutes les 30 s). */
@Injectable({ providedIn: 'root' })
export class NotificationsService {
  private readonly http = inject(HttpClient);
  private readonly api = `${environment.apiUrl}/moi/notifications`;
  private minuterie: ReturnType<typeof setInterval> | null = null;

  readonly nonLues = signal(0);

  /** Démarre (ou arrête) le suivi du compteur ; appelé par le cadre de l'espace connecté. */
  suivre(actif: boolean): void {
    if (this.minuterie) clearInterval(this.minuterie);
    this.minuterie = null;
    if (!actif) {
      this.nonLues.set(0);
      return;
    }
    this.compter();
    this.minuterie = setInterval(() => this.compter(), INTERVALLE_MS);
  }

  compter(): void {
    this.http.get<{ nombre: number }>(`${this.api}/non-lues`).subscribe({
      next: (r) => this.nonLues.set(r.nombre),
      error: () => {},
    });
  }

  lister(page: number): Observable<PageNotifications> {
    return this.http.get<PageNotifications>(this.api, { params: new HttpParams().set('page', page).set('taille', 20) });
  }

  marquerLue(n: Notification): Observable<void> {
    return this.http
      .post<void>(`${this.api}/${n.id}/lue`, {})
      .pipe(tap(() => this.nonLues.update((x) => Math.max(0, x - 1))));
  }

  toutesLues(): Observable<void> {
    return this.http.post<void>(`${this.api}/lues`, {}).pipe(tap(() => this.nonLues.set(0)));
  }
}
