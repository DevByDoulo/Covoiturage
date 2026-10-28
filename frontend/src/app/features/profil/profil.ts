import { ChangeDetectionStrategy, Component, inject } from '@angular/core';
import { RouterLink } from '@angular/router';
import { SessionService } from '../../core/auth/session.service';
import { Icone } from '../../shared/ui/icone';
import { APropos } from './a-propos';
import { ContactsUrgence } from './contacts-urgence';
import { EnteteProfil } from './entete-profil';
import { PreferencesTrajet } from './preferences-trajet';

/** Écran « Mon profil » (01 Gestion des utilisateurs), d'après la maquette docs/maquettes/Mon profil CoVoitIA.png. */
@Component({
  selector: 'app-profil',
  imports: [RouterLink, Icone, EnteteProfil, APropos, PreferencesTrajet, ContactsUrgence],
  template: `
    @if (session.utilisateur(); as u) {
      <div class="pile">
        <app-entete-profil [profil]="u" />
        <app-a-propos [profil]="u" />
        @if (u.role !== 'ADMIN') {
          <app-preferences-trajet [valeurs]="u.preferences" />
          <app-contacts-urgence />
        }

        <nav class="carte menu" aria-label="Mon compte">
          @if (u.role !== 'ADMIN') {
            <a routerLink="/vehicules" class="menu__vehicules">
              <span class="pictogramme"><app-icone nom="voiture" [taille]="19" /></span>
              <span class="menu__texte">
                Mes véhicules et documents
                <small>{{ u.conducteurValide ? 'Conducteur vérifié' : 'Permis, carte grise, pièce d’identité' }}</small>
              </span>
              <app-icone nom="chevron-droite" [taille]="18" />
            </a>
          }
          <a routerLink="/profil/mot-de-passe">
            <span class="pictogramme"><app-icone nom="cadenas-rotation" [taille]="19" /></span>
            <span class="menu__texte">{{ u.motDePasseDefini ? 'Changer le mot de passe' : 'Définir un mot de passe' }}</span>
            <app-icone nom="chevron-droite" [taille]="18" />
          </a>
          @if (u.role !== 'ADMIN') {
            <a routerLink="/profil/desactivation" class="menu__danger">
              <span class="pictogramme"><app-icone nom="utilisateur-barre" [taille]="19" /></span>
              <span class="menu__texte">Désactiver mon compte</span>
              <app-icone nom="chevron-droite" [taille]="18" />
            </a>
          }
        </nav>

        <button class="bouton deconnexion" type="button" (click)="session.demanderDeconnexion()">
          <app-icone nom="deconnexion" [taille]="18" /> Se déconnecter
        </button>
        <p class="version">YOBALEMAsn • Teranga &amp; mobilité au Sénégal</p>
      </div>
    }
  `,
  styles: `
    .pile {
      display: flex;
      flex-direction: column;
      gap: 16px;
      max-width: 640px;
      margin: 0 auto;
    }
    .menu {
      display: flex;
      flex-direction: column;
      gap: 4px;
      padding: 10px;
      a {
        display: flex;
        align-items: center;
        gap: 12px;
        padding: 10px;
        border-radius: var(--rayon);
        color: var(--texte);
        text-decoration: none;
        &:hover {
          background: var(--surface-2);
        }
      }
    }
    .menu__texte {
      display: flex;
      flex: 1;
      flex-direction: column;
      font-weight: 700;
      small {
        font-weight: 600;
        color: var(--vert);
      }
    }
    .menu__vehicules {
      background: var(--surface-2);
    }
    .pictogramme {
      display: grid;
      place-items: center;
      width: 40px;
      height: 40px;
      border-radius: 50%;
      background: var(--surface-2);
      color: var(--texte-2);
    }
    .menu__danger {
      color: var(--erreur) !important;
      .pictogramme {
        background: var(--erreur-fond);
        color: var(--erreur);
      }
    }
    .deconnexion {
      background: var(--info-fond);
      color: var(--texte);
    }
    .version {
      margin: 0;
      text-align: center;
      font-size: 12.5px;
      color: var(--texte-3);
    }
  `,
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class ProfilPage {
  protected readonly session = inject(SessionService);
}
