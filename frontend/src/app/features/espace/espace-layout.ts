import { ChangeDetectionStrategy, Component, computed, inject } from '@angular/core';
import { RouterLink, RouterLinkActive, RouterOutlet } from '@angular/router';
import { SessionService } from '../../core/auth/session.service';
import { Icone, NomIcone } from '../../shared/ui/icone';
import { Logo } from '../../shared/ui/logo';

interface EntreeMenu {
  lien: string;
  libelle: string;
  icone: NomIcone;
}

/**
 * Cadre de l'espace connecté : barre du haut (grand écran) et barre d'onglets en bas (mobile).
 * Chaque fonctionnalité ajoute son entrée dans `entrees` (fichier partagé : modification courte).
 */
@Component({
  selector: 'app-espace-layout',
  imports: [RouterOutlet, RouterLink, RouterLinkActive, Icone, Logo],
  template: `
    <header class="barre">
      <a [routerLink]="session.pageAccueil()" aria-label="Accueil YOBALEMAsn"><app-logo /></a>
      <nav class="menu" aria-label="Navigation principale">
        @for (e of entrees(); track e.lien) {
          <a [routerLink]="e.lien" routerLinkActive="actif" [routerLinkActiveOptions]="{ exact: true }">
            <app-icone [nom]="e.icone" [taille]="18" /> {{ e.libelle }}
          </a>
        }
      </nav>
      <button class="deconnexion" type="button" (click)="session.deconnexion()" aria-label="Se déconnecter">
        <app-icone nom="deconnexion" [taille]="18" /> <span>Déconnexion</span>
      </button>
    </header>

    <main class="contenu"><router-outlet /></main>

    <nav class="onglets" aria-label="Navigation principale">
      @for (e of entrees(); track e.lien) {
        <a [routerLink]="e.lien" routerLinkActive="actif" [routerLinkActiveOptions]="{ exact: true }">
          <app-icone [nom]="e.icone" [taille]="22" />
          <span>{{ e.libelle }}</span>
        </a>
      }
    </nav>
  `,
  styles: `
    :host {
      display: block;
      min-height: 100dvh;
      padding-bottom: 72px;
    }
    .barre {
      position: sticky;
      top: 0;
      z-index: 10;
      display: flex;
      align-items: center;
      gap: 24px;
      padding: 10px 16px;
      background: var(--surface);
      box-shadow: var(--ombre);
    }
    .menu {
      display: none;
      gap: 4px;
      margin-right: auto;
    }
    .menu a,
    .onglets a {
      display: flex;
      align-items: center;
      gap: 6px;
      border-radius: 10px;
      color: var(--texte-2);
      font-weight: 600;
      text-decoration: none;
    }
    .menu a {
      padding: 8px 12px;
    }
    .menu a.actif,
    .onglets a.actif {
      color: var(--vert);
    }
    .menu a.actif {
      background: var(--vert-clair);
    }
    .deconnexion {
      display: inline-flex;
      align-items: center;
      gap: 6px;
      margin-left: auto;
      padding: 8px 12px;
      border: 0;
      border-radius: 10px;
      background: var(--surface-2);
      font-weight: 600;
      cursor: pointer;
    }
    .contenu {
      max-width: 1080px;
      margin: 0 auto;
      padding: 20px 16px 32px;
    }
    .onglets {
      position: fixed;
      inset: auto 0 0;
      z-index: 10;
      display: flex;
      justify-content: space-around;
      padding: 6px 4px calc(6px + env(safe-area-inset-bottom));
      background: var(--surface);
      box-shadow: 0 -2px 10px rgba(17, 24, 39, 0.06);
    }
    .onglets a {
      flex-direction: column;
      gap: 2px;
      padding: 4px 10px;
      font-size: 11.5px;
    }
    @media (min-width: 768px) {
      :host {
        padding-bottom: 0;
      }
      .menu {
        display: flex;
      }
      .deconnexion {
        margin-left: 0;
      }
      .onglets {
        display: none;
      }
    }
    @media (max-width: 420px) {
      .deconnexion span {
        display: none;
      }
    }
  `,
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class EspaceLayout {
  protected readonly session = inject(SessionService);

  protected readonly entrees = computed<EntreeMenu[]>(() => {
    const role = this.session.utilisateur()?.role;
    const profil: EntreeMenu = { lien: '/profil', libelle: 'Profil', icone: 'utilisateur' };
    if (role === 'ADMIN') return [{ lien: '/admin', libelle: 'Tableau de bord', icone: 'maison' }, profil];
    const menu: EntreeMenu[] = [{ lien: '/accueil', libelle: 'Accueil', icone: 'maison' }];
    // 03 — Trajets
    menu.push({ lien: '/rechercher', libelle: 'Rechercher', icone: 'recherche' });
    menu.push({ lien: '/trajets/publier', libelle: 'Publier', icone: 'plus' });
    if (role === 'CONDUCTEUR') menu.push({ lien: '/trajets/mes-trajets', libelle: 'Mes trajets', icone: 'route' });
    return [...menu, profil];
  });
}
