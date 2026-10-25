import { ChangeDetectionStrategy, Component, input, output } from '@angular/core';
import { Icone } from './icone';

/** Pavé numérique à l'écran (maquette OTP). Émet un chiffre, ou « effacer ». */
@Component({
  selector: 'app-pave-numerique',
  imports: [Icone],
  template: `
    <div class="pave" role="group" aria-label="Pavé numérique">
      @for (t of touches; track t) {
        <button type="button" [disabled]="desactive()" (click)="touche.emit(t)">{{ t }}</button>
      }
      <span></span>
      <button type="button" [disabled]="desactive()" (click)="touche.emit('0')">0</button>
      <button type="button" aria-label="Effacer" [disabled]="desactive()" (click)="touche.emit('effacer')">
        <app-icone nom="effacer" />
      </button>
    </div>
  `,
  styles: `
    .pave {
      display: grid;
      grid-template-columns: repeat(3, 1fr);
      gap: 8px;
      padding: 8px;
      border-radius: 16px;
      background: var(--surface-2);
    }
    button {
      display: grid;
      place-items: center;
      height: 46px;
      border: 0;
      border-radius: 10px;
      background: var(--surface);
      font-size: 20px;
      font-weight: 600;
      color: var(--texte);
      cursor: pointer;
      &:active {
        background: var(--vert-clair);
      }
    }
  `,
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class PaveNumerique {
  readonly desactive = input(false);
  readonly touche = output<string>();
  protected readonly touches = ['1', '2', '3', '4', '5', '6', '7', '8', '9'];
}
