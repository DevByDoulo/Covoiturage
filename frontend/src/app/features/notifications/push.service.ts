import { HttpClient } from '@angular/common/http';
import { Injectable, InjectionToken, inject, signal } from '@angular/core';
import { Router } from '@angular/router';
import type { Messaging } from 'firebase/messaging';
import { Observable, firstValueFrom } from 'rxjs';
import { environment } from '../../../environments/environment';
import { SessionService } from '../../core/auth/session.service';
import { NotificationsService } from './notifications.service';

/** Message du service worker (public/firebase-messaging-sw.js). */
export interface MessageServiceWorker {
  type: 'yobalema-push' | 'yobalema-ouvrir';
  lien: string | null;
}

/** Navigateur + Firebase, remplacés par un faux dans les tests. */
export interface PlateformePushWeb {
  supportee(): boolean;
  configuree(): boolean;
  permission(): NotificationPermission;
  demanderPermission(): Promise<NotificationPermission>;
  /** Enregistre le service worker puis demande le jeton FCM de ce navigateur. */
  jeton(): Promise<string>;
  supprimerJeton(): Promise<void>;
  ecouter(traiter: (m: MessageServiceWorker) => void): void;
}

class PlateformeNavigateur implements PlateformePushWeb {
  private messaging?: Promise<Messaging>;

  supportee(): boolean {
    return typeof window !== 'undefined' && 'serviceWorker' in navigator && 'PushManager' in window && 'Notification' in window;
  }

  configuree(): boolean {
    const c = environment.firebase;
    return !!(c.apiKey && c.appId && c.projectId && c.messagingSenderId && c.vapidKey);
  }

  permission(): NotificationPermission {
    return Notification.permission;
  }

  demanderPermission(): Promise<NotificationPermission> {
    return Notification.requestPermission();
  }

  async jeton(): Promise<string> {
    await navigator.serviceWorker.register(new URL('firebase-messaging-sw.js', document.baseURI).href);
    const enregistrement = await navigator.serviceWorker.ready;
    const { getToken } = await import('firebase/messaging');
    return getToken(await this.charger(), {
      vapidKey: environment.firebase.vapidKey,
      serviceWorkerRegistration: enregistrement,
    });
  }

  async supprimerJeton(): Promise<void> {
    if (!this.messaging) return;
    const { deleteToken } = await import('firebase/messaging');
    await deleteToken(await this.messaging);
  }

  ecouter(traiter: (m: MessageServiceWorker) => void): void {
    navigator.serviceWorker.addEventListener('message', (e: MessageEvent) => {
      const m = e.data as MessageServiceWorker | null;
      if (m?.type === 'yobalema-push' || m?.type === 'yobalema-ouvrir') traiter(m);
    });
  }

  /** Firebase n'est chargé (morceau séparé) qu'au premier usage du push. */
  private charger(): Promise<Messaging> {
    this.messaging ??= Promise.all([import('firebase/app'), import('firebase/messaging')]).then(([app, messaging]) => {
      const { vapidKey: _, ...options } = environment.firebase;
      return messaging.getMessaging(app.getApps()[0] ?? app.initializeApp(options));
    });
    return this.messaging;
  }
}

export const PLATEFORME_PUSH = new InjectionToken<PlateformePushWeb>('PLATEFORME_PUSH', {
  providedIn: 'root',
  factory: () => new PlateformeNavigateur(),
});

/**
 * État du push sur ce navigateur : indisponible (navigateur trop ancien), non configuré (clés Firebase absentes),
 * bloqué (permission refusée), inactif (à activer d'un clic), actif (jeton enregistré auprès de l'API).
 */
export type EtatPush = 'indisponible' | 'non-configure' | 'bloque' | 'inactif' | 'actif';

/**
 * Notifications push du navigateur (module 06) : jeton enregistré à l'ouverture de l'espace connecté si la
 * permission est déjà accordée (sinon via le bouton « Activer », la fenêtre du navigateur devant suivre un clic),
 * et retiré à la déconnexion.
 */
@Injectable({ providedIn: 'root' })
export class PushService {
  private readonly http = inject(HttpClient);
  private readonly router = inject(Router);
  private readonly notifications = inject(NotificationsService);
  private readonly plateforme = inject(PLATEFORME_PUSH);
  private readonly api = `${environment.apiUrl}/moi`;
  private jeton: string | null = null;
  private ecoute = false;

  readonly etat = signal<EtatPush>('inactif');

  constructor() {
    inject(SessionService).avantDeconnexion(() => this.retirer());
  }

  /** Espace connecté affiché : réenregistre le jeton si l'utilisateur a déjà autorisé les notifications. */
  async demarrer(): Promise<void> {
    const base = this.etatDeBase();
    this.etat.set(base);
    if (base !== 'inactif') return;
    this.ecouter();
    if (this.plateforme.permission() === 'granted') await this.enregistrer();
  }

  /** Bouton « Activer sur ce navigateur » : fenêtre d'autorisation, puis enregistrement. */
  async activer(): Promise<boolean> {
    const base = this.etatDeBase();
    if (base === 'indisponible' || base === 'non-configure') {
      this.etat.set(base);
      return false;
    }
    const permission = await this.plateforme.demanderPermission();
    if (permission !== 'granted') {
      this.etat.set(permission === 'denied' ? 'bloque' : 'inactif');
      return false;
    }
    this.ecouter();
    return this.enregistrer();
  }

  /** Déconnexion : ce navigateur ne reçoit plus les notifications de ce compte. */
  retirer(): void {
    const jeton = this.jeton;
    this.jeton = null;
    if (jeton) {
      this.http.delete<void>(`${this.api}/appareils/${encodeURIComponent(jeton)}`).subscribe({ error: () => {} });
      this.plateforme.supprimerJeton().catch(() => {});
    }
    if (this.etat() === 'actif') this.etat.set('inactif');
  }

  /** Préférence du compte (tous ses appareils) : recevoir ou non les notifications push. */
  preferences(): Observable<{ pushActive: boolean }> {
    return this.http.get<{ pushActive: boolean }>(`${this.api}/notifications/preferences`);
  }

  modifierPreferences(pushActive: boolean): Observable<{ pushActive: boolean }> {
    return this.http.put<{ pushActive: boolean }>(`${this.api}/notifications/preferences`, { pushActive });
  }

  private etatDeBase(): EtatPush {
    if (!this.plateforme.supportee()) return 'indisponible';
    if (!this.plateforme.configuree()) return 'non-configure';
    if (this.plateforme.permission() === 'denied') return 'bloque';
    return this.jeton ? 'actif' : 'inactif';
  }

  private async enregistrer(): Promise<boolean> {
    try {
      const jeton = await this.plateforme.jeton();
      await firstValueFrom(this.http.post<void>(`${this.api}/appareils`, { jeton, plateforme: 'WEB' }));
      this.jeton = jeton;
      this.etat.set('actif');
      return true;
    } catch {
      this.etat.set('inactif');
      return false;
    }
  }

  private ecouter(): void {
    if (this.ecoute) return;
    this.ecoute = true;
    this.plateforme.ecouter((m) => {
      this.notifications.compter();
      if (m.type === 'yobalema-ouvrir' && m.lien?.startsWith('/')) this.router.navigateByUrl(m.lien);
    });
  }
}
