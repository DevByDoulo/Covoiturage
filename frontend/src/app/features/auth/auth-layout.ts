import { ChangeDetectionStrategy, Component, signal, ViewEncapsulation } from '@angular/core';
import { RouterLink, RouterOutlet } from '@angular/router';
import { Logo } from '../../shared/ui/logo';

/**
 * Cadre de tous les écrans d'authentification : photo plein écran (WebP, repli en dégradé vert si elle manque),
 * voile sombre, et formulaire dans un panneau en verre dépoli. Sur grand écran, logo et accroche à gauche,
 * séparés du panneau par une fine ligne blanche ; sur téléphone, panneau en bas, pleine largeur.
 * Le style (partagé par tous les écrans) est dans `auth-photo.scss`, appliqué sous `.auth-photo`.
 */
@Component({
  selector: 'app-auth-layout',
  imports: [RouterOutlet, RouterLink, Logo],
  template: `
    <div class="auth-photo">
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
            width="1920"
            height="1080"
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
          <p class="auth-photo__accroche">Le covoiturage au juste prix, partout au Sénégal.</p>
        </header>
        <main class="auth-panneau">
          <router-outlet />
          <p class="liens-legaux">
            <a routerLink="/conditions">Conditions d'utilisation</a> · <a routerLink="/confidentialite">Confidentialité</a>
          </p>
        </main>
      </div>
    </div>
  `,
  styleUrl: './auth-photo.scss',
  encapsulation: ViewEncapsulation.None,
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class AuthLayout {
  /** Vrai si la photo n'a pas pu être chargée : on laisse alors le dégradé de repli. */
  protected readonly fondAbsent = signal(false);
}
