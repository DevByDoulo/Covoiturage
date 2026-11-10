import { ChangeDetectionStrategy, Component, ViewEncapsulation, computed, inject, input } from '@angular/core';
import { RouterLink } from '@angular/router';
import { SessionService } from '../../core/auth/session.service';
import { Logo } from '../../shared/ui/logo';

/** Adresse de contact affichée dans les textes légaux (questions, demandes sur les données personnelles). */
export const CONTACT_LEGAL = 'doulo.thioune.dev@gmail.com';
/** Date de la version en vigueur des deux textes. */
export const VERSION_LEGALE = '10 novembre 2026';

/**
 * Cadre commun des pages publiques « Conditions d'utilisation » et « Politique de confidentialité » :
 * accessibles sans compte (lien depuis l'inscription), lisibles sur téléphone et imprimables.
 */
@Component({
  selector: 'app-page-legale',
  imports: [RouterLink, Logo],
  template: `
    <div class="legal">
      <header class="legal__entete">
        <a [routerLink]="retour()" class="legal__logo" aria-label="YOBALEMAsn"><app-logo /></a>
        <a [routerLink]="retour()" class="bouton-lien">{{ connecte() ? 'Retour à mon espace' : 'Retour à la connexion' }}</a>
      </header>
      <main class="legal__corps">
        <h1>{{ titre() }}</h1>
        <p class="legal__version">Version du {{ version }} · YOBALEMAsn, projet de fin d'études réalisé à l'ISEP de Diamniadio</p>
        <ng-content />
        <footer class="legal__pied">
          <p>Une question ? Écrivez-nous à <a [href]="'mailto:' + contact">{{ contact }}</a>.</p>
          <nav aria-label="Textes légaux">
            <a routerLink="/conditions">Conditions d'utilisation</a> ·
            <a routerLink="/confidentialite">Politique de confidentialité</a>
          </nav>
        </footer>
      </main>
    </div>
  `,
  styles: `
    .legal {
      min-height: 100vh;
      background: var(--fond, #f5f7f6);
    }
    .legal__entete {
      display: flex;
      align-items: center;
      justify-content: space-between;
      gap: 12px;
      max-width: 820px;
      margin: 0 auto;
      padding: 16px;
    }
    .legal__corps {
      max-width: 820px;
      margin: 0 auto 40px;
      padding: 24px 20px 32px;
      border-radius: 16px;
      background: var(--surface, #fff);
      line-height: 1.6;
      color: var(--texte, #1d2a24);
    }
    .legal__corps h1 { margin: 0 0 4px; font-size: 26px; }
    .legal__corps h2 { margin: 28px 0 8px; font-size: 19px; color: var(--vert, #0c6b3f); }
    .legal__corps h3 { margin: 18px 0 6px; font-size: 16px; }
    .legal__corps ul { padding-left: 20px; }
    .legal__corps li { margin: 4px 0; }
    .legal__corps table { width: 100%; border-collapse: collapse; font-size: 14px; }
    .legal__corps th, .legal__corps td { padding: 8px; border: 1px solid var(--bord, #dde3e0); text-align: left; vertical-align: top; }
    .legal__corps th { background: var(--vert-clair, #e6f2ec); }
    .legal__tableau { overflow-x: auto; }
    .legal__version { margin: 0 0 16px; color: var(--texte-2, #5b6b63); font-size: 14px; }
    .legal__sommaire { padding: 12px 16px; border-radius: 12px; background: var(--vert-clair, #e6f2ec); }
    .legal__sommaire ol { margin: 6px 0 0; padding-left: 20px; }
    .legal__note {
      padding: 12px 16px;
      border-left: 4px solid var(--orange, #f29a1f);
      border-radius: 8px;
      background: var(--orange-clair, #fdf0e1);
    }
    .legal__pied {
      margin-top: 32px;
      padding-top: 16px;
      border-top: 1px solid var(--bord, #dde3e0);
      font-size: 14px;
      color: var(--texte-2, #5b6b63);
    }
    @media print {
      .legal__entete, .legal__pied nav { display: none; }
      .legal__corps { box-shadow: none; margin: 0; }
    }
  `,
  encapsulation: ViewEncapsulation.None,
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class PageLegale {
  private readonly session = inject(SessionService);
  readonly titre = input.required<string>();
  protected readonly contact = CONTACT_LEGAL;
  protected readonly version = VERSION_LEGALE;
  protected readonly connecte = this.session.estConnecte;
  protected readonly retour = computed(() => (this.connecte() ? this.session.pageAccueil() : '/auth/connexion'));
}
