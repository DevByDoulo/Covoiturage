import { ChangeDetectionStrategy, Component, inject, signal } from '@angular/core';
import { toSignal } from '@angular/core/rxjs-interop';
import { FormBuilder, ReactiveFormsModule, Validators } from '@angular/forms';
import { Router, RouterLink } from '@angular/router';
import { ErreurApi, lireErreur } from '../../../core/api/erreur-api';
import { Sexe } from '../../../core/auth/auth.models';
import { SessionService } from '../../../core/auth/session.service';
import { Alerte } from '../../../shared/ui/alerte';
import { BoutonGoogle } from '../../../shared/ui/bouton-google';
import { ChampMotDePasse } from '../../../shared/ui/champ-mot-de-passe';
import { DrapeauSenegal } from '../../../shared/ui/drapeau-senegal';
import { Icone } from '../../../shared/ui/icone';
import { Logo } from '../../../shared/ui/logo';
import {
  REGLE_MOT_DE_PASSE,
  appliquerErreurServeur,
  champsIdentiques,
  chiffresTelephone,
  enErreur,
  telephoneSenegalValidator,
} from '../formulaire';

@Component({
  selector: 'app-inscription',
  imports: [ReactiveFormsModule, RouterLink, Logo, Icone, Alerte, ChampMotDePasse, BoutonGoogle, DrapeauSenegal],
  templateUrl: './inscription.html',
  styleUrl: '../auth-commun.scss',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class Inscription {
  private readonly session = inject(SessionService);
  private readonly router = inject(Router);
  private readonly fb = inject(FormBuilder);

  protected readonly form = this.fb.nonNullable.group(
    {
      prenom: ['', [Validators.required, Validators.maxLength(80)]],
      nom: ['', [Validators.required, Validators.maxLength(80)]],
      email: ['', [Validators.required, Validators.email, Validators.maxLength(160)]],
      telephone: ['', [Validators.required, telephoneSenegalValidator]],
      sexe: this.fb.control<Sexe | null>(null, Validators.required),
      motDePasse: ['', [Validators.required, Validators.pattern(REGLE_MOT_DE_PASSE)]],
      confirmation: ['', Validators.required],
      cgu: [false, Validators.requiredTrue],
    },
    { validators: champsIdentiques('motDePasse', 'confirmation') },
  );

  protected readonly sexe = toSignal(this.form.controls.sexe.valueChanges, { initialValue: null });
  protected readonly envoi = signal(false);
  protected readonly erreur = signal<ErreurApi | null>(null);
  protected readonly googleIndisponible = signal(false);
  protected readonly enErreur = (nom: string) => enErreur(this.form, nom);

  protected confirmationDifferente(): boolean {
    const c = this.form.controls.confirmation;
    return this.form.hasError('differents') && (c.touched || c.dirty);
  }

  protected choisirSexe(s: Sexe): void {
    this.form.controls.sexe.setValue(s);
    this.form.controls.sexe.markAsTouched();
  }

  protected soumettre(): void {
    if (this.form.invalid) {
      this.form.markAllAsTouched();
      return;
    }
    const v = this.form.getRawValue();
    this.envoi.set(true);
    this.erreur.set(null);
    this.session
      .inscription({
        prenom: v.prenom.trim(),
        nom: v.nom.trim(),
        email: v.email.trim(),
        telephone: '+221' + chiffresTelephone(v.telephone),
        motDePasse: v.motDePasse,
        sexe: v.sexe,
      })
      .subscribe({
        next: () => this.router.navigateByUrl('/auth/verification'),
        error: (e) => {
          const err = lireErreur(e);
          if (!appliquerErreurServeur(this.form, err)) this.erreur.set(err);
          this.envoi.set(false);
        },
      });
  }

  protected google(idToken: string): void {
    this.session.connexionGoogle(idToken).subscribe({
      next: (r) =>
        this.router.navigateByUrl(
          r.etape === 'TELEPHONE_REQUIS'
            ? '/auth/google/telephone'
            : r.etape === 'OTP_ENVOYE'
              ? '/auth/verification'
              : this.session.pageAccueil(),
        ),
      error: (e) => this.erreur.set(lireErreur(e)),
    });
  }

  /** Message d'erreur du serveur (ex. « Cet email est déjà utilisé ») s'il y en a un sur ce champ. */
  protected erreurServeur(nom: string): string | null {
    return (this.form.get(nom)?.errors?.['serveur'] as string | undefined) ?? null;
  }
}
