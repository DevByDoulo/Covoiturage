import { ChangeDetectionStrategy, Component, inject, input, signal } from '@angular/core';
import { Router } from '@angular/router';
import { Observable } from 'rxjs';
import { ErreurApi, lireErreur } from '../../core/api/erreur-api';
import { AuthReponse } from '../../core/auth/auth.models';
import { SessionService } from '../../core/auth/session.service';
import { Alerte } from '../../shared/ui/alerte';
import { BoutonApple, ReponseApple } from '../../shared/ui/bouton-apple';
import { BoutonGoogle } from '../../shared/ui/bouton-google';
import { appleConfigure } from './entree/entree';

/**
 * « ou continuer avec » Google (et Apple s'il est configuré) : pastilles rondes, puis suite du parcours
 * (numéro de téléphone à compléter, code de vérification, ou connexion directe). Utilisé sous le formulaire e-mail
 * de l'inscription ; le style (`.separateur`, `.reseaux`) est celui d'`auth-photo.scss`.
 */
@Component({
  selector: 'app-connexion-sociale',
  imports: [Alerte, BoutonGoogle, BoutonApple],
  template: `
    <div class="separateur">ou continuer avec</div>

    <div class="reseaux">
      <app-bouton-google variante="icone" (jeton)="google($event)" (indisponible)="googleIndisponible.set(true)" />
      @if (apple) {
        <app-bouton-apple variante="icone" (reponse)="connexionApple($event)"
                          (indisponible)="messageApple.set(messagesApple.indisponible)" (echec)="messageApple.set(messagesApple.echec)" />
      }
    </div>
    @if (googleIndisponible()) {
      <app-alerte type="info">La connexion Google n'est pas disponible pour le moment. Utilisez votre e-mail ou votre numéro.</app-alerte>
    }
    @if (apple && messageApple(); as m) {
      <app-alerte type="info">{{ m }}</app-alerte>
    }
    @if (erreur(); as e) {
      <app-alerte type="erreur">{{ e.message }}</app-alerte>
    }
  `,
  styles: `
    :host {
      display: flex;
      flex-direction: column;
      gap: 14px;
    }
  `,
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class ConnexionSociale {
  private readonly session = inject(SessionService);
  private readonly router = inject(Router);

  /** Garder la session 30 jours (case « Rester connecté » de l'écran qui l'affiche). */
  readonly resterConnecte = input(false);

  protected readonly googleIndisponible = signal(false);
  protected readonly apple = appleConfigure();
  protected readonly messageApple = signal<string | null>(null);
  protected readonly messagesApple = {
    indisponible: "La connexion Apple n'est pas disponible pour le moment.",
    echec: 'La connexion avec Apple a échoué. Réessayez.',
  };
  protected readonly erreur = signal<ErreurApi | null>(null);

  protected google(idToken: string): void {
    this.suivre(this.session.connexionGoogle(idToken, undefined, undefined, this.resterConnecte()));
  }

  protected connexionApple(r: ReponseApple): void {
    this.suivre(this.session.connexionApple(r, undefined, undefined, this.resterConnecte()));
  }

  private suivre(appel: Observable<AuthReponse>): void {
    this.erreur.set(null);
    appel.subscribe({
      next: (r) => {
        if (r.etape === 'TELEPHONE_REQUIS') this.router.navigateByUrl('/auth/telephone');
        else if (r.etape === 'OTP_ENVOYE') this.router.navigate(['/auth/verification'], { queryParams: { inscription: 5 } });
        else this.router.navigateByUrl(this.session.pageApresConnexion());
      },
      error: (e) => this.erreur.set(lireErreur(e)),
    });
  }
}
