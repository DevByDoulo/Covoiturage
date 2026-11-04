import { ChangeDetectionStrategy, Component, effect, inject, input, output, signal } from '@angular/core';
import { Geocodage, Lieu } from '../../../core/carte/geocodage';
import { PRECISION_APPROXIMATIVE_M, PositionActuelle } from '../../../core/carte/position-actuelle';
import { Icone } from '../../../shared/ui/icone';

/**
 * Saisie d'un lieu : on tape une adresse, on valide (Entrée ou loupe), on choisit une suggestion.
 * Pas d'appel à chaque frappe (règle d'usage du géocodage OpenStreetMap).
 * 08 — Avec `maPosition`, un bouton remplit le champ avec la position de l'appareil (adresse retrouvée).
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
        @if (maPosition()) {
          @if (localisation()) {
            <span class="chargement chargement--sombre" aria-label="Localisation en cours"></span>
          } @else {
            <button type="button" class="saisie__action saisie__action--position" (click)="localiser()"
                    aria-label="Utiliser ma position actuelle" title="Utiliser ma position actuelle">
              <app-icone nom="cible" />
            </button>
          }
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
      } @else if (erreur() || erreurPosition(); as e) {
        <p class="message-erreur">{{ e }}</p>
      } @else if (precisionApprox(); as m) {
        <p class="aide">Position approximative (à environ {{ m }} m près) : vérifiez l'adresse ou touchez la carte.</p>
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
    .saisie__action--position {
      color: var(--vert);
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
  private readonly position = inject(PositionActuelle);

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
  /** Propose « Ma position » (champ de départ). */
  readonly maPosition = input(false);

  readonly lieuChoisi = output<Lieu>();
  readonly activation = output<void>();
  readonly supprimer = output<void>();

  protected readonly texte = signal('');
  protected readonly suggestions = signal<Lieu[]>([]);
  protected readonly recherche = signal(false);
  protected readonly aucunResultat = signal(false);
  protected readonly localisation = signal(false);
  protected readonly erreurPosition = signal<string | null>(null);
  /** Précision en mètres quand la position est trop approximative pour être prise telle quelle. */
  protected readonly precisionApprox = signal<number | null>(null);

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
    this.erreurPosition.set(null);
    this.precisionApprox.set(null);
    this.geocodage.rechercher(q).subscribe((resultats) => {
      this.recherche.set(false);
      this.suggestions.set(resultats);
      this.aucunResultat.set(resultats.length === 0);
    });
  }

  /** Position de l'appareil, puis adresse correspondante (« Ma position » si elle est introuvable). */
  protected localiser(): void {
    this.localisation.set(true);
    this.erreurPosition.set(null);
    this.precisionApprox.set(null);
    this.suggestions.set([]);
    this.aucunResultat.set(false);
    this.position.localiser().subscribe({
      next: (p) => {
        this.geocodage.adresseDe(p.latitude, p.longitude).subscribe((adresse) => {
          this.localisation.set(false);
          this.precisionApprox.set(p.precisionM > PRECISION_APPROXIMATIVE_M ? p.precisionM : null);
          this.choisir({ libelle: adresse ?? 'Ma position', latitude: p.latitude, longitude: p.longitude });
        });
      },
      error: (e: Error) => {
        this.localisation.set(false);
        this.erreurPosition.set(e.message);
      },
    });
  }

  protected choisir(lieu: Lieu): void {
    this.suggestions.set([]);
    this.texte.set(lieu.libelle);
    this.lieuChoisi.emit(lieu);
  }
}
