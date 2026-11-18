import { ChangeDetectionStrategy, Component, computed, inject, signal, viewChild } from '@angular/core';
import { toSignal } from '@angular/core/rxjs-interop';
import { NavigationEnd, Router, RouterLink, RouterLinkActive, RouterOutlet } from '@angular/router';
import { filter, map } from 'rxjs';
import { SessionService } from '../../core/auth/session.service';
import { Icone } from '../../shared/ui/icone';
import { Logo } from '../../shared/ui/logo';

/**
 * Cadre des pages publiques (accueil, recherche et détail d'un trajet sans compte) : en-tête avec le logo, Rechercher,
 * Publier et la connexion / inscription, puis pied de page avec les textes légaux. Un utilisateur connecté n'y arrive
 * pas (il garde l'espace connecté) ; l'en-tête propose quand même « Mon espace » si la session s'ouvre sur place.
 */
@Component({
  selector: 'app-public-layout',
  imports: [RouterOutlet, RouterLink, RouterLinkActive, Icone, Logo],
  template: `
    <button class="evitement" type="button" (click)="contenu.focus()">Aller au contenu</button>
    <header class="entete">
      <div class="entete__corps">
        <a class="entete__logo" routerLink="/accueil" aria-label="YOBALEMAsn, accueil"><app-logo /></a>
        <nav class="menu" aria-label="Navigation principale">
          <a routerLink="/rechercher" routerLinkActive="actif"><app-icone nom="recherche" [taille]="18" /> Rechercher</a>
          <a routerLink="/trajets/publier" routerLinkActive="actif"><app-icone nom="plus" [taille]="18" /> Publier</a>
        </nav>
        <div class="acces">
          @if (session.estConnecte()) {
            <a class="bouton bouton--primaire" [routerLink]="session.pageAccueil()">Mon espace</a>
          } @else {
            <a class="connexion" routerLink="/auth/connexion" [queryParams]="retour()">Se connecter</a>
            <a class="bouton bouton--primaire" routerLink="/auth/inscription" [queryParams]="retour()">S'inscrire</a>
          }
        </div>
      </div>
    </header>

    <main #contenu tabindex="-1" [class.cadre]="!pleineLargeur()"><router-outlet (activate)="activer()" /></main>

    <footer class="pied">
      <app-logo [compact]="true" />
      <span>© YOBALEMAsn, covoiturage au Sénégal</span>
      <nav aria-label="Informations légales">
        <a routerLink="/conditions">Conditions d'utilisation</a> · <a routerLink="/confidentialite">Confidentialité</a>
      </nav>
    </footer>
  `,
  styles: `
    :host { display: flex; flex-direction: column; min-height: 100dvh; }
    .evitement {
      position: absolute;
      left: 8px;
      top: -48px;
      z-index: 20;
      padding: 8px 12px;
      border: 0;
      border-radius: 8px;
      background: var(--surface);
      font-weight: 700;
      color: var(--vert);
      &:focus { top: 8px; }
    }
    .entete { position: sticky; top: 0; z-index: 10; background: var(--surface); box-shadow: var(--ombre); }
    .entete__corps {
      display: grid;
      grid-template-columns: 1fr auto;
      grid-template-areas: 'logo acces' 'menu menu';
      align-items: center;
      gap: 6px 12px;
      max-width: 1180px;
      margin: 0 auto;
      padding: 10px 16px 6px;
    }
    .entete__logo { grid-area: logo; justify-self: start; }
    .acces { grid-area: acces; display: flex; align-items: center; gap: 4px; white-space: nowrap; }
    .acces .bouton { width: auto; min-height: 40px; padding: 0 12px; font-size: 14px; }
    .connexion { padding: 8px 6px; font-size: 14px; }
    .menu { grid-area: menu; display: flex; gap: 4px; overflow-x: auto; }
    .menu a {
      display: flex;
      align-items: center;
      gap: 6px;
      padding: 8px 12px;
      border-radius: 10px;
      color: var(--texte-2);
      white-space: nowrap;
      &:hover { text-decoration: none; background: var(--surface-2); }
      &.actif { color: var(--vert); background: var(--vert-clair); }
    }
    main { flex: 1; width: 100%; outline: 0; }
    /* Recherche et détail : même largeur que dans l'espace connecté ; l'accueil occupe toute la largeur. */
    .cadre { max-width: 1080px; margin: 0 auto; padding: 20px 16px 32px; }
    .pied {
      display: flex;
      flex-wrap: wrap;
      align-items: center;
      justify-content: center;
      gap: 8px 16px;
      padding: 20px 16px calc(20px + env(safe-area-inset-bottom));
      border-top: 1px solid rgba(17, 24, 39, 0.08);
      background: var(--surface);
      font-size: 13.5px;
      color: var(--texte-3);
      a { font-weight: 600; }
    }
    @media (min-width: 768px) {
      .entete__corps {
        grid-template-columns: auto 1fr auto;
        grid-template-areas: 'logo menu acces';
        padding: 12px 24px;
      }
      .menu { margin-left: 16px; }
      .cadre { padding: 28px 32px 40px; }
      .acces { gap: 10px; }
      .acces .bouton { padding: 0 16px; }
    }
    /* Téléphone : le pictogramme seul (le nom reste lu par les lecteurs d'écran) laisse la place aux boutons. */
    @media (max-width: 429px) {
      .entete__logo { width: 32px; overflow: hidden; }
    }
  `,
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class PublicLayout {
  protected readonly session = inject(SessionService);
  private readonly router = inject(Router);
  private readonly url = toSignal(
    this.router.events.pipe(
      filter((e) => e instanceof NavigationEnd),
      map(() => this.router.url),
    ),
    { initialValue: this.router.url },
  );
  /** Depuis une recherche ou un trajet, se connecter ramène à la même page (pas depuis l'accueil). */
  protected readonly retour = computed(() => {
    const url = this.url();
    return url === '/' || url.startsWith('/accueil') ? null : { retour: url };
  });
  private readonly outlet = viewChild.required(RouterOutlet);  /** Donnée de route `pleineLargeur` (accueil) : pas de marge autour de la page. */
  protected readonly pleineLargeur = signal(false);

  protected activer(): void {
    this.pleineLargeur.set(!!this.outlet().activatedRouteData['pleineLargeur']);
  }
}
