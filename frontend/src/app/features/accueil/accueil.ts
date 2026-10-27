import { ChangeDetectionStrategy, Component, computed, inject } from '@angular/core';
import { SessionService } from '../../core/auth/session.service';

/** Page d'arrivée après connexion. Chaque fonctionnalité y ajoutera ses raccourcis. */
@Component({
  selector: 'app-accueil',
  template: `
    @if (session.utilisateur(); as u) {
      <section class="carte">
        <h1>Bienvenue, {{ u.prenom }} 👋</h1>
        <p>Vous êtes connecté en tant {{ libelleRole() === 'administrateur' ? "qu'" : 'que ' }}<strong>{{ libelleRole() }}</strong>.</p>
        <p class="note">Les fonctionnalités de YOBALEMAsn arrivent bientôt sur cette page.</p>
      </section>
    }
  `,
  styles: `
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
