import { ChangeDetectionStrategy, Component, computed, inject } from '@angular/core';
import { RouterLink, RouterLinkActive, RouterOutlet } from '@angular/router';
import { SessionService } from '../../core/auth/session.service';
import { Icone } from '../../shared/ui/icone';
import { initiales } from '../profil/profil.service';
import { AdminService } from './admin.service';

/**
 * Cadre du back-office (module 07), d'après les maquettes « Validation des documents » et « BO - Fiche utilisateur » :
 * menu latéral vert sur grand écran, barre d'onglets en haut sur téléphone.
 */
@Component({
  selector: 'app-admin-layout',
  imports: [RouterOutlet, RouterLink, RouterLinkActive, Icone],
  template: `
    <aside class="menu">
      <a class="menu__marque" routerLink="/admin">
        <span class="menu__logo">Y</span>
        <span><strong>YOBALEMA<span class="sn">sn</span></strong><small>Back-office administrateur</small></span>
      </a>
      <nav aria-label="Back-office">
        <a routerLink="/admin" routerLinkActive="actif" [routerLinkActiveOptions]="{ exact: true }">
          <app-icone nom="maison" [taille]="19" /> <span>Tableau de bord</span>
        </a>
        <a routerLink="/admin/utilisateurs" routerLinkActive="actif">
          <app-icone nom="utilisateurs" [taille]="19" /> <span>Utilisateurs</span>
        </a>
        <a routerLink="/admin/documents" routerLinkActive="actif">
          <app-icone nom="bouclier" [taille]="19" /> <span>Validation documents</span>
          @if (admin.documentsEnAttente(); as n) {
            <span class="badge" [attr.aria-label]="n + ' en attente'">{{ n }}</span>
          }
        </a>
      </nav>
      <button class="menu__sortie" type="button" (click)="session.demanderDeconnexion()">
        <app-icone nom="deconnexion" [taille]="19" /> <span>Se déconnecter</span>
      </button>
    </aside>

    <div class="principal">
      <header class="barre">
        <a class="moi" routerLink="/profil">
          <span class="moi__texte"><strong>{{ nom() }}</strong><small>Administrateur</small></span>
          <span class="moi__avatar">{{ initiales() }}</span>
        </a>
      </header>
      <main class="contenu"><router-outlet /></main>
    </div>
  `,
  styles: `
    :host {
      display: block;
      min-height: 100dvh;
    }
    .menu {
      display: flex;
      flex-direction: column;
      gap: 12px;
      padding: 12px 16px;
      background: #0d3d2b;
      color: #e7f3ec;
    }
    .menu__marque {
      display: flex;
      align-items: center;
      gap: 10px;
      color: #fff;
      text-decoration: none !important;
      small {
        display: block;
        font-size: 11.5px;
        font-weight: 500;
        color: #a9c9b8;
      }
      .sn {
        color: var(--orange);
      }
    }
    .menu__logo {
      display: grid;
      place-items: center;
      width: 36px;
      height: 36px;
      border-radius: 10px;
      background: var(--vert);
      font-weight: 800;
    }
    nav {
      display: flex;
      gap: 4px;
      overflow-x: auto;
      a {
        display: flex;
        flex: none;
        align-items: center;
        gap: 10px;
        padding: 10px 12px;
        border-radius: 12px;
        color: inherit;
        font-weight: 600;
        text-decoration: none;
        &:hover {
          background: rgba(255, 255, 255, 0.08);
        }
      }
      a.actif {
        background: var(--vert);
        color: #fff;
      }
    }
    .badge {
      min-width: 22px;
      padding: 1px 7px;
      border-radius: 999px;
      background: var(--orange);
      font-size: 12px;
      font-weight: 800;
      text-align: center;
      color: #3d2300;
    }
    .menu__sortie {
      display: none;
      align-items: center;
      gap: 10px;
      margin-top: auto;
      padding: 10px 12px;
      border: 0;
      background: none;
      color: #f6c27a;
      font-weight: 600;
      cursor: pointer;
    }
    .barre {
      display: flex;
      justify-content: flex-end;
      padding: 10px 20px;
      background: var(--surface);
      box-shadow: var(--ombre);
    }
    .moi {
      display: flex;
      align-items: center;
      gap: 10px;
      color: var(--texte);
      text-align: right;
      text-decoration: none !important;
      small {
        display: block;
        font-size: 12px;
        color: var(--texte-3);
      }
    }
    .moi__avatar {
      display: grid;
      place-items: center;
      width: 42px;
      height: 42px;
      border-radius: 50%;
      background: var(--vert);
      font-weight: 800;
      color: #fff;
    }
    .contenu {
      max-width: 1280px;
      margin: 0 auto;
      padding: 22px 16px 40px;
    }
    @media (min-width: 900px) {
      :host {
        display: grid;
        grid-template-columns: 260px 1fr;
      }
      .menu {
        position: sticky;
        top: 0;
        height: 100dvh;
        padding: 24px 16px;
        gap: 28px;
      }
      nav {
        flex-direction: column;
      }
      .menu__sortie {
        display: flex;
      }
      .contenu {
        padding: 26px 32px 48px;
      }
    }
  `,
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class AdminLayout {
  protected readonly session = inject(SessionService);
  protected readonly admin = inject(AdminService);
  protected readonly nom = computed(() => {
    const u = this.session.utilisateur();
    return u ? `${u.prenom} ${u.nom}` : '';
  });
  protected readonly initiales = computed(() => initiales(this.nom()));

  constructor() {
    // Pastille « documents en attente » du menu.
    this.admin.statistiques().subscribe({ error: () => {} });
  }
}
