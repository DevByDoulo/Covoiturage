import { HttpClient } from '@angular/common/http';
import { Injectable, inject, signal } from '@angular/core';
import { Observable, map, tap } from 'rxjs';
import { environment } from '../../../environments/environment';
import { PersonneResume } from '../reservations/reservations.models';

export interface TrajetConversation {
  id: number;
  lieuDepart: string;
  lieuArrivee: string;
  dateHeureDepart: string;
  statut: string;
}

export interface ConversationResume {
  id: number;
  trajet: TrajetConversation;
  interlocuteur: PersonneResume;
  jeSuisConducteur: boolean;
  dernierMessage: string | null;
  dernierDeMoi: boolean;
  dateDernierMessage: string;
  nonLus: number;
}

export interface MessageConversation {
  id: number;
  contenu: string;
  dateEnvoi: string;
  deMoi: boolean;
  lu: boolean;
}

export interface ConversationDetail {
  id: number;
  trajet: TrajetConversation;
  interlocuteur: PersonneResume;
  jeSuisConducteur: boolean;
  /** Raison pour laquelle on ne peut plus écrire, sinon null. */
  fermeture: string | null;
  messages: MessageConversation[];
}

const INTERVALLE_MS = 30_000;

/** 09 — Messagerie entre conducteur et passagers, et compteur des messages non lus (rafraîchi toutes les 30 s). */
@Injectable({ providedIn: 'root' })
export class MessagesService {
  private readonly http = inject(HttpClient);
  private readonly api = `${environment.apiUrl}/moi/conversations`;
  private minuterie: ReturnType<typeof setInterval> | null = null;

  readonly nonLus = signal(0);

  /** Démarre (ou arrête) le suivi du compteur ; appelé par le cadre de l'espace connecté. */
  suivre(actif: boolean): void {
    if (this.minuterie) clearInterval(this.minuterie);
    this.minuterie = null;
    if (!actif) {
      this.nonLus.set(0);
      return;
    }
    this.compter();
    this.minuterie = setInterval(() => this.compter(), INTERVALLE_MS);
  }

  compter(): void {
    this.http.get<{ nombre: number }>(`${this.api}/non-lus`).subscribe({
      next: (r) => this.nonLus.set(r.nombre),
      error: () => {},
    });
  }

  /** Conversation d'un trajet : le passager n'indique rien, le conducteur indique le passager. */
  ouvrir(idTrajet: number, idPassager?: number): Observable<number> {
    return this.http
      .post<{ id: number }>(`${environment.apiUrl}/trajets/${idTrajet}/conversation`, idPassager ? { idPassager } : {})
      .pipe(map((r) => r.id));
  }

  lister(): Observable<ConversationResume[]> {
    return this.http.get<ConversationResume[]>(this.api);
  }

  /** Ouvrir une conversation marque ses messages reçus comme lus : le compteur est recalculé. */
  consulter(id: number): Observable<ConversationDetail> {
    return this.http.get<ConversationDetail>(`${this.api}/${id}`).pipe(tap(() => this.compter()));
  }

  envoyer(id: number, contenu: string): Observable<MessageConversation> {
    return this.http.post<MessageConversation>(`${this.api}/${id}/messages`, { contenu });
  }
}
