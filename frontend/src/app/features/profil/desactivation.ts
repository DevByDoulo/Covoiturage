import { ChangeDetectionStrategy, Component, computed, inject, signal } from '@angular/core';
import { FormBuilder, ReactiveFormsModule, Validators } from '@angular/forms';
import { Router } from '@angular/router';
import { ErreurApi, lireErreur } from '../../core/api/erreur-api';
import { SessionService } from '../../core/auth/session.service';
import { Alerte } from '../../shared/ui/alerte';
import { ChampMotDePasse } from '../../shared/ui/champ-mot-de-passe';
import { EntetePage } from '../../shared/ui/entete-page';
import { Icone } from '../../shared/ui/icone';
import { ProfilService } from './profil.service';

/** Désactivation du compte par son titulaire, confirmée par le mot de passe. Réversible en se reconnectant. */
@Component({
  selector: 'app-desactivation',
  imports: [ReactiveFormsModule, EntetePage, Alerte, ChampMotDePasse, Icone],
  template: `
    <div class="page">
      <app-entete-page titre="Désactiver mon compte" retour="/profil" />

      <form class="carte formulaire" [formGroup]="form" (ngSubmit)="desactiver()" novalidate>
        <app-alerte type="avertissement" titre="Que se passe-t-il ?">
          Votre profil n'est plus visible et vous êtes déconnecté de tous vos appareils. Vos données sont conservées :
          il suffit de vous reconnecter pour réactiver votre compte.
        </app-alerte>

        @if (aUnMotDePasse()) {
          <div class="champ" [class.champ--erreur]="erreur()?.champ === 'motDePasse'">
            <label class="libelle" for="mdp">Confirmez avec votre mot de passe</label>
            <app-champ-mot-de-passe idChamp="mdp" formControlName="motDePasse" autocomplete="current-password" />
          </div>
        }

        <label class="case">
          <input type="checkbox" formControlName="compris" />
          <span>Je comprends que mon compte sera désactivé.</span>
        </label>

        @if (erreur(); as e) {
          <app-alerte type="erreur">{{ e.message }}</app-alerte>
        }

        <button class="bouton danger" type="submit" [disabled]="form.invalid || envoi()">
          @if (envoi()) {
            <span class="chargement" aria-hidden="true"></span>
          } @else {
            <app-icone nom="utilisateur-barre" [taille]="18" />
          }
          Désactiver mon compte
        </button>
      </form>
    </div>
  `,
  styles: `
    .page {
      display: flex;
      flex-direction: column;
      gap: 12px;
      max-width: 520px;
      margin: 0 auto;
    }
    .danger {
      background: var(--erreur);
      color: #fff;
    }
  `,
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class Desactivation {
  private readonly profils = inject(ProfilService);
  private readonly session = inject(SessionService);
  private readonly router = inject(Router);
  private readonly fb = inject(FormBuilder);

  protected readonly aUnMotDePasse = computed(() => this.session.utilisateur()?.motDePasseDefini ?? true);
  protected readonly form = this.fb.nonNullable.group({
    motDePasse: [''],
    compris: [false, Validators.requiredTrue],
  });
  protected readonly envoi = signal(false);
  protected readonly erreur = signal<ErreurApi | null>(null);

  constructor() {
    if (this.aUnMotDePasse()) this.form.controls.motDePasse.addValidators(Validators.required);
  }

  protected desactiver(): void {
    if (this.form.invalid) return;
    this.envoi.set(true);
    this.erreur.set(null);
    this.profils.desactiver(this.aUnMotDePasse() ? this.form.controls.motDePasse.value : null).subscribe({
      next: () => this.router.navigate(['/auth/connexion'], { queryParams: { desactive: 1 } }),
      error: (e) => {
        this.erreur.set(lireErreur(e));
        this.envoi.set(false);
      },
    });
  }
}
