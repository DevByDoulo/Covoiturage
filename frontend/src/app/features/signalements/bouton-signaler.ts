import { ChangeDetectionStrategy, Component, input } from '@angular/core';
import { RouterLink } from '@angular/router';
import { Icone } from '../../shared/ui/icone';

/** Lien « Signaler » à poser près d'une personne rencontrée lors d'un trajet : ouvre le formulaire de signalement. */
@Component({
  selector: 'app-bouton-signaler',
  imports: [RouterLink, Icone],
  template: `
    <a class="bouton-lien" [routerLink]="['/signaler', idUtilisateur()]"
       [queryParams]="{ trajet: idTrajet() ?? null, nom: nom() }">
      <app-icone nom="drapeau" [taille]="16" /> Signaler {{ nom() }}
    </a>
  `,
  styles: `:host { display: contents; }`,
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class BoutonSignaler {
  readonly idUtilisateur = input.required<number>();
  readonly idTrajet = input<number | null>(null);
  readonly nom = input.required<string>();
}
