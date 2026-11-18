import { ChangeDetectionStrategy, Component, input, model, output } from '@angular/core';
import { Lieu } from '../../core/carte/geocodage';
import { Icone } from '../../shared/ui/icone';
import { ChampLieu } from '../trajets/champ-lieu/champ-lieu';
import { aujourdhui } from './parametres-recherche';

/**
 * Barre de recherche d'un trajet : départ, arrivée, date, passagers et bouton « Rechercher ». Les valeurs vivent chez
 * le parent (liaison à double sens) ; les filtres éventuels se glissent entre les passagers et le bouton.
 * Utilisée par la page Rechercher (colonne) et par l'accueil public (ligne en grand écran).
 */
@Component({
  selector: 'app-barre-recherche',
  imports: [ChampLieu, Icone],
  template: `
    <form class="barre" [class.barre--ligne]="disposition() === 'ligne'" role="search" [attr.aria-label]="libelleAria()"
          novalidate (submit)="$event.preventDefault(); lancer.emit()">
      <app-champ-lieu class="depart" [idChamp]="prefixe() + '-depart'" libelle="Départ" type="depart" etiquette="A"
                      [lieu]="depart()" [maPosition]="true" [actif]="champActif() === 'depart'"
                      (activation)="champActif.set('depart')" (lieuChoisi)="choisir('depart', $event)" />
      <app-champ-lieu class="arrivee" [idChamp]="prefixe() + '-arrivee'" libelle="Arrivée" type="arrivee" etiquette="B"
                      [lieu]="arrivee()" [actif]="champActif() === 'arrivee'"
                      (activation)="champActif.set('arrivee')" (lieuChoisi)="choisir('arrivee', $event)" />
      <button type="button" class="bouton-lien inverser" (click)="inverser()" [disabled]="!depart() && !arrivee()"
              aria-label="Inverser départ et arrivée">
        <app-icone nom="rafraichir" [taille]="16" /> <span>Inverser départ et arrivée</span>
      </button>

      <div class="champ date">
        <label class="libelle" [for]="prefixe() + '-date'">Date</label>
        <div class="saisie">
          <input [id]="prefixe() + '-date'" type="date" [value]="date()" [min]="aujourdhui"
                 (input)="date.set($any($event.target).value)" />
        </div>
      </div>
      <div class="champ passagers">
        <span class="libelle" [id]="prefixe() + '-places'">Passagers</span>
        <div class="compteur" role="group" [attr.aria-labelledby]="prefixe() + '-places'">
          <button type="button" (click)="changerPassagers(-1)" aria-label="Un passager de moins">−</button>
          <output>{{ passagers() }}</output>
          <button type="button" (click)="changerPassagers(1)" aria-label="Un passager de plus">+</button>
        </div>
      </div>

      <div class="projete"><ng-content /></div>

      <button type="submit" class="bouton bouton--primaire envoi"><app-icone nom="recherche" /> {{ libelleBouton() }}</button>
    </form>
    @if (erreur(); as e) {
      <p class="message-erreur" role="alert">{{ e }}</p>
    }
  `,
  styles: `
    :host { display: block; }
    .barre { display: flex; flex-wrap: wrap; gap: 14px; }
    .barre > * { flex: 1 1 100%; min-width: 0; }
    .barre > .date, .barre > .passagers { flex: 1 1 calc(50% - 7px); }
    .barre > .inverser { flex: 0 0 auto; align-self: flex-start; margin-top: -8px; }
    .projete:empty { display: none; }
    .message-erreur { margin-top: 10px; }
    .compteur {
      display: flex;
      align-items: center;
      justify-content: space-between;
      height: 50px;
      padding: 0 6px;
      border-radius: var(--rayon);
      background: var(--surface);
      box-shadow: var(--ombre);
      button {
        width: 36px;
        height: 36px;
        border: 0;
        border-radius: 10px;
        background: var(--surface-2);
        font-size: 20px;
        cursor: pointer;
      }
      output { font-size: 18px; font-weight: 700; }
    }
    @media (min-width: 960px) {
      .barre--ligne { flex-wrap: nowrap; align-items: flex-end; gap: 10px; }
      .barre--ligne > .depart { order: 1; flex: 1 1 0; }
      .barre--ligne > .inverser { order: 2; align-self: flex-end; margin: 0 0 8px; span { display: none; } }
      .barre--ligne > .arrivee { order: 3; flex: 1 1 0; }
      .barre--ligne > .date { order: 4; flex: 0 0 170px; }
      .barre--ligne > .passagers { order: 5; flex: 0 0 140px; }
      .barre--ligne > .envoi { order: 6; flex: 0 0 auto; width: auto; }
    }
  `,
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class BarreRecherche {
  readonly depart = model<Lieu | null>(null);
  readonly arrivee = model<Lieu | null>(null);
  readonly champActif = model<'depart' | 'arrivee'>('depart');
  readonly date = model<string>(aujourdhui());
  readonly passagers = model(1);

  /** Préfixe des identifiants de champs (deux barres sur une même page ne doivent pas se confondre). */
  readonly prefixe = input('r');
  readonly erreur = input<string | null>(null);
  readonly libelleBouton = input('Rechercher');
  readonly libelleAria = input('Critères de recherche');
  readonly disposition = input<'colonne' | 'ligne'>('colonne');

  /** Formulaire validé (bouton ou touche Entrée) : le parent lance la recherche. */
  readonly lancer = output<void>();

  protected readonly aujourdhui = aujourdhui();

  protected choisir(cle: 'depart' | 'arrivee', lieu: Lieu): void {
    (cle === 'depart' ? this.depart : this.arrivee).set(lieu);
    if (cle === 'depart' && !this.arrivee()) this.champActif.set('arrivee');
  }

  protected inverser(): void {
    const d = this.depart();
    this.depart.set(this.arrivee());
    this.arrivee.set(d);
  }

  protected changerPassagers(delta: number): void {
    const n = this.passagers() + delta;
    if (n >= 1 && n <= 8) this.passagers.set(n);
  }
}
