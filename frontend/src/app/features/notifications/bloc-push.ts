import { ChangeDetectionStrategy, Component, inject, signal } from '@angular/core';
import { lireErreur } from '../../core/api/erreur-api';
import { Alerte } from '../../shared/ui/alerte';
import { PushService } from './push.service';

/**
 * Bloc « Notifications push » de l'écran Notifications : préférence du compte (tous ses appareils) et activation
 * sur ce navigateur.
 */
@Component({
  selector: 'app-bloc-push',
  imports: [Alerte],
  template: `
    <section class="carte bloc-push">
      <div class="ligne">
        <label for="push-actif">
          <strong>Notifications push</strong>
          <span>Réservations, messages et trajets, même quand le site est fermé.</span>
        </label>
        <input class="interrupteur" id="push-actif" type="checkbox" role="switch" [checked]="actif()"
          [disabled]="actif() === null || enCours()" (change)="basculer($event)" />
      </div>
      @if (actif()) {
        <p class="etat">
          @switch (push.etat()) {
            @case ('actif') { Activées sur ce navigateur. }
            @case ('inactif') {
              <button class="bouton bouton--secondaire" type="button" [disabled]="enCours()" (click)="activer()">
                Activer sur ce navigateur
              </button>
            }
            @case ('bloque') { Bloquées par le navigateur : autorisez les notifications dans les réglages du site. }
            @case ('non-configure') { Pas encore disponibles sur le site (configuration Firebase à compléter). }
            @case ('indisponible') { Ce navigateur ne prend pas en charge les notifications push. }
          }
        </p>
      }
      @if (erreur(); as e) {
        <app-alerte type="erreur">{{ e }}</app-alerte>
      }
    </section>
  `,
  styles: `
    .bloc-push {
      display: flex;
      flex-direction: column;
      gap: 10px;
    }
    .ligne {
      display: flex;
      align-items: center;
      justify-content: space-between;
      gap: 14px;
    }
    label {
      display: flex;
      flex-direction: column;
      gap: 2px;
      cursor: pointer;
      span {
        color: var(--texte-2);
        font-size: 14px;
      }
    }
    .etat {
      margin: 0;
      color: var(--texte-2);
      font-size: 14px;
    }
  `,
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class BlocPush {
  protected readonly push = inject(PushService);
  protected readonly actif = signal<boolean | null>(null);
  protected readonly enCours = signal(false);
  protected readonly erreur = signal<string | null>(null);

  constructor() {
    this.push.preferences().subscribe({
      next: (p) => this.actif.set(p.pushActive),
      error: () => this.actif.set(true),
    });
  }

  protected basculer(e: Event): void {
    const valeur = (e.target as HTMLInputElement).checked;
    this.enCours.set(true);
    this.erreur.set(null);
    this.push.modifierPreferences(valeur).subscribe({
      next: (p) => {
        this.actif.set(p.pushActive);
        this.enCours.set(false);
      },
      error: (err: unknown) => {
        (e.target as HTMLInputElement).checked = !valeur;
        this.erreur.set(lireErreur(err).message);
        this.enCours.set(false);
      },
    });
  }

  protected async activer(): Promise<void> {
    this.enCours.set(true);
    this.erreur.set(null);
    const ok = await this.push.activer();
    if (!ok && this.push.etat() === 'inactif') this.erreur.set("Les notifications n'ont pas pu être activées.");
    this.enCours.set(false);
  }
}
