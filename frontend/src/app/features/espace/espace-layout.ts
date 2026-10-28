import { ChangeDetectionStrategy, Component, computed, inject } from '@angular/core';
import { RouterLink, RouterLinkActive, RouterOutlet } from '@angular/router';
import { SessionService } from '../../core/auth/session.service';
import { Icone, NomIcone } from '../../shared/ui/icone';
import { Logo } from '../../shared/ui/logo';
import { initiales, urlFichier } from '../profil/profil.service';

interface EntreeMenu {
  lien: string;
  libelle: string;
  icone: NomIcone;
}

/**
 * Cadre de l'espace connecté : menu latéral à gauche et en-tête avec le nom, le rôle et l'avatar (grand écran) ;
 * sur téléphone, barre du haut avec le logo et l'avatar, et barre d'onglets en bas.
 * Chaque fonctionnalité ajoute son entrée dans `entrees` (fichier partagé : modification courte).
 */
@Component({
  selector: 'app-espace-layout',
  imports: [RouterOutlet, RouterLink, RouterLinkActive, Icone, Logo],
  template: `
    <header class="barre">
      <a class="barre__logo" [routerLink]="session.pageAccueil()" aria-label="Accueil YOBALEMAsn"><app-logo /></a>
      <nav class="menu" aria-label="Navigation principale">
        @for (e of entrees(); track e.lien) {
          <a [routerLink]="e.lien" routerLinkActive="actif" [routerLinkActiveOptions]="{ exact: true }">
            <app-icone [nom]="e.icone" [taille]="18" /> {{ e.libelle }}
          </a>
        }
      </nav>
      <a class="avatar avatar--mobile" routerLink="/profil" [attr.aria-label]="'Mon profil : ' + nom()">
        @if (photo(); as url) { <img [src]="url" alt="" /> } @else { {{ initiales() }} }
      </a>
      <button class="deconnexion" type="button" (click)="session.demanderDeconnexion()" aria-label="Se déconnecter">
        <app-icone nom="deconnexion" [taille]="18" /> <span>Déconnexion</span>
      </button>
    </header>

    <div class="principal">
      <header class="entete">
        <a class="moi" routerLink="/profil">
          <span class="moi__texte"><strong>{{ nom() }}</strong><small>{{ role() }}</small></span>
          <span class="avatar">
            @if (photo(); as url) { <img [src]="url" alt="" /> } @else { {{ initiales() }} }
          </span>
        </a>
      </header>
      <main class="contenu"><router-outlet /></main>
    </div>

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
      padding: 8px 12px;
      border: 0;
      border-radius: 10px;
      background: var(--surface-2);
      font-weight: 600;
      cursor: pointer;
    }
    .entete {
      position: sticky;
      top: 0;
      z-index: 5;
      display: none;
      justify-content: flex-end;
      padding: 12px 32px;
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
        font-weight: 500;
        color: var(--texte-3);
      }
    }
    .avatar {
      display: grid;
      place-items: center;
      flex: none;
      width: 42px;
      height: 42px;
      overflow: hidden;
      border-radius: 50%;
      background: var(--vert);
      font-weight: 800;
      color: #fff;
      text-decoration: none !important;
      img {
        width: 100%;
        height: 100%;
        object-fit: cover;
      }
    }
    .avatar--mobile {
      width: 36px;
      height: 36px;
      margin-left: auto;
      font-size: 14px;
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
        display: grid;
        grid-template-columns: 240px 1fr;
        padding-bottom: 0;
      }
      /* Même vert que le back-office. */
      .barre {
        --logo-texte: #fff;
        flex-direction: column;
        align-items: stretch;
        gap: 28px;
        height: 100dvh;
        padding: 24px 16px;
        background: #0d3d2b;
        box-shadow: none;
      }
      .barre__logo {
        padding: 0 8px;
      }
      .avatar--mobile {
        display: none;
      }
      .entete {
        display: flex;
      }
      .menu a {
        color: #d7ebe0;
        &:hover {
          background: rgba(255, 255, 255, 0.08);
        }
      }
      .menu a.actif {
        background: var(--vert);
        color: #fff;
      }
      .menu {
        display: flex;
        flex-direction: column;
        margin-right: 0;
      }
      .menu a {
        gap: 10px;
        padding: 11px 12px;
      }
      .deconnexion {
        justify-content: flex-start;
        gap: 10px;
        margin: auto 0 0;
        padding: 11px 12px;
        background: none;
        color: #f6c27a;
        &:hover {
          background: rgba(255, 255, 255, 0.08);
        }
      }
      .contenu {
        width: 100%;
        padding: 28px 32px 40px;
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

  protected readonly nom = computed(() => {
    const u = this.session.utilisateur();
    return u ? `${u.prenom} ${u.nom}` : '';
  });
  protected readonly initiales = computed(() => initiales(this.nom()));
  protected readonly photo = computed(() => urlFichier(this.session.utilisateur()?.photoProfil ?? null));
  protected readonly role = computed(() => {
    const u = this.session.utilisateur();
    if (!u) return '';
    const femme = u.sexe === 'FEMME';
    if (u.role === 'ADMIN') return 'Administrateur';
    if (u.role === 'CONDUCTEUR') {
      return (femme ? 'Conductrice' : 'Conducteur') + (u.conducteurValide ? (femme ? ' vérifiée' : ' vérifié') : '');
    }
    return femme ? 'Passagère' : 'Passager';
  });

  protected readonly entrees = computed<EntreeMenu[]>(() => {
    const role = this.session.utilisateur()?.role;
    const profil: EntreeMenu = { lien: '/profil', libelle: 'Profil', icone: 'utilisateur' };
    if (role === 'ADMIN') return [{ lien: '/admin', libelle: 'Tableau de bord', icone: 'maison' }, profil];
    const menu: EntreeMenu[] = [{ lien: '/accueil', libelle: 'Accueil', icone: 'maison' }];
    // 03 — Trajets
    menu.push({ lien: '/rechercher', libelle: 'Rechercher', icone: 'recherche' });
    menu.push({ lien: '/trajets/publier', libelle: 'Publier', icone: 'plus' });
    if (role === 'CONDUCTEUR') menu.push({ lien: '/trajets/mes-trajets', libelle: 'Mes trajets', icone: 'route' });
    // 04 — Facturation (les paiements et reçus sont accessibles depuis « Réservations »)
    menu.push({ lien: '/reservations', libelle: 'Réservations', icone: 'valide' });
    return [...menu, profil];
  });
}
