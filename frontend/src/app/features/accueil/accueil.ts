import { ChangeDetectionStrategy, Component, computed, inject } from '@angular/core';
import { RouterLink } from '@angular/router';
import { SessionService } from '../../core/auth/session.service';
import { Icone } from '../../shared/ui/icone';

/** Page d'arrivée après connexion : raccourcis vers les fonctionnalités disponibles. */
@Component({
  selector: 'app-accueil',
  imports: [Icone, RouterLink],
  template: `
    @if (session.utilisateur(); as u) {
      <section class="carte">
        <h1>Bonjour {{ u.prenom }} 👋</h1>
        <p>Vous êtes connecté en tant {{ libelleRole() === 'administrateur' ? "qu'" : 'que ' }}<strong>{{ libelleRole() }}</strong>.</p>
        @if (u.role === 'CONDUCTEUR' && !u.conducteurValide) {
          <p class="note">Vos documents sont en cours de vérification par notre équipe.</p>
        }
      </section>

      @if (u.role !== 'ADMIN') {
        <div class="raccourcis">
          <a class="carte raccourci" routerLink="/trajets/publier">
            <span class="raccourci__icone"><app-icone nom="plus" [taille]="24" /></span>
            <span><strong>Publier un trajet</strong><br /><small>Le prix est calculé pour vous</small></span>
          </a>
          @if (u.role === 'CONDUCTEUR') {
            <a class="carte raccourci" routerLink="/trajets/mes-trajets">
              <span class="raccourci__icone"><app-icone nom="liste" [taille]="24" /></span>
              <span><strong>Mes trajets</strong><br /><small>Suivre, modifier, démarrer</small></span>
            </a>
          }
        </div>
      }
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
    .raccourcis {
      display: grid;
      grid-template-columns: repeat(auto-fit, minmax(240px, 1fr));
      gap: 12px;
      margin-top: 16px;
    }
    .raccourci {
      display: flex;
      align-items: center;
      gap: 14px;
      color: var(--texte);
      font-weight: 400;
      &:hover {
        text-decoration: none;
        box-shadow: 0 0 0 2px var(--vert-clair), var(--ombre);
      }
      small {
        color: var(--texte-3);
      }
    }
    .raccourci__icone {
      display: grid;
      place-items: center;
      width: 48px;
      height: 48px;
      border-radius: 14px;
      background: var(--vert-clair);
      color: var(--vert);
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
