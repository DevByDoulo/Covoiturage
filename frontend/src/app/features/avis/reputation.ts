import { DatePipe } from '@angular/common';
import { ChangeDetectionStrategy, Component, OnInit, inject, input, signal } from '@angular/core';
import { Reputation, pourcentage } from './avis.models';
import { AvisService } from './avis.service';
import { Etoiles } from './etoiles';

/** 05 — Réputation d'une personne : moyenne, répartition des notes et derniers avis reçus. */
@Component({
  selector: 'app-reputation',
  imports: [DatePipe, Etoiles],
  template: `
    @if (reputation(); as r) {
      <section class="carte bloc" aria-labelledby="titre-reputation">
        <h2 id="titre-reputation">{{ titre() }}</h2>
        @if (r.nombreAvis === 0) {
          <p class="aide">Pas encore d'avis.</p>
        } @else {
          <div class="synthese">
            <strong class="moyenne">{{ r.noteMoyenne?.toFixed(1)?.replace('.', ',') }}</strong>
            <div>
              <app-etoiles [note]="r.noteMoyenne" />
              <small>{{ r.nombreAvis }} avis</small>
            </div>
          </div>
          <ul class="repartition" aria-label="Répartition des notes">
            @for (n of [5, 4, 3, 2, 1]; track n) {
              <li>
                <span>{{ n }} ★</span>
                <span class="barre"><span [style.width.%]="part(r, n)"></span></span>
                <span>{{ r.repartition[n - 1] }}</span>
              </li>
            }
          </ul>
          <ul class="avis">
            @for (a of r.avis; track a.id) {
              <li>
                <div class="ligne">
                  <app-etoiles [note]="a.note" />
                  <small>{{ a.auteur.prenom }} {{ a.auteur.nomInitiale }} · {{ a.roleEvalue === 'CONDUCTEUR' ? 'passager' : 'conducteur' }}
                    · {{ a.dateEvaluation | date: 'd MMM y' }}</small>
                </div>
                @if (a.commentaire) { <p>{{ a.commentaire }}</p> }
              </li>
            }
          </ul>
        }
      </section>
    }
  `,
  styles: `
    .synthese {
      display: flex;
      align-items: center;
      gap: 12px;
      margin-bottom: 12px;
    }
    .synthese div {
      display: grid;
      gap: 2px;
    }
    .moyenne {
      font-size: 36px;
    }
    small,
    .aide {
      color: var(--texte-2);
    }
    ul {
      margin: 0;
      padding: 0;
      list-style: none;
    }
    .repartition li {
      display: grid;
      grid-template-columns: 34px 1fr 28px;
      align-items: center;
      gap: 8px;
      font-size: 13px;
    }
    .barre {
      height: 6px;
      border-radius: 3px;
      background: var(--surface-2);
      overflow: hidden;
    }
    .barre span {
      display: block;
      height: 100%;
      background: var(--orange);
    }
    .avis li {
      padding: 10px 0;
      border-top: 1px solid var(--bord);
    }
    .avis li:first-child {
      margin-top: 12px;
    }
    .ligne {
      display: flex;
      flex-wrap: wrap;
      align-items: center;
      gap: 8px;
    }
    .avis p {
      margin: 6px 0 0;
    }
  `,
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class ReputationBloc implements OnInit {
  private readonly service = inject(AvisService);

  readonly idUtilisateur = input.required<number>();
  readonly titre = input('Avis');

  protected readonly reputation = signal<Reputation | null>(null);
  protected readonly part = pourcentage;

  ngOnInit(): void {
    this.service.reputation(this.idUtilisateur()).subscribe({ next: (r) => this.reputation.set(r), error: () => undefined });
  }
}
