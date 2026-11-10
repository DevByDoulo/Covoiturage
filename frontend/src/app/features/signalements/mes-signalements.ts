import { DatePipe } from '@angular/common';
import { ChangeDetectionStrategy, Component, OnInit, inject, signal } from '@angular/core';
import { ErreurApi, lireErreur } from '../../core/api/erreur-api';
import { Alerte } from '../../shared/ui/alerte';
import { LIBELLES_MOTIF, LIBELLES_STATUT_SIGNALEMENT, Signalement } from './signalements.models';
import { SignalementsService } from './signalements.service';

/** 10 — « Mes signalements » : ce que j'ai signalé et où en est le traitement. */
@Component({
  selector: 'app-mes-signalements',
  imports: [DatePipe, Alerte],
  template: `
    <div class="page">
      <h1>Mes signalements</h1>
      @if (erreur(); as e) {
        <app-alerte type="erreur">{{ e.message }}</app-alerte>
      }
      @if (liste(); as l) {
        @for (s of l; track s.id) {
          <article class="carte bloc">
            <header>
              <strong>{{ s.signale.prenom }} {{ s.signale.nomInitiale }}</strong>
              <span class="pastille" [class.pastille--attente]="s.statut === 'EN_ATTENTE' || s.statut === 'EN_COURS'"
                    [class.pastille--succes]="s.statut === 'TRAITE'">{{ statuts[s.statut] }}</span>
            </header>
            <p>{{ motifs[s.motif] }}@if (s.trajet) { · {{ s.trajet }} }</p>
            @if (s.description) {
              <p class="description">{{ s.description }}</p>
            }
            <small>Envoyé le {{ s.dateSignalement | date: 'd MMMM y' }}@if (s.dateTraitement) { · examiné le {{ s.dateTraitement | date: 'd MMMM y' }} }</small>
          </article>
        } @empty {
          <section class="carte bloc">
            <p>Vous n'avez fait aucun signalement. Vous pouvez signaler une personne depuis « Mes réservations » ou la liste des passagers d'un trajet.</p>
          </section>
        }
      }
    </div>
  `,
  styles: `
    .page {
      display: grid;
      gap: 12px;
      max-width: 640px;
      margin: 0 auto;
      padding: 16px;
    }
    article {
      display: grid;
      gap: 6px;
    }
    header {
      display: flex;
      align-items: center;
      justify-content: space-between;
      gap: 8px;
    }
    p {
      margin: 0;
    }
    .description {
      color: var(--texte-2);
    }
    small {
      color: var(--texte-3);
    }
  `,
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class MesSignalements implements OnInit {
  private readonly service = inject(SignalementsService);

  protected readonly motifs = LIBELLES_MOTIF;
  protected readonly statuts = LIBELLES_STATUT_SIGNALEMENT;
  protected readonly liste = signal<Signalement[] | null>(null);
  protected readonly erreur = signal<ErreurApi | null>(null);

  ngOnInit(): void {
    this.service.mes().subscribe({
      next: (l) => this.liste.set(l),
      error: (e) => this.erreur.set(lireErreur(e)),
    });
  }
}
