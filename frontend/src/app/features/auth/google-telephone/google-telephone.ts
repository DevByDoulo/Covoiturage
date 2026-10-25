import { ChangeDetectionStrategy, Component, OnInit, inject, signal } from '@angular/core';
import { toSignal } from '@angular/core/rxjs-interop';
import { FormBuilder, ReactiveFormsModule, Validators } from '@angular/forms';
import { Router } from '@angular/router';
import { ErreurApi, lireErreur } from '../../../core/api/erreur-api';
import { Sexe } from '../../../core/auth/auth.models';
import { SessionService } from '../../../core/auth/session.service';
import { Alerte } from '../../../shared/ui/alerte';
import { DrapeauSenegal } from '../../../shared/ui/drapeau-senegal';
import { EntetePage } from '../../../shared/ui/entete-page';
import { Icone } from '../../../shared/ui/icone';
import { appliquerErreurServeur, chiffresTelephone, enErreur, telephoneSenegalValidator } from '../formulaire';

/** Premier passage par Google : le numéro (vérifié par SMS) est obligatoire sur YOBALEMAsn. */
@Component({
  selector: 'app-google-telephone',
  imports: [ReactiveFormsModule, EntetePage, Icone, Alerte, DrapeauSenegal],
  template: `
    <app-entete-page titre="Votre numéro" />
    <div class="ecran">
      <div class="titres">
        <h1>Encore une étape</h1>
        <p>Pour la sécurité des trajets, chaque compte est relié à un numéro de téléphone vérifié par SMS.</p>
      </div>

      <form class="formulaire" [formGroup]="form" (ngSubmit)="soumettre()" novalidate>
        <div class="champ" [class.champ--erreur]="enErreur('telephone')">
          <label class="libelle" for="telephone">Numéro de téléphone</label>
          <div class="saisie">
            <span class="indicatif"><app-drapeau-senegal /> +221</span>
            <input id="telephone" type="tel" formControlName="telephone" autocomplete="tel-national" inputmode="tel" placeholder="77 123 45 67" />
          </div>
          @if (enErreur('telephone')) {
            <p class="message-erreur">{{ form.controls.telephone.errors?.['serveur'] ?? 'Numéro sénégalais à 9 chiffres' }}</p>
          }
        </div>

        <div class="champ">
          <span class="libelle" id="libelle-sexe">Sexe</span>
          <div class="bascule" role="group" aria-labelledby="libelle-sexe">
            <button type="button" [attr.aria-pressed]="sexe() === 'HOMME'" (click)="form.controls.sexe.setValue('HOMME')">
              <app-icone nom="homme" [taille]="18" /> Homme
            </button>
            <button type="button" [attr.aria-pressed]="sexe() === 'FEMME'" (click)="form.controls.sexe.setValue('FEMME')">
              <app-icone nom="femme" [taille]="18" /> Femme
            </button>
          </div>
        </div>

        @if (erreur(); as e) {
          <app-alerte type="erreur">{{ e.message }}</app-alerte>
        }

        <button class="bouton bouton--primaire" type="submit" [disabled]="envoi()">
          @if (envoi()) {
            <span class="chargement" aria-hidden="true"></span> Envoi du code…
          } @else {
            Recevoir le code <app-icone nom="fleche-droite" />
          }
        </button>
      </form>
    </div>
  `,
  styleUrl: '../auth-commun.scss',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class GoogleTelephone implements OnInit {
  private readonly session = inject(SessionService);
  private readonly router = inject(Router);
  private readonly fb = inject(FormBuilder);

  protected readonly form = this.fb.nonNullable.group({
    telephone: ['', [Validators.required, telephoneSenegalValidator]],
    sexe: this.fb.control<Sexe | null>(null),
  });
  protected readonly sexe = toSignal(this.form.controls.sexe.valueChanges, { initialValue: null });
  protected readonly envoi = signal(false);
  protected readonly erreur = signal<ErreurApi | null>(null);
  protected readonly enErreur = (nom: string) => enErreur(this.form, nom);

  ngOnInit(): void {
    // L'idToken Google n'est gardé qu'en mémoire : après un rechargement, il faut recommencer.
    if (!this.session.idTokenGoogle) this.router.navigateByUrl('/auth/connexion');
  }

  protected soumettre(): void {
    const idToken = this.session.idTokenGoogle;
    if (!idToken) return;
    if (this.form.invalid) {
      this.form.markAllAsTouched();
      return;
    }
    const { telephone, sexe } = this.form.getRawValue();
    this.envoi.set(true);
    this.erreur.set(null);
    this.session.connexionGoogle(idToken, '+221' + chiffresTelephone(telephone), sexe).subscribe({
      next: (r) => this.router.navigateByUrl(r.etape === 'CONNECTE' ? this.session.pageAccueil() : '/auth/verification'),
      error: (e) => {
        const err = lireErreur(e);
        if (!appliquerErreurServeur(this.form, err)) this.erreur.set(err);
        this.envoi.set(false);
      },
    });
  }
}
