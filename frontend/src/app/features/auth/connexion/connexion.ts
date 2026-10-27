import { ChangeDetectionStrategy, Component, computed, inject, input, signal } from '@angular/core';
import { FormBuilder, ReactiveFormsModule, Validators } from '@angular/forms';
import { Router, RouterLink } from '@angular/router';
import { ErreurApi, lireErreur } from '../../../core/api/erreur-api';
import { AuthReponse } from '../../../core/auth/auth.models';
import { SessionService } from '../../../core/auth/session.service';
import { Alerte } from '../../../shared/ui/alerte';
import { BoutonGoogle } from '../../../shared/ui/bouton-google';
import { ChampMotDePasse } from '../../../shared/ui/champ-mot-de-passe';
import { Icone } from '../../../shared/ui/icone';
import { Logo } from '../../../shared/ui/logo';
import { enErreur, retourSur } from '../formulaire';

@Component({
  selector: 'app-connexion',
  imports: [ReactiveFormsModule, RouterLink, Logo, Icone, Alerte, ChampMotDePasse, BoutonGoogle],
  templateUrl: './connexion.html',
  styleUrl: '../auth-commun.scss',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class Connexion {
  private readonly session = inject(SessionService);
  private readonly router = inject(Router);

  /** Paramètres d'URL (liés automatiquement par le routeur). */
  readonly retour = input<string>();
  readonly expiree = input<string>();
  readonly reinitialise = input<string>();
  readonly desactive = input<string>();

  protected readonly form = inject(FormBuilder).nonNullable.group({
    identifiant: ['', Validators.required],
    motDePasse: ['', Validators.required],
  });
  protected readonly envoi = signal(false);
  protected readonly erreur = signal<ErreurApi | null>(null);
  protected readonly googleIndisponible = signal(false);
  protected readonly bloque = computed(() => this.erreur()?.status === 429);
  protected readonly enErreur = (nom: string) => enErreur(this.form, nom);

  protected soumettre(): void {
    if (this.form.invalid) {
      this.form.markAllAsTouched();
      return;
    }
    const { identifiant, motDePasse } = this.form.getRawValue();
    this.envoi.set(true);
    this.erreur.set(null);
    this.session.connexion(identifiant.trim(), motDePasse).subscribe({
      next: (r) => this.suite(r),
      error: (e) => {
        this.erreur.set(lireErreur(e));
        this.envoi.set(false);
      },
    });
  }

  protected google(idToken: string): void {
    this.envoi.set(true);
    this.erreur.set(null);
    this.session.connexionGoogle(idToken).subscribe({
      next: (r) => this.suite(r),
      error: (e) => {
        this.erreur.set(lireErreur(e));
        this.envoi.set(false);
      },
    });
  }

  private suite(r: AuthReponse): void {
    if (r.etape === 'OTP_ENVOYE') this.router.navigateByUrl('/auth/verification');
    else if (r.etape === 'TELEPHONE_REQUIS') this.router.navigateByUrl('/auth/google/telephone');
    else this.router.navigateByUrl(retourSur(this.retour()) ?? this.session.pageAccueil());
  }
}
