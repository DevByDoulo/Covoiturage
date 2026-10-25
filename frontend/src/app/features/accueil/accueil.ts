import { ChangeDetectionStrategy, Component, computed, inject } from '@angular/core';
import { SessionService } from '../../core/auth/session.service';
import { Icone } from '../../shared/ui/icone';
import { Logo } from '../../shared/ui/logo';

/** Page d'arrivée provisoire après connexion, en attendant les écrans métier (recherche, profil, back-office). */
@Component({
  selector: 'app-accueil',
  imports: [Logo, Icone],
  template: `
    <header class="barre">
      <app-logo />
      <button class="deconnexion" type="button" (click)="session.deconnexion()">
        <app-icone nom="deconnexion" [taille]="18" /> Déconnexion
      </button>
    </header>
    <main class="contenu">
      @if (session.utilisateur(); as u) {
        <section class="carte">
          <h1>Bonjour {{ u.prenom }} 👋</h1>
          <p>Vous êtes connecté en tant {{ libelleRole() === 'administrateur' ? "qu'" : 'que ' }}<strong>{{ libelleRole() }}</strong>.</p>
          @if (u.role === 'CONDUCTEUR' && !u.conducteurValide) {
            <p class="note">Vos documents sont en cours de vérification par notre équipe.</p>
          }
          <p class="note">Les écrans de recherche, de profil et de gestion arrivent dans les prochaines étapes.</p>
        </section>
      }
    </main>
  `,
  styles: `
    .barre {
      display: flex;
      align-items: center;
      justify-content: space-between;
      padding: 12px 16px;
      background: var(--surface);
      box-shadow: var(--ombre);
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
    .contenu {
      max-width: 720px;
      margin: 0 auto;
      padding: 24px 16px;
    }
    h1 {
      font-size: 24px;
      margin-bottom: 8px;
    }
    .note {
      color: var(--texte-2);
    }
  `,
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class Accueil {
  protected readonly session = inject(SessionService);
  protected readonly libelleRole = computed(
    () =>
      ({ PASSAGER: 'passager', CONDUCTEUR: 'conducteur', ADMIN: 'administrateur' })[
        this.session.utilisateur()?.role ?? 'PASSAGER'
      ],
  );
}
