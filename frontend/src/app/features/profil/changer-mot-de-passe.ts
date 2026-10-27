import { ChangeDetectionStrategy, Component, computed, inject, signal } from '@angular/core';
import { toSignal } from '@angular/core/rxjs-interop';
import { FormBuilder, ReactiveFormsModule, Validators } from '@angular/forms';
import { RouterLink } from '@angular/router';
import { ErreurApi, lireErreur } from '../../core/api/erreur-api';
import { SessionService } from '../../core/auth/session.service';
import { Alerte } from '../../shared/ui/alerte';
import { ChampMotDePasse } from '../../shared/ui/champ-mot-de-passe';
import { EntetePage } from '../../shared/ui/entete-page';
import { ForceMotDePasse } from '../../shared/ui/force-mot-de-passe';
import { Icone } from '../../shared/ui/icone';
import { REGLE_MOT_DE_PASSE, champsIdentiques, enErreur } from '../auth/formulaire';
import { ProfilService } from './profil.service';

/**
 * Changement du mot de passe une fois connecté. L'ancien est demandé, sauf pour un compte créé avec Google
 * (il n'en a pas encore). Les autres appareils sont déconnectés ; celui-ci reste connecté.
 */
@Component({
  selector: 'app-changer-mot-de-passe',
  imports: [ReactiveFormsModule, RouterLink, EntetePage, Alerte, ChampMotDePasse, ForceMotDePasse, Icone],
  template: `
    <div class="page">
      <app-entete-page [titre]="aUnMotDePasse() ? 'Changer le mot de passe' : 'Définir un mot de passe'" retour="/profil" />

      @if (termine()) {
        <section class="carte bloc">
          <app-alerte type="succes" titre="Mot de passe modifié">
            Vos autres appareils ont été déconnectés. Un email de confirmation vous a été envoyé.
          </app-alerte>
          <a class="bouton bouton--primaire" routerLink="/profil">Retour à mon profil</a>
        </section>
      } @else {
        <form class="carte formulaire" [formGroup]="form" (ngSubmit)="enregistrer()" novalidate>
          @if (aUnMotDePasse()) {
            <div class="champ" [class.champ--erreur]="enErreur('actuel') || erreur()?.champ === 'motDePasseActuel'">
              <label class="libelle" for="actuel">Mot de passe actuel</label>
              <app-champ-mot-de-passe idChamp="actuel" formControlName="actuel" autocomplete="current-password" />
            </div>
          } @else {
            <p class="aide">Votre compte a été créé avec Google : choisissez un mot de passe pour pouvoir aussi vous
              connecter avec votre email ou votre numéro.</p>
          }

          <div class="champ" [class.champ--erreur]="enErreur('nouveau') || erreur()?.champ === 'nouveauMotDePasse'">
            <label class="libelle" for="nouveau">Nouveau mot de passe</label>
            <app-champ-mot-de-passe idChamp="nouveau" formControlName="nouveau" icone="cle" autocomplete="new-password" />
            @if (enErreur('nouveau')) {
              <p class="message-erreur">8 caractères minimum, au moins une lettre et un chiffre</p>
            }
          </div>

          <div class="champ" [class.champ--erreur]="confirmationDifferente()">
            <label class="libelle" for="confirmer">Confirmer</label>
            <app-champ-mot-de-passe idChamp="confirmer" formControlName="confirmation" autocomplete="new-password" />
            @if (confirmationDifferente()) {
              <p class="message-erreur">Les deux mots de passe ne correspondent pas</p>
            }
          </div>

          <app-force-mot-de-passe [motDePasse]="nouveau()" />

          @if (erreur(); as e) {
            <app-alerte type="erreur">{{ e.message }}</app-alerte>
          }

          <button class="bouton bouton--primaire" type="submit" [disabled]="envoi()">
            @if (envoi()) {
              <span class="chargement" aria-hidden="true"></span>
            } @else {
              <app-icone nom="valide" />
            }
            Enregistrer
          </button>
          <p class="pied-securite"><app-icone nom="bouclier" [taille]="15" /> Vos autres appareils seront déconnectés.</p>
        </form>
      }
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
  `,
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class ChangerMotDePasse {
  private readonly profils = inject(ProfilService);
  private readonly session = inject(SessionService);
  private readonly fb = inject(FormBuilder);

  protected readonly aUnMotDePasse = computed(() => this.session.utilisateur()?.motDePasseDefini ?? true);
  protected readonly form = this.fb.nonNullable.group(
    {
      actuel: [''],
      nouveau: ['', [Validators.required, Validators.pattern(REGLE_MOT_DE_PASSE)]],
      confirmation: ['', Validators.required],
    },
    { validators: champsIdentiques('nouveau', 'confirmation') },
  );
  protected readonly nouveau = toSignal(this.form.controls.nouveau.valueChanges, { initialValue: '' });
  protected readonly envoi = signal(false);
  protected readonly termine = signal(false);
  protected readonly erreur = signal<ErreurApi | null>(null);
  protected readonly enErreur = (nom: string) => enErreur(this.form, nom);

  constructor() {
    if (this.aUnMotDePasse()) this.form.controls.actuel.addValidators(Validators.required);
  }

  protected confirmationDifferente(): boolean {
    const c = this.form.controls.confirmation;
    return this.form.hasError('differents') && (c.touched || c.dirty);
  }

  protected enregistrer(): void {
    if (this.form.invalid) {
      this.form.markAllAsTouched();
      return;
    }
    const { actuel, nouveau } = this.form.getRawValue();
    this.envoi.set(true);
    this.erreur.set(null);
    this.profils.changerMotDePasse(this.aUnMotDePasse() ? actuel : null, nouveau).subscribe({
      next: () => this.termine.set(true),
      error: (e) => {
        this.erreur.set(lireErreur(e));
        this.envoi.set(false);
      },
    });
  }
}
