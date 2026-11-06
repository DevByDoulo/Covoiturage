import { Injectable, inject, signal } from '@angular/core';
import { Subscription } from 'rxjs';
import { lireErreur } from '../../core/api/erreur-api';
import { distanceM } from '../../core/carte/itineraire';
import { Position, PositionActuelle } from '../../core/carte/position-actuelle';
import { SuiviService } from './suivi.service';

/** Envoi au plus toutes les 5 s ; sinon dès 15 m de déplacement, et au moins toutes les 20 s à l'arrêt. */
const INTERVALLE_MIN_MS = 5_000;
const INTERVALLE_MAX_MS = 20_000;
const DEPLACEMENT_MIN_M = 15;

interface VerrouEcran {
  release(): Promise<void>;
}

/**
 * 08 — Partage de la position du conducteur. Service global : le partage continue quand le conducteur change
 * d'écran dans le site (il s'arrête à la fermeture de l'onglet, ou avec « Arrêter »).
 */
@Injectable({ providedIn: 'root' })
export class PartagePosition {
  private readonly positions = inject(PositionActuelle);
  private readonly suivi = inject(SuiviService);

  /** Trajet dont la position est partagée (null : pas de partage). */
  readonly idTrajet = signal<number | null>(null);
  readonly dernierEnvoi = signal<Date | null>(null);
  readonly erreur = signal<string | null>(null);

  private abonnement?: Subscription;
  private envoye: { position: Position; instant: number } | null = null;
  private envoiEnCours = false;
  private verrou: VerrouEcran | null = null;
  /** Position reçue trop tôt, envoyée à la fin du délai minimal. */
  private enAttente: Position | null = null;
  private differe?: ReturnType<typeof setTimeout>;

  demarrer(idTrajet: number): void {
    if (this.idTrajet() === idTrajet) return;
    this.arreter(false);
    this.idTrajet.set(idTrajet);
    this.erreur.set(null);
    this.abonnement = this.positions.suivre().subscribe({
      next: (p) => this.peutEtreEnvoyer(idTrajet, p),
      error: (e: Error) => {
        this.erreur.set(e.message);
        this.arreter(false);
      },
    });
    const wakeLock = (navigator as Navigator & { wakeLock?: { request(t: 'screen'): Promise<VerrouEcran> } }).wakeLock;
    wakeLock?.request('screen').then((v) => (this.verrou = v)).catch(() => undefined);
  }

  /** [effacer] : supprime aussi la position côté serveur (les passagers ne la voient plus). */
  arreter(effacer = true): void {
    const id = this.idTrajet();
    this.abonnement?.unsubscribe();
    this.abonnement = undefined;
    this.verrou?.release().catch(() => undefined);
    this.verrou = null;
    this.envoye = null;
    this.enAttente = null;
    clearTimeout(this.differe);
    this.differe = undefined;
    this.idTrajet.set(null);
    this.dernierEnvoi.set(null);
    if (effacer && id !== null) this.suivi.arreter(id).subscribe({ error: () => undefined });
  }

  private peutEtreEnvoyer(idTrajet: number, p: Position): void {
    const maintenant = Date.now();
    const precedent = this.envoye;
    if (precedent && distanceM(precedent.position, p) >= DEPLACEMENT_MIN_M
        && maintenant - precedent.instant < INTERVALLE_MIN_MS) {
      // Déplacement trop tôt après le dernier envoi : envoyé dès que le délai est écoulé (sinon, à l'arrêt, le GPS
      // ne redonne plus de position et la dernière ne partirait jamais).
      this.enAttente = p;
      this.differe ??= setTimeout(() => {
        this.differe = undefined;
        const derniere = this.enAttente;
        this.enAttente = null;
        if (derniere && this.idTrajet() === idTrajet) this.peutEtreEnvoyer(idTrajet, derniere);
      }, INTERVALLE_MIN_MS - (maintenant - precedent.instant));
      return;
    }
    const attendu =
      !precedent ||
      maintenant - precedent.instant >= INTERVALLE_MAX_MS ||
      (maintenant - precedent.instant >= INTERVALLE_MIN_MS && distanceM(precedent.position, p) >= DEPLACEMENT_MIN_M);
    if (!attendu || this.envoiEnCours) return;
    this.enAttente = null;
    this.envoiEnCours = true;
    this.envoye = { position: p, instant: maintenant };
    this.suivi
      .envoyer(idTrajet, {
        latitude: p.latitude,
        longitude: p.longitude,
        precisionM: p.precisionM,
        cap: p.cap,
        vitesse: p.vitesse,
      })
      .subscribe({
        next: () => {
          this.envoiEnCours = false;
          this.erreur.set(null);
          this.dernierEnvoi.set(new Date());
        },
        error: (e) => {
          this.envoiEnCours = false;
          const erreur = lireErreur(e);
          this.erreur.set(erreur.message);
          // Refus définitif (trop tôt, trajet terminé ou annulé) : on arrête le partage.
          if (erreur.status === 409 || erreur.status === 403 || erreur.status === 404) this.arreter(false);
        },
      });
  }
}
