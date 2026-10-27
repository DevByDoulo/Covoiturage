import { ChangeDetectionStrategy, Component, effect, inject, input, output, signal } from '@angular/core';
import { Geocodage, Lieu } from '../../../core/carte/geocodage';
import { Icone } from '../../../shared/ui/icone';

/**
 * Saisie d'un lieu : on tape une adresse, on valide (Entrée ou loupe), on choisit une suggestion.
 * Pas d'appel à chaque frappe (règle d'usage du géocodage OpenStreetMap).
 */
@Component({
  selector: 'app-champ-lieu',
  imports: [Icone],
  template: `
    <div class="champ" [class.champ--erreur]="erreur()">
      <label class="libelle" [for]="idChamp()">{{ libelle() }}</label>
      <div class="saisie" [class.saisie--actif]="actif()">
        <span class="puce" [class]="'puce puce--' + type()">{{ etiquette() }}</span>
        <input
          [id]="idChamp()"
          [value]="texte()"
          [placeholder]="placeholder()"
          autocomplete="off"
          (input)="texte.set($any($event.target).value)"
          (keydown.enter)="$event.preventDefault(); chercher()"
          (focus)="activation.emit()"
          [attr.aria-expanded]="suggestions().length > 0"
          [attr.aria-controls]="idChamp() + '-suggestions'"
        />
        @if (recherche()) {
          <span class="chargement chargement--sombre" aria-label="Recherche en cours"></span>
        } @else {
          <button type="button" class="saisie__action" (click)="chercher()" aria-label="Rechercher ce lieu">
            <app-icone nom="recherche" />
          </button>
        }
        @if (supprimable()) {
          <button type="button" class="saisie__action" (click)="supprimer.emit()" aria-label="Retirer cette escale">
            <app-icone nom="croix" />
          </button>
        }
      </div>

      @if (suggestions().length) {
        <ul class="suggestions" [id]="idChamp() + '-suggestions'" role="listbox">
          @for (s of suggestions(); track $index) {
            <li role="option" aria-selected="false">
              <button type="button" (click)="choisir(s)">
                <strong>{{ s.libelle }}</strong>
                @if (s.detail) {
                  <small>{{ s.detail }}</small>
                }
              </button>
            </li>
          }
        </ul>
      } @else if (aucunResultat()) {
        <p class="aide">Aucun lieu trouvé. Précisez (quartier, ville) ou touchez la carte.</p>
      } @else if (erreur()) {
        <p class="message-erreur">{{ erreur() }}</p>
      }
    </div>
  `,
  styles: `
    .champ {
      position: relative;
    }
    .saisie--actif {
      border-color: var(--vert);
    }
    .puce {
      display: grid;
      place-items: center;
      flex: none;
      width: 22px;
      height: 22px;
      border-radius: 50%;
      font-size: 11px;
      font-weight: 800;
      color: #fff;
    }
    .puce--depart { background: var(--vert); }
    .puce--arrivee { background: var(--erreur); }
    .puce--escale { background: var(--orange); }
    .suggestions {
      position: absolute;
      inset: calc(100% + 4px) 0 auto;
      z-index: 20;
      max-height: 280px;
      overflow: auto;
      margin: 0;
      padding: 6px;
      list-style: none;
      background: var(--surface);
      border-radius: 14px;
      box-shadow: 0 10px 30px rgba(17, 24, 39, 0.15);
    }
    .suggestions button {
      display: flex;
      flex-direction: column;
      width: 100%;
      padding: 10px;
      border: 0;
      border-radius: 10px;
      background: none;
      text-align: left;
      cursor: pointer;
      &:hover {
        background: var(--surface-2);
      }
      small {
        color: var(--texte-3);
      }
    }
  `,
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class ChampLieu {
  private readonly geocodage = inject(Geocodage);

  readonly idChamp = input.required<string>();
  readonly libelle = input.required<string>();
  readonly type = input<'depart' | 'arrivee' | 'escale'>('depart');
  readonly etiquette = input('');
  readonly placeholder = input('Adresse, quartier, ville…');
  /** Lieu actuellement choisi (affiché dans le champ). */
  readonly lieu = input<Lieu | null>(null);
  readonly actif = input(false);
  readonly supprimable = input(false);
  readonly erreur = input<string | null>(null);

  readonly lieuChoisi = output<Lieu>();
  readonly activation = output<void>();
  readonly supprimer = output<void>();

  protected readonly texte = signal('');
  protected readonly suggestions = signal<Lieu[]>([]);
  protected readonly recherche = signal(false);
  protected readonly aucunResultat = signal(false);

  constructor() {
    // Un lieu fixé de l'extérieur (clic sur la carte) remplace le texte saisi.
    effect(() => {
      const lieu = this.lieu();
      if (lieu) this.texte.set(lieu.libelle);
    });
  }

  protected chercher(): void {
    const q = this.texte().trim();
    if (q.length < 2 || this.recherche()) return;
    this.recherche.set(true);
    this.aucunResultat.set(false);
    this.geocodage.rechercher(q).subscribe((resultats) => {
      this.recherche.set(false);
      this.suggestions.set(resultats);
      this.aucunResultat.set(resultats.length === 0);
    });
  }

  protected choisir(lieu: Lieu): void {
    this.suggestions.set([]);
    this.texte.set(lieu.libelle);
    this.lieuChoisi.emit(lieu);
  }
}
