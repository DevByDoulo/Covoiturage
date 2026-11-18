import { ChangeDetectionStrategy, Component } from '@angular/core';
import { RouterLink } from '@angular/router';
import { Lieu } from '../../core/carte/geocodage';
import { Icone } from '../../shared/ui/icone';
import { aujourdhui, parametresRecherche } from '../recherche/parametres-recherche';

export interface ItinerairePopulaire {
  depart: Lieu;
  arrivee: Lieu;
}

const DAKAR: Lieu = { libelle: 'Dakar', latitude: 14.6937, longitude: -17.4441 };
const THIES: Lieu = { libelle: 'Thiès', latitude: 14.791, longitude: -16.9359 };
const MBOUR: Lieu = { libelle: 'Mbour', latitude: 14.4198, longitude: -16.964 };
const SAINT_LOUIS: Lieu = { libelle: 'Saint-Louis', latitude: 16.0179, longitude: -16.4896 };
const TOUBA: Lieu = { libelle: 'Touba', latitude: 14.85, longitude: -15.8833 };
const KAOLACK: Lieu = { libelle: 'Kaolack', latitude: 14.1652, longitude: -16.0758 };

/**
 * Itinéraires proposés sur l'accueil public. Liste fixe : l'API ne fournit pas de statistiques de popularité, et
 * l'estimation du prix est réservée aux conducteurs (elle demande un véhicule). On n'affiche donc aucun prix.
 */
export const ITINERAIRES_POPULAIRES: ItinerairePopulaire[] = [
  { depart: DAKAR, arrivee: THIES },
  { depart: DAKAR, arrivee: MBOUR },
  { depart: DAKAR, arrivee: SAINT_LOUIS },
  { depart: DAKAR, arrivee: TOUBA },
  { depart: DAKAR, arrivee: KAOLACK },
  { depart: THIES, arrivee: DAKAR },
];

/** Paramètres de la page Rechercher pour un itinéraire populaire : départ, arrivée, aujourd'hui, 1 passager. */
export function parametresItineraire(i: ItinerairePopulaire, date = aujourdhui()) {
  return parametresRecherche(i.depart, i.arrivee, date, 1);
}

/** Accueil public : itinéraires courants du Sénégal ; un clic lance la recherche du jour. */
@Component({
  selector: 'app-trajets-populaires',
  imports: [RouterLink, Icone],
  template: `
    <section aria-labelledby="titre-populaires">
      <h2 id="titre-populaires">Trajets populaires</h2>
      <ul>
        @for (i of itineraires; track i.depart.libelle + i.arrivee.libelle) {
          <li>
            <a class="itineraire" routerLink="/rechercher" [queryParams]="parametres(i)">
              <app-icone nom="route" [taille]="18" />
              <span>{{ i.depart.libelle }} <span aria-hidden="true">→</span><span class="sr-only">vers</span> {{ i.arrivee.libelle }}</span>
              <app-icone nom="chevron-droite" [taille]="18" />
            </a>
          </li>
        }
      </ul>
    </section>
  `,
  styles: `
    h2 { font-size: 20px; margin-bottom: 14px; }
    ul { display: grid; gap: 10px; margin: 0; padding: 0; list-style: none; }
    @media (min-width: 640px) { ul { grid-template-columns: repeat(2, 1fr); } }
    @media (min-width: 960px) { ul { grid-template-columns: repeat(3, 1fr); } }
    .itineraire {
      display: flex;
      align-items: center;
      gap: 10px;
      padding: 14px 16px;
      border-radius: var(--rayon);
      background: var(--surface);
      box-shadow: var(--ombre);
      color: var(--texte);
      > span { flex: 1; }
      app-icone { color: var(--vert); }
      &:hover { text-decoration: none; box-shadow: 0 0 0 2px var(--vert-clair), var(--ombre); }
    }
  `,
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class TrajetsPopulaires {
  protected readonly itineraires = ITINERAIRES_POPULAIRES;
  protected readonly parametres = (i: ItinerairePopulaire) => parametresItineraire(i);
}
