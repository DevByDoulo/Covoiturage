import { ChangeDetectionStrategy, Component, computed, inject, signal } from '@angular/core';
import { toSignal } from '@angular/core/rxjs-interop';
import { FormBuilder, ReactiveFormsModule, Validators } from '@angular/forms';
import { Router } from '@angular/router';
import { ErreurApi, lireErreur } from '../../../core/api/erreur-api';
import { SessionService } from '../../../core/auth/session.service';
import { Alerte } from '../../../shared/ui/alerte';
import { ChampMotDePasse } from '../../../shared/ui/champ-mot-de-passe';
import { compteARebours } from '../../../shared/ui/compte-a-rebours';
import { EntetePage } from '../../../shared/ui/entete-page';
import { ForceMotDePasse } from '../../../shared/ui/force-mot-de-passe';
import { Icone } from '../../../shared/ui/icone';
import { SaisieCode } from '../../../shared/ui/saisie-code';
import { REGLE_MOT_DE_PASSE, champsIdentiques, enErreur } from '../formulaire';

/** Deux étapes sur le même écran (maquette) : envoi du code, puis code + nouveau mot de passe. */
@Component({
  selector: 'app-mot-de-passe-oublie',
  imports: [ReactiveFormsModule, EntetePage, Icone, Alerte, ChampMotDePasse, SaisieCode, ForceMotDePasse],
  templateUrl: './mot-de-passe-oublie.html',
  styleUrls: ['../auth-commun.scss', './mot-de-passe-oublie.scss'],
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class MotDePasseOublie {
  private readonly session = inject(SessionService);
  private readonly router = inject(Router);
  private readonly fb = inject(FormBuilder);

  protected readonly contact = this.fb.nonNullable.control('', Validators.required);
  protected readonly form = this.fb.nonNullable.group(
    {
      code: ['', [Validators.required, Validators.pattern(/^\d{6}$/)]],
      motDePasse: ['', [Validators.required, Validators.pattern(REGLE_MOT_DE_PASSE)]],
      confirmation: ['', Validators.required],
    },
    { validators: champsIdentiques('motDePasse', 'confirmation') },
  );

  /** Identifiant pour lequel le code a été demandé (étape 2 active). */
  protected readonly identifiantEnvoye = signal<string | null>(null);
  private readonly renvoiPossibleA = signal<number | null>(null);
  protected readonly attenteRenvoi = compteARebours(this.renvoiPossibleA);

  protected readonly envoiCode = signal(false);
  protected readonly envoiReinit = signal(false);
  protected readonly erreurEtape1 = signal<ErreurApi | null>(null);
  protected readonly erreurEtape2 = signal<ErreurApi | null>(null);

  private readonly valeurContact = toSignal(this.contact.valueChanges, { initialValue: '' });
  /** Affiche l'indicatif +221 tant que la saisie ressemble à un numéro. */
  protected readonly ressembleATelephone = computed(() => !/[a-z@]/i.test(this.valeurContact()));
  protected readonly motDePasse = toSignal(this.form.controls.motDePasse.valueChanges, { initialValue: '' });
  protected readonly enErreur = (nom: string) => enErreur(this.form, nom);

  protected envoyerCode(): void {
    if (this.contact.invalid) {
      this.contact.markAsTouched();
      return;
    }
    const identifiant = this.contact.value.trim();
    this.envoiCode.set(true);
    this.erreurEtape1.set(null);
    this.session.motDePasseOublie(identifiant).subscribe({
      next: (r) => {
        this.identifiantEnvoye.set(identifiant);
        this.renvoiPossibleA.set(Date.now() + (r.renvoiPossibleDansSecondes ?? 60) * 1000);
        this.envoiCode.set(false);
      },
      error: (e) => {
        const err = lireErreur(e);
        // Délai de renvoi non écoulé : le code précédent reste valable, on passe quand même à l'étape 2.
        if (err.status === 429 && err.reessayerDansSecondes) {
          this.identifiantEnvoye.set(identifiant);
          this.renvoiPossibleA.set(Date.now() + err.reessayerDansSecondes * 1000);
        }
        this.erreurEtape1.set(err);
        this.envoiCode.set(false);
      },
    });
  }

  protected confirmationDifferente(): boolean {
    const c = this.form.controls.confirmation;
    return this.form.hasError('differents') && (c.touched || c.dirty);
  }

  protected reinitialiser(): void {
    const identifiant = this.identifiantEnvoye();
    if (!identifiant) return;
    if (this.form.invalid) {
      this.form.markAllAsTouched();
      return;
    }
    const { code, motDePasse } = this.form.getRawValue();
    this.envoiReinit.set(true);
    this.erreurEtape2.set(null);
    this.session.reinitialiserMotDePasse(identifiant, code, motDePasse).subscribe({
      next: () => this.router.navigate(['/auth/connexion'], { queryParams: { reinitialise: 1 } }),
      error: (e) => {
        this.erreurEtape2.set(lireErreur(e));
        this.envoiReinit.set(false);
      },
    });
  }
}
