import { ChangeDetectionStrategy, Component, inject, input, signal } from '@angular/core';
import { toSignal } from '@angular/core/rxjs-interop';
import { FormBuilder, ReactiveFormsModule, Validators } from '@angular/forms';
import { ErreurApi, lireErreur } from '../../core/api/erreur-api';
import { Profil } from '../../core/auth/auth.models';
import { Alerte } from '../../shared/ui/alerte';
import { Icone } from '../../shared/ui/icone';
import { ProfilService } from './profil.service';

/** Bloc « À propos » : présentation libre, et modification du prénom, du nom et de la présentation. */
@Component({
  selector: 'app-a-propos',
  imports: [ReactiveFormsModule, Icone, Alerte],
  template: `
    <section class="carte bloc">
      <header class="bloc__entete">
        <h2><app-icone nom="utilisateur" /> À propos</h2>
        @if (!edition()) {
          <button class="bouton-rond" type="button" (click)="ouvrir()" aria-label="Modifier mes informations">
            <app-icone nom="crayon" [taille]="17" />
          </button>
        }
      </header>

      @if (!edition()) {
        @if (profil().bio; as bio) {
          <blockquote>« {{ bio }} »</blockquote>
        } @else {
          <p class="vide">Présentez-vous en quelques mots : vos trajets habituels, votre façon de conduire…</p>
        }
      } @else {
        <form class="formulaire" [formGroup]="form" (ngSubmit)="enregistrer()" novalidate>
          <div class="deux">
            <div class="champ" [class.champ--erreur]="form.controls.prenom.invalid && form.controls.prenom.touched">
              <label class="libelle" for="prenom">Prénom</label>
              <div class="saisie"><input id="prenom" formControlName="prenom" autocomplete="given-name" /></div>
            </div>
            <div class="champ" [class.champ--erreur]="form.controls.nom.invalid && form.controls.nom.touched">
              <label class="libelle" for="nom">Nom</label>
              <div class="saisie"><input id="nom" formControlName="nom" autocomplete="family-name" /></div>
            </div>
          </div>
          <div class="champ">
            <label class="libelle" for="bio">Présentation</label>
            <div class="saisie saisie--texte">
              <textarea id="bio" formControlName="bio" rows="4" maxlength="500"
                placeholder="Trajets fréquents Dakar – Thiès, conduite prudente…"></textarea>
            </div>
            <p class="aide">{{ longueurBio() }} / 500</p>
          </div>
          @if (erreur(); as e) {
            <app-alerte type="erreur">{{ e.message }}</app-alerte>
          }
          <div class="actions">
            <button class="bouton bouton--secondaire" type="button" (click)="edition.set(false)">Annuler</button>
            <button class="bouton bouton--primaire" type="submit" [disabled]="envoi()">
              @if (envoi()) {
                <span class="chargement" aria-hidden="true"></span>
              }
              Enregistrer
            </button>
          </div>
        </form>
      }
    </section>
  `,
  styles: `
    blockquote {
      margin: 0;
      padding: 14px 16px;
      border-radius: var(--rayon);
      background: var(--surface-2);
      color: var(--texte-2);
      white-space: pre-line;
    }
    .vide {
      margin: 0;
      color: var(--texte-3);
    }
    .deux {
      display: grid;
      grid-template-columns: 1fr 1fr;
      gap: 12px;
    }
    .saisie--texte {
      padding: 10px 14px;
      textarea {
        width: 100%;
        border: 0;
        outline: 0;
        resize: vertical;
        font: inherit;
        background: transparent;
      }
    }
    .aide {
      text-align: right;
    }
    .actions {
      display: grid;
      grid-template-columns: 1fr 1fr;
      gap: 10px;
    }
  `,
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class APropos {
  private readonly profils = inject(ProfilService);
  private readonly fb = inject(FormBuilder);

  readonly profil = input.required<Profil>();

  protected readonly edition = signal(false);
  protected readonly envoi = signal(false);
  protected readonly erreur = signal<ErreurApi | null>(null);
  protected readonly form = this.fb.nonNullable.group({
    prenom: ['', [Validators.required, Validators.maxLength(80)]],
    nom: ['', [Validators.required, Validators.maxLength(80)]],
    bio: ['', Validators.maxLength(500)],
  });
  private readonly bio = toSignal(this.form.controls.bio.valueChanges, { initialValue: '' });
  protected readonly longueurBio = () => this.bio().length;

  protected ouvrir(): void {
    const p = this.profil();
    this.form.reset({ prenom: p.prenom, nom: p.nom, bio: p.bio ?? '' });
    this.erreur.set(null);
    this.edition.set(true);
  }

  protected enregistrer(): void {
    if (this.form.invalid) {
      this.form.markAllAsTouched();
      return;
    }
    const { prenom, nom, bio } = this.form.getRawValue();
    this.envoi.set(true);
    this.profils.modifier({ prenom, nom, bio: bio.trim() || null, sexe: this.profil().sexe }).subscribe({
      next: () => {
        this.envoi.set(false);
        this.edition.set(false);
      },
      error: (e) => {
        this.erreur.set(lireErreur(e));
        this.envoi.set(false);
      },
    });
  }
}
