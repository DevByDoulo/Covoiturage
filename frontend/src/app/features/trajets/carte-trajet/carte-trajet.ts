import { DatePipe } from '@angular/common';
import { ChangeDetectionStrategy, Component, input } from '@angular/core';
import { RouterLink } from '@angular/router';
import { FcfaPipe } from '../../../shared/format/formats';
import { Icone } from '../../../shared/ui/icone';
import { LIBELLES_STATUT, Trajet } from '../trajets.models';

/** Résumé cliquable d'un trajet (listes « Mes trajets », résultats de recherche). */
@Component({
  selector: 'app-carte-trajet',
  imports: [RouterLink, DatePipe, FcfaPipe, Icone],
  template: `
    @let t = trajet();
    <a class="carte trajet" [routerLink]="['/trajets', t.id]">
      <div class="trajet__haut">
        <time [attr.datetime]="t.dateHeureDepart">
          <strong>{{ t.dateHeureDepart | date: 'HH:mm' }}</strong>
          <span>{{ t.dateHeureDepart | date: 'EEE d MMM' }}</span>
        </time>
        <span class="statut" [attr.data-statut]="t.statut">{{ libellesStatut[t.statut] }}</span>
      </div>

      <ol class="trajet__lieux">
        <li><span class="puce puce--depart"></span>{{ t.depart.lieu }}</li>
        @if (t.escales.length) {
          <li class="escales">{{ t.escales.length }} escale{{ t.escales.length > 1 ? 's' : '' }}</li>
        }
        <li><span class="puce puce--arrivee"></span>{{ t.arrivee.lieu }}</li>
      </ol>

      <div class="trajet__bas">
        <span><app-icone nom="utilisateurs" [taille]="16" /> {{ t.nombrePlacesDisponibles }}/{{ t.nombrePlacesTotal }} places</span>
        @if (t.femmesUniquement) {
          <span class="femmes">Femmes uniquement</span>
        }
        <strong class="prix">{{ t.prixParPlace | fcfa }}</strong>
      </div>
    </a>
  `,
  styles: `
    .trajet {
      display: flex;
      flex-direction: column;
      gap: 10px;
      color: var(--texte);
      font-weight: 400;
      &:hover { text-decoration: none; box-shadow: 0 0 0 2px var(--vert-clair), var(--ombre); }
    }
    .trajet__haut, .trajet__bas {
      display: flex;
      align-items: center;
      justify-content: space-between;
      gap: 8px;
    }
    time { display: flex; align-items: baseline; gap: 8px; }
    time strong { font-size: 20px; }
    time span { color: var(--texte-3); text-transform: capitalize; }
    .statut {
      padding: 3px 10px;
      border-radius: 999px;
      background: var(--vert-clair);
      font-size: 12px;
      font-weight: 700;
      color: var(--vert-fonce);
    }
    .statut[data-statut='COMPLET'] { background: var(--info-fond); color: var(--info); }
    .statut[data-statut='EN_COURS'] { background: var(--orange-clair); color: var(--orange-fonce); }
    .statut[data-statut='TERMINE'] { background: var(--surface-2); color: var(--texte-2); }
    .statut[data-statut='ANNULE'] { background: var(--erreur-fond); color: var(--erreur); }
    .trajet__lieux {
      display: grid;
      gap: 4px;
      margin: 0;
      padding: 0;
      list-style: none;
      font-weight: 600;
    }
    .trajet__lieux li { display: flex; align-items: center; gap: 8px; min-width: 0; }
    .escales { padding-left: 18px; font-size: 12.5px; font-weight: 400; color: var(--texte-3); }
    .puce { flex: none; width: 10px; height: 10px; border-radius: 50%; }
    .puce--depart { background: var(--vert); }
    .puce--arrivee { background: var(--erreur); }
    .trajet__bas { color: var(--texte-2); font-size: 13.5px; }
    .trajet__bas span { display: inline-flex; align-items: center; gap: 4px; }
    .femmes { color: #a0306a; font-weight: 600; }
    .prix { margin-left: auto; font-size: 17px; color: var(--vert-fonce); }
  `,
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class CarteTrajet {
  readonly trajet = input.required<Trajet>();
  protected readonly libellesStatut = LIBELLES_STATUT;
}
