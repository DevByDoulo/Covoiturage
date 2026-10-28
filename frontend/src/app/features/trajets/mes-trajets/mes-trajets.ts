import { ChangeDetectionStrategy, Component, OnInit, computed, inject, signal } from '@angular/core';
import { RouterLink } from '@angular/router';
import { ErreurApi, lireErreur } from '../../../core/api/erreur-api';
import { Alerte } from '../../../shared/ui/alerte';
import { Icone } from '../../../shared/ui/icone';
import { AvisADonnerBloc } from '../../avis/avis-a-donner';
import { CarteTrajet } from '../carte-trajet/carte-trajet';
import { StatutTrajet, Trajet } from '../trajets.models';
import { TrajetsService } from '../trajets.service';

const A_VENIR: StatutTrajet[] = ['PUBLIE', 'COMPLET', 'EN_COURS'];

/** F4 — Historique des trajets proposés par le conducteur. */
@Component({
  selector: 'app-mes-trajets',
  imports: [RouterLink, CarteTrajet, Icone, Alerte, AvisADonnerBloc],
  template: `
    <header class="entete">
      <h1>Mes trajets</h1>
      <a class="bouton bouton--primaire bouton--compact" routerLink="/trajets/publier">
        <app-icone nom="plus" [taille]="18" /> Publier
      </a>
    </header>

    <!-- 05 — passagers à noter après les trajets terminés -->
    <app-avis-a-donner />

    <div class="onglets" role="tablist" aria-label="Période">
      <button role="tab" type="button" [attr.aria-selected]="onglet() === 'avenir'" (click)="onglet.set('avenir')">
        À venir ({{ aVenir().length }})
      </button>
      <button role="tab" type="button" [attr.aria-selected]="onglet() === 'passes'" (click)="onglet.set('passes')">
        Passés ({{ passes().length }})
      </button>
    </div>

    @if (erreur(); as e) {
      <app-alerte type="erreur">{{ e.message }}</app-alerte>
    } @else if (chargement()) {
      <p class="vide"><span class="chargement chargement--sombre"></span> Chargement…</p>
    } @else {
      @let liste = onglet() === 'avenir' ? aVenir() : passes();
      @if (liste.length) {
        <div class="liste">
          @for (t of liste; track t.id) {
            <app-carte-trajet [trajet]="t" />
          }
        </div>
      } @else {
        <section class="carte vide">
          <app-icone nom="route" [taille]="32" />
          <p>{{ onglet() === 'avenir' ? 'Aucun trajet à venir.' : 'Aucun trajet passé pour le moment.' }}</p>
          @if (onglet() === 'avenir') {
            <a routerLink="/trajets/publier">Publier un trajet</a>
          }
        </section>
      }
    }
  `,
  styles: `
    .entete {
      display: flex;
      align-items: center;
      justify-content: space-between;
      gap: 12px;
      margin-bottom: 16px;
      h1 { font-size: 24px; }
    }
    .bouton--compact { width: auto; min-height: 42px; padding: 0 16px; font-size: 14.5px; }
    .onglets {
      display: inline-flex;
      gap: 4px;
      padding: 4px;
      margin-bottom: 16px;
      border-radius: 12px;
      background: var(--surface-2);
      button {
        padding: 8px 14px;
        border: 0;
        border-radius: 9px;
        background: none;
        font-weight: 600;
        color: var(--texte-2);
        cursor: pointer;
      }
      button[aria-selected='true'] { background: var(--surface); color: var(--vert); box-shadow: var(--ombre); }
    }
    .liste {
      display: grid;
      grid-template-columns: repeat(auto-fill, minmax(300px, 1fr));
      gap: 12px;
    }
    .vide { display: grid; justify-items: center; gap: 8px; color: var(--texte-3); text-align: center; }
  `,
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class MesTrajets implements OnInit {
  private readonly service = inject(TrajetsService);

  protected readonly trajets = signal<Trajet[]>([]);
  protected readonly chargement = signal(true);
  protected readonly erreur = signal<ErreurApi | null>(null);
  protected readonly onglet = signal<'avenir' | 'passes'>('avenir');

  /** À venir : du plus proche au plus lointain. Passés : du plus récent au plus ancien. */
  protected readonly aVenir = computed(() =>
    this.trajets()
      .filter((t) => A_VENIR.includes(t.statut))
      .sort((a, b) => a.dateHeureDepart.localeCompare(b.dateHeureDepart)),
  );
  protected readonly passes = computed(() => this.trajets().filter((t) => !A_VENIR.includes(t.statut)));

  ngOnInit(): void {
    this.service.mesTrajets().subscribe({
      next: (liste) => {
        this.trajets.set(liste);
        this.chargement.set(false);
      },
      error: (e) => {
        this.erreur.set(lireErreur(e));
        this.chargement.set(false);
      },
    });
  }
}
