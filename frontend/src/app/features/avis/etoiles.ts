import { ChangeDetectionStrategy, Component, computed, input, model } from '@angular/core';
import { LIBELLES_NOTE } from './avis.models';

/**
 * Note sur 5 étoiles. Lecture seule par défaut (étoiles arrondies à l'unité, valeur exacte lue par les lecteurs
 * d'écran) ; avec [modifiable]="true", groupe de boutons radio pour choisir une note.
 */
@Component({
  selector: 'app-etoiles',
  template: `
    @if (modifiable()) {
      <div class="etoiles etoiles--choix" role="radiogroup" [attr.aria-label]="libelle()">
        @for (n of valeurs; track n) {
          <button type="button" role="radio" [attr.aria-checked]="note() === n" [attr.aria-label]="n + ' sur 5 : ' + libelles[n]"
                  [class.pleine]="n <= (note() ?? 0)" (click)="note.set(n)">★</button>
        }
        @if (note(); as n) { <span class="texte">{{ libelles[n] }}</span> }
      </div>
    } @else {
      <span class="etoiles" role="img" [attr.aria-label]="resume()">
        @for (n of valeurs; track n) {
          <span aria-hidden="true" [class.pleine]="n <= arrondi()">★</span>
        }
      </span>
    }
  `,
  styles: `
    .etoiles {
      display: inline-flex;
      align-items: center;
      gap: 2px;
      color: var(--bord);
      line-height: 1;
    }
    .pleine {
      color: var(--orange);
    }
    .etoiles--choix button {
      padding: 2px;
      border: 0;
      background: none;
      font-size: 30px;
      color: var(--bord);
      cursor: pointer;
    }
    .etoiles--choix button.pleine {
      color: var(--orange);
    }
    .texte {
      margin-left: 8px;
      color: var(--texte-2);
      font-size: 14px;
    }
  `,
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class Etoiles {
  readonly note = model<number | null>(null);
  readonly modifiable = input(false);
  readonly libelle = input('Votre note');

  protected readonly valeurs = [1, 2, 3, 4, 5];
  protected readonly libelles = LIBELLES_NOTE;
  protected readonly arrondi = computed(() => Math.round(this.note() ?? 0));
  protected readonly resume = computed(() =>
    this.note() == null ? 'Pas encore noté' : `${this.note()!.toFixed(1).replace('.', ',')} sur 5`,
  );
}
