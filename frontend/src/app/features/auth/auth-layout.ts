import { ChangeDetectionStrategy, Component, signal, viewChild } from '@angular/core';
import { RouterLink, RouterOutlet } from '@angular/router';
import { Icone } from '../../shared/ui/icone';
import { Logo } from '../../shared/ui/logo';

/**
 * Cadre des écrans d'authentification : colonne centrée (mobile-first, comme les maquettes) ;
 * sur grand écran, un panneau de présentation s'ajoute à gauche.
 * Donnée de route `epure` (écran de connexion) : bandeau vert en haut avec le logo et colonne étroite centrée,
 * sans panneau de présentation (inspiré de la page de connexion d'Uber).
 */
@Component({
  selector: 'app-auth-layout',
  imports: [RouterOutlet, RouterLink, Logo, Icone],
  template: `
    @if (epure()) {
      <header class="bandeau">
        <a routerLink="/accueil" aria-label="YOBALEMAsn, accueil"><app-logo /></a>
      </header>
    }
    <div class="cadre" [class.cadre--epure]="epure()">
      <aside class="presentation" aria-hidden="true">
        <app-logo />
        <div>
          <p class="presentation__titre">Le covoiturage au juste prix, partout au Sénégal.</p>
          <ul>
            <li><app-icone nom="eclair" [taille]="18" /> Un prix calculé à partir de votre véhicule et du trajet réel</li>
            <li><app-icone nom="bouclier" [taille]="18" /> Conducteurs vérifiés par notre équipe</li>
            <li><app-icone nom="feuille" [taille]="18" /> Moins de voitures, moins de CO₂</li>
          </ul>
        </div>
        <p class="presentation__pied">Dakar · Thiès · Saint-Louis · Touba · Ziguinchor</p>
      </aside>
      <main class="contenu">
        <router-outlet (activate)="activer()" />
        <p class="liens-legaux">
          <a routerLink="/conditions">Conditions d'utilisation</a> · <a routerLink="/confidentialite">Confidentialité</a>
        </p>
      </main>
    </div>
  `,
  styles: `
    .bandeau {
      --logo-texte: #fff;
      display: flex;
      align-items: center;
      height: 64px;
      padding: 0 16px;
      background: #0d3d2b;
    }
    .cadre--epure {
      min-height: calc(100dvh - 64px);
      background: var(--surface);
      .presentation { display: none; }
      .contenu { max-width: 442px; align-self: start; padding: 32px 16px; }
    }
    .liens-legaux {
      margin: 24px 0 8px;
      font-size: 13px;
      text-align: center;
      color: var(--texte-2);
    }
    .cadre {
      display: grid;
      min-height: 100dvh;
    }
    .contenu {
      width: 100%;
      max-width: 440px;
      margin: 0 auto;
      padding: 16px 16px 32px;
    }
    .presentation {
      display: none;
    }
    @media (min-width: 960px) {
      .cadre {
        grid-template-columns: minmax(360px, 5fr) 7fr;
      }
      .contenu {
        align-self: center;
        padding: 40px 16px;
      }
      .bandeau { padding: 0 72px; }
      .cadre--epure {
        grid-template-columns: 1fr;
        .contenu { padding: 96px 16px 40px; }
      }
      .presentation {
        display: flex;
        flex-direction: column;
        justify-content: space-between;
        padding: 40px 48px;
        background: linear-gradient(160deg, #0c6b3f 0%, #084a2b 100%);
        color: #e7f6ee;
        ::ng-deep .logo__texte {
          color: #fff;
        }
        ul {
          display: grid;
          gap: 14px;
          padding: 0;
          margin: 24px 0 0;
          list-style: none;
          font-size: 15px;
        }
        li {
          display: flex;
          gap: 10px;
          align-items: flex-start;
        }
      }
      .presentation__titre {
        margin: 0;
        font-size: 30px;
        font-weight: 800;
        line-height: 1.15;
        letter-spacing: -0.02em;
        color: #fff;
      }
      .presentation__pied {
        margin: 0;
        font-size: 13px;
        opacity: 0.7;
      }
    }
  `,
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class AuthLayout {
  private readonly outlet = viewChild.required(RouterOutlet);
  protected readonly epure = signal(false);

  protected activer(): void {
    this.epure.set(!!this.outlet().activatedRouteData['epure']);
  }
}
