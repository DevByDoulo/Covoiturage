import { DatePipe } from '@angular/common';
import { ChangeDetectionStrategy, Component, inject, signal } from '@angular/core';
import { lireErreur } from '../../core/api/erreur-api';
import { Icone } from '../../shared/ui/icone';
import { AlerteRecherche, AlertesService } from './alertes.service';

/** Bloc « Mes alertes » : alertes de recherche à venir, avec suppression. Masqué s'il n'y en a aucune. */
@Component({
  selector: 'app-mes-alertes',
  imports: [DatePipe, Icone],
  template: `
    @if (service.alertes()?.length) {
      <section class="carte bloc" aria-labelledby="titre-alertes">
        <h2 id="titre-alertes"><app-icone nom="cloche" /> Mes alertes</h2>
        <p class="bloc__sous-titre">Vous recevez une notification dès qu'un trajet correspondant est publié.</p>
        <ul>
          @for (a of service.alertes(); track a.id) {
            <li>
              <span>
                <strong>{{ a.depart.lieu }} → {{ a.arrivee.lieu }}</strong>
                <small>{{ a.date | date: 'EEEE d MMMM' }}@if (a.prixMax) { · {{ a.prixMax }} FCFA max. }</small>
              </span>
              <button type="button" class="bouton-rond" [disabled]="suppression() === a.id" (click)="supprimer(a)"
                      [attr.aria-label]="'Supprimer l’alerte ' + a.depart.lieu + ' → ' + a.arrivee.lieu">
                <app-icone nom="poubelle" [taille]="16" />
              </button>
            </li>
          }
        </ul>
        @if (erreur(); as e) {
          <p class="message-erreur">{{ e }}</p>
        }
      </section>
    }
  `,
  styles: `
    ul {
      display: flex;
      flex-direction: column;
      gap: 6px;
      margin: 0;
      padding: 0;
      list-style: none;
    }
    li {
      display: flex;
      align-items: center;
      justify-content: space-between;
      gap: 12px;
      padding: 10px 12px;
      border-radius: var(--rayon);
      background: var(--surface-2);
    }
    li > span {
      display: flex;
      flex-direction: column;
      min-width: 0;
    }
    small {
      color: var(--texte-2);
    }
    small::first-letter {
      text-transform: uppercase;
    }
  `,
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class MesAlertes {
  protected readonly service = inject(AlertesService);
  protected readonly suppression = signal<number | null>(null);
  protected readonly erreur = signal<string | null>(null);

  constructor() {
    this.service.charger();
  }

  protected supprimer(a: AlerteRecherche): void {
    this.suppression.set(a.id);
    this.erreur.set(null);
    this.service.supprimer(a.id).subscribe({
      next: () => this.suppression.set(null),
      error: (e) => {
        this.suppression.set(null);
        this.erreur.set(lireErreur(e).message);
      },
    });
  }
}
