import { ChangeDetectionStrategy, Component, forwardRef, input, signal } from '@angular/core';
import { ControlValueAccessor, NG_VALUE_ACCESSOR } from '@angular/forms';
import { Icone, NomIcone } from './icone';

/** Saisie de mot de passe avec icône et bouton afficher/masquer. S'utilise avec formControlName. */
@Component({
  selector: 'app-champ-mot-de-passe',
  imports: [Icone],
  providers: [{ provide: NG_VALUE_ACCESSOR, useExisting: forwardRef(() => ChampMotDePasse), multi: true }],
  template: `
    <div class="saisie">
      <app-icone [nom]="icone()" />
      <input
        [id]="idChamp()"
        [type]="visible() ? 'text' : 'password'"
        [value]="valeur()"
        [attr.autocomplete]="autocomplete()"
        [attr.placeholder]="placeholder()"
        [attr.aria-describedby]="decritPar() || null"
        [disabled]="desactive()"
        (input)="saisir($event)"
        (blur)="toucher()"
      />
      <button
        type="button"
        class="saisie__action"
        [attr.aria-label]="visible() ? 'Masquer le mot de passe' : 'Afficher le mot de passe'"
        [attr.aria-pressed]="visible()"
        (click)="visible.set(!visible())"
      >
        <app-icone [nom]="visible() ? 'oeil-barre' : 'oeil'" />
      </button>
    </div>
  `,
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class ChampMotDePasse implements ControlValueAccessor {
  readonly idChamp = input.required<string>();
  readonly icone = input<NomIcone>('cadenas');
  readonly autocomplete = input('current-password');
  readonly placeholder = input('');
  readonly decritPar = input('');

  protected readonly visible = signal(false);
  protected readonly valeur = signal('');
  protected readonly desactive = signal(false);

  private onChange: (v: string) => void = () => {};
  private onTouched: () => void = () => {};

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

  protected saisir(e: Event): void {
    const v = (e.target as HTMLInputElement).value;
    this.valeur.set(v);
    this.onChange(v);
  }

  protected toucher(): void {
    this.onTouched();
  }
}
