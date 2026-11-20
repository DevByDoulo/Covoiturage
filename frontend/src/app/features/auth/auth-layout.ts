import { ChangeDetectionStrategy, Component, inject, signal, ViewEncapsulation, viewChild } from '@angular/core';
import { RouterLink, RouterOutlet } from '@angular/router';
import { SessionService } from '../../core/auth/session.service';
import { Logo } from '../../shared/ui/logo';

/**
 * Cadre de tous les écrans d'authentification : photo plein écran (WebP, repli en dégradé vert si elle manque),
 * voile sombre dégradé, et formulaire posé directement sur la photo (texte blanc, champs blancs arrondis).
 * Sur grand écran, logo et accroche à gauche, séparés du formulaire par une fine ligne blanche ; sur téléphone,
 * formulaire centré, pleine largeur. Le style (partagé par tous les écrans) est dans `auth-photo.scss`.
 * Écrans d'inscription (donnée de route `carte`, ou code de vérification d'une inscription) : le formulaire est dans une
 * carte vert foncé translucide (`auth-carte.scss`) et la colonne de gauche porte un texte d'accueil.
 */
@Component({
  selector: 'app-auth-layout',
  imports: [RouterOutlet, RouterLink, Logo],
  template: `
    <div class="auth-photo" [class.auth-photo--carte]="carte()">
      @if (!fondAbsent()) {
        <picture class="auth-photo__fond" aria-hidden="true">
          <source
            media="(max-width: 767px) and (orientation: portrait)"
            srcset="fond-connexion-mobile.webp"
            type="image/webp"
            width="828"
            height="1600"
          />
          <img
            src="fond-connexion.webp"
            alt=""
            width="1376"
            height="768"
            fetchpriority="high"
            decoding="async"
            (error)="fondAbsent.set(true)"
          />
        </picture>
      }
      <div class="auth-photo__voile" aria-hidden="true"></div>
      <div class="auth-photo__cadre">
        <header class="auth-photo__marque">
          <a class="auth-photo__logo" routerLink="/accueil" aria-label="YOBALEMAsn, accueil"><app-logo /></a>
          @if (carte()) {
            <div class="auth-photo__hero">
              <p class="auth-photo__etiquette">REJOIGNEZ GRATUITEMENT</p>
              <h2 class="auth-photo__titre">Voyagez ensemble, <mark>au juste prix</mark>.</h2>
              <p class="auth-photo__texte">
                Un prix calculé pour votre trajet, des conducteurs vérifiés par notre équipe et moins de voitures sur la route.
              </p>
            </div>
          } @else {
            <p class="auth-photo__accroche">Le covoiturage au juste prix, partout au Sénégal.</p>
          }
        </header>
        <main class="auth-panneau">
          <router-outlet (activate)="activer()" />
          @if (carte()) {
            <p class="auth-photo__deja">Déjà membre ? <a routerLink="/auth/connexion">Se connecter</a></p>
          }
          <p class="liens-legaux">
            <a routerLink="/conditions">Conditions d'utilisation</a> · <a routerLink="/confidentialite">Confidentialité</a>
          </p>
        </main>
      </div>
    </div>
  `,
  styleUrls: ['./auth-photo.scss', './auth-carte.scss'],
  encapsulation: ViewEncapsulation.None,
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class AuthLayout {
  /** Vrai si la photo n'a pas pu être chargée : on laisse alors le dégradé de repli. */
  protected readonly fondAbsent = signal(false);
  /** Vrai sur les écrans d'inscription : formulaire dans une carte sombre, texte d'accueil à gauche. */
  protected readonly carte = signal(false);

  private readonly outlet = viewChild.required(RouterOutlet);
  private readonly session = inject(SessionService);

  protected activer(): void {
    const route = this.outlet().activatedRoute;
    const codeDInscription =
      route.snapshot.routeConfig?.path === 'verification' &&
      (route.snapshot.queryParamMap.has('inscription') || !!this.session.verification()?.inscription);
    this.carte.set(!!this.outlet().activatedRouteData['carte'] || codeDInscription);
  }
}
