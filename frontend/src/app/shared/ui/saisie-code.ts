import {
  ChangeDetectionStrategy,
  Component,
  ElementRef,
  computed,
  forwardRef,
  input,
  output,
  signal,
  viewChild,
} from '@angular/core';
import { ControlValueAccessor, NG_VALUE_ACCESSOR } from '@angular/forms';

/**
 * Saisie d'un code à N chiffres affiché en cases. Un seul <input> réel (invisible, posé sur les cases)
 * reçoit la frappe, le collage et le remplissage automatique du SMS (autocomplete="one-time-code").
 */
@Component({
  selector: 'app-saisie-code',
  providers: [{ provide: NG_VALUE_ACCESSOR, useExisting: forwardRef(() => SaisieCode), multi: true }],
  template: `
    <div class="cases" [class.cases--erreur]="erreur()" [style.--n]="longueur()" (click)="focus()">
      <input
        #champ
        [id]="idChamp()"
        class="cases__input"
        inputmode="numeric"
        autocomplete="one-time-code"
        [attr.maxlength]="longueur()"
        [attr.aria-label]="'Code à ' + longueur() + ' chiffres'"
        [value]="valeur()"
        [disabled]="desactive()"
        (input)="saisir($event)"
        (focus)="actif.set(true)"
        (blur)="actif.set(false); onTouched()"
      />
      @for (c of cases(); track $index) {
        <span
          class="case"
          [class.case--remplie]="c !== ''"
          [class.case--courante]="actif() && $index === indexCourant()"
          aria-hidden="true"
          >{{ c || '•' }}</span
        >
      }
    </div>
  `,
  styles: `
    :host {
      display: block;
    }
    .cases {
      position: relative;
      display: grid;
      grid-template-columns: repeat(var(--n), minmax(0, 1fr));
      gap: 8px;
      max-width: 352px;
      margin: 0 auto;
      width: 100%;
    }
    .cases__input {
      position: absolute;
      inset: 0;
      width: 100%;
      opacity: 0;
      font-size: 16px;
      caret-color: transparent;
    }
    .case {
      display: grid;
      place-items: center;
      height: 56px;
      border: 1.5px solid transparent;
      border-radius: 12px;
      background: var(--surface-2);
      font-size: 22px;
      font-weight: 700;
      color: #b6bfd1;
    }
    .case--remplie {
      background: var(--surface);
      box-shadow: var(--ombre);
      color: var(--texte);
    }
    .case--courante {
      border-color: var(--vert);
      background: var(--vert-clair);
      color: var(--vert);
    }
    .cases--erreur .case--remplie {
      border-color: rgba(192, 38, 45, 0.4);
    }
  `,
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class SaisieCode implements ControlValueAccessor {
  readonly idChamp = input('code');
  readonly longueur = input(6);
  readonly erreur = input(false);
  /** Émis quand tous les chiffres sont saisis. */
  readonly complet = output<string>();

  protected readonly valeur = signal('');
  protected readonly actif = signal(false);
  protected readonly desactive = signal(false);
  protected readonly cases = computed(() =>
    Array.from({ length: this.longueur() }, (_, i) => this.valeur()[i] ?? ''),
  );
  protected readonly indexCourant = computed(() => Math.min(this.valeur().length, this.longueur() - 1));

  private readonly champ = viewChild.required<ElementRef<HTMLInputElement>>('champ');
  private onChange: (v: string) => void = () => {};
  protected onTouched: () => void = () => {};

  writeValue(v: string | null): void {
    this.valeur.set(v ?? '');
  }
  registerOnChange(fn: (v: string) => void): void {
    this.onChange = fn;
  }
  registerOnTouched(fn: () => void): void {
    this.onTouched = fn;
  }
  setDisabledState(d: boolean): void {
    this.desactive.set(d);
  }

  focus(): void {
    this.champ().nativeElement.focus();
  }

  /** Touche du pavé numérique : un chiffre ou « effacer ». */
  appliquerTouche(touche: string): void {
    const v = this.valeur();
    if (touche === 'effacer') this.mettreAJour(v.slice(0, -1));
    else if (v.length < this.longueur()) this.mettreAJour(v + touche);
  }

  protected saisir(e: Event): void {
    const champ = e.target as HTMLInputElement;
    const chiffres = champ.value.replace(/\D/g, '').slice(0, this.longueur());
    champ.value = chiffres;
    this.mettreAJour(chiffres);
  }

  private mettreAJour(v: string): void {
    this.valeur.set(v);
    this.onChange(v);
    if (v.length === this.longueur()) this.complet.emit(v);
  }
}
