import { ChangeDetectionStrategy, Component, computed, inject, signal } from '@angular/core';
import { FormBuilder, ReactiveFormsModule, Validators } from '@angular/forms';
import { Router } from '@angular/router';
import { ErreurApi, lireErreur } from '../../core/api/erreur-api';
import { SessionService } from '../../core/auth/session.service';
import { Alerte } from '../../shared/ui/alerte';
import { ChampMotDePasse } from '../../shared/ui/champ-mot-de-passe';
import { EntetePage } from '../../shared/ui/entete-page';
import { Icone } from '../../shared/ui/icone';
import { SaisieCode } from '../../shared/ui/saisie-code';
import { ProfilService } from './profil.service';

/**
 * Suppression du compte (droit à l'effacement), confirmée par le mot de passe ou, pour un compte créé avec Google,
 * par un code reçu par email ou SMS. Délai de grâce de 30 jours : se reconnecter annule la suppression.
 */
@Component({
  selector: 'app-suppression-compte',
  imports: [ReactiveFormsModule, EntetePage, Alerte, ChampMotDePasse, SaisieCode, Icone],
  template: `
    <div class="page">
      <app-entete-page titre="Supprimer mon compte" retour="/profil" />

      <form class="carte formulaire" [formGroup]="form" (ngSubmit)="supprimer()" novalidate>
        <app-alerte type="avertissement" titre="Ce qui va se passer">
          Votre compte est immédiatement invisible et vous êtes déconnecté de tous vos appareils. Pendant
          30 jours, il vous suffit de vous reconnecter pour annuler la suppression. Passé ce délai, vos données
          personnelles (nom, email, téléphone, photo, documents, alertes) sont définitivement effacées. Les paiements
          et les trajets passés sont conservés sans lien avec votre identité, comme la loi l'exige.
        </app-alerte>

        @if (aUnMotDePasse()) {
          <div class="champ" [class.champ--erreur]="erreur()?.champ === 'motDePasse'">
            <label class="libelle" for="mdp">Confirmez avec votre mot de passe</label>
            <app-champ-mot-de-passe idChamp="mdp" formControlName="motDePasse" autocomplete="current-password" />
          </div>
        } @else {
          <div class="champ" [class.champ--erreur]="erreur()?.champ === 'code'">
            <span class="libelle">Confirmez avec un code</span>
            @if (codeEnvoye()) {
              <app-saisie-code formControlName="code" [erreur]="erreur()?.champ === 'code'" />
              <button class="lien" type="button" (click)="envoyerCode()" [disabled]="envoiCode()">Renvoyer le code</button>
            } @else {
              <button class="bouton" type="button" (click)="envoyerCode()" [disabled]="envoiCode()">
                Recevoir un code de confirmation
              </button>
            }
          </div>
        }

        <label class="case">
          <input type="checkbox" formControlName="compris" />
          <span>Je comprends que mon compte sera supprimé définitivement dans 30 jours.</span>
        </label>

        @if (erreur(); as e) {
          <app-alerte type="erreur" [titre]="e.status === 409 ? 'Suppression impossible pour le moment' : ''">{{ e.message }}</app-alerte>
        }

        <button class="bouton danger" type="submit" [disabled]="form.invalid || envoi()">
          @if (envoi()) {
            <span class="chargement" aria-hidden="true"></span>
          } @else {
            <app-icone nom="poubelle" [taille]="18" />
          }
          Supprimer mon compte
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
export class SuppressionCompte {
  private readonly profils = inject(ProfilService);
  private readonly session = inject(SessionService);
  private readonly router = inject(Router);
  private readonly fb = inject(FormBuilder);

  protected readonly aUnMotDePasse = computed(() => this.session.utilisateur()?.motDePasseDefini ?? true);
  protected readonly form = this.fb.nonNullable.group({
    motDePasse: [''],
    code: [''],
    compris: [false, Validators.requiredTrue],
  });
  protected readonly envoi = signal(false);
  protected readonly envoiCode = signal(false);
  protected readonly codeEnvoye = signal(false);
  protected readonly erreur = signal<ErreurApi | null>(null);

  constructor() {
    if (this.aUnMotDePasse()) this.form.controls.motDePasse.addValidators(Validators.required);
    else this.form.controls.code.addValidators(Validators.pattern(/^\d{6}$/));
  }

  protected envoyerCode(): void {
    this.envoiCode.set(true);
    this.erreur.set(null);
    this.profils.envoyerCodeSuppression().subscribe({
      next: () => {
        this.codeEnvoye.set(true);
        this.envoiCode.set(false);
      },
      error: (e) => {
        this.erreur.set(lireErreur(e));
        this.envoiCode.set(false);
      },
    });
  }

  protected supprimer(): void {
    const { motDePasse, code } = this.form.getRawValue();
    if (this.form.invalid || (!this.aUnMotDePasse() && code.length !== 6)) return;
    this.envoi.set(true);
    this.erreur.set(null);
    this.profils.supprimerCompte(this.aUnMotDePasse() ? motDePasse : null, this.aUnMotDePasse() ? null : code).subscribe({
      next: () => this.router.navigate(['/auth/connexion'], { queryParams: { suppression: 1 } }),
      error: (e) => {
        this.erreur.set(lireErreur(e));
        this.envoi.set(false);
      },
    });
  }
}
