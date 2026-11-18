import { ChangeDetectionStrategy, Component, OnInit, computed, inject, input, signal } from '@angular/core';
import { Router, RouterLink } from '@angular/router';
import { ErreurApi, lireErreur } from '../../../core/api/erreur-api';
import { AuthReponse } from '../../../core/auth/auth.models';
import { SessionService } from '../../../core/auth/session.service';
import { Alerte } from '../../../shared/ui/alerte';
import { BoutonGoogle } from '../../../shared/ui/bouton-google';
import { retourSur } from '../formulaire';

/**
 * Inscription sur le site, uniquement avec Google, en plusieurs étapes comme Uber :
 * 1. Google (nom, prénom et e-mail repris du compte Google), puis sur /auth/google/telephone
 * 2. numéro de téléphone, 3. sexe, 4. conditions, et enfin 5. code reçu par SMS (/auth/verification).
 * Un compte Google déjà inscrit est simplement connecté.
 */
@Component({
  selector: 'app-inscription',
  imports: [RouterLink, Alerte, BoutonGoogle],
  templateUrl: './inscription.html',
  styleUrls: ['../auth-epure.scss', './inscription.scss'],
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class Inscription implements OnInit {
  private readonly session = inject(SessionService);
  private readonly router = inject(Router);

  /** Paramètre d'URL (lié par le routeur) : page à rejoindre après l'inscription. */
  readonly retour = input<string>();
  protected readonly retourValide = computed(() => retourSur(this.retour()));

  protected readonly envoi = signal(false);
  protected readonly erreur = signal<ErreurApi | null>(null);
  protected readonly googleIndisponible = signal(false);

  ngOnInit(): void {
    this.session.memoriserRetour(this.retour());
  }

  protected google(idToken: string): void {
    this.envoi.set(true);
    this.erreur.set(null);
    this.session.connexionGoogle(idToken, undefined, undefined, false).subscribe({
      next: (r) => this.suite(r),
      error: (e) => {
        this.erreur.set(lireErreur(e));
        this.envoi.set(false);
      },
    });
  }

  private suite(r: AuthReponse): void {
    if (r.etape === 'TELEPHONE_REQUIS') this.router.navigateByUrl('/auth/google/telephone');
    else if (r.etape === 'OTP_ENVOYE') this.router.navigateByUrl('/auth/verification');
    else this.router.navigateByUrl(this.session.pageApresConnexion());
  }
}
