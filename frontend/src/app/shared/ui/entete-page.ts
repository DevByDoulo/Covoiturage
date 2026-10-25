import { ChangeDetectionStrategy, Component, input } from '@angular/core';
import { RouterLink } from '@angular/router';
import { Icone } from './icone';
import { Logo } from './logo';

/** Barre de titre des écrans secondaires : retour, petit logo, titre. */
@Component({
  selector: 'app-entete-page',
  imports: [RouterLink, Icone, Logo],
  template: `
    <header class="entete">
      <a class="entete__retour" [routerLink]="retour()" aria-label="Retour"><app-icone nom="fleche-gauche" [taille]="22" /></a>
      <span class="entete__logo"><app-logo [compact]="true" /></span>
      <h1 class="entete__titre">{{ titre() }}</h1>
    </header>
  `,
  styles: `
    .entete {
      display: flex;
      align-items: center;
      gap: 10px;
      padding: 14px 4px;
    }
    .entete__retour {
      display: grid;
      place-items: center;
      width: 36px;
      height: 36px;
      margin-left: -6px;
      border-radius: 10px;
      color: var(--texte);
      &:hover {
        background: var(--surface-2);
      }
    }
    .entete__logo {
      display: grid;
      place-items: center;
      width: 32px;
      height: 32px;
      border-radius: 8px;
      background: #f3f1e7;
    }
    .entete__titre {
      font-size: 19px;
      font-weight: 700;
    }
  `,
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class EntetePage {
  readonly titre = input.required<string>();
  readonly retour = input('/auth/connexion');
}
