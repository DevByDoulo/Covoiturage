import { ChangeDetectionStrategy, Component, computed, input } from '@angular/core';
import { RouterLink } from '@angular/router';
import { Icone } from '../../shared/ui/icone';
import { urlFichier } from '../profil/profil.service';
import { LIBELLES_ENERGIE, Vehicule } from './vehicules.service';

/** Carte d'un véhicule : photo, modèle, immatriculation, énergie, places, puissance, statut, modification. */
@Component({
  selector: 'app-carte-vehicule',
  imports: [RouterLink, Icone],
  template: `
    <article class="carte vehicule">
      <div class="vehicule__photo">
        @if (photo(); as url) {
          <img [src]="url" alt="" />
        } @else {
          <app-icone nom="voiture" [taille]="30" />
        }
      </div>
      <div class="vehicule__texte">
        <strong>{{ v().marque }} {{ v().modele }} {{ v().annee }}</strong>
        <span class="plaque">{{ v().immatriculation }}</span>
        <div class="caracteristiques">
          <span>{{ energie() }}</span>
          <span>{{ v().nombrePlaces }} places</span>
          <span>{{ v().puissanceFiscale }} CV</span>
        </div>
        @switch (v().statutValidation) {
          @case ('VALIDE') {
            <span class="pastille pastille--succes">Carte grise validée</span>
          }
          @case ('REFUSE') {
            <span class="pastille pastille--erreur">Carte grise refusée</span>
          }
          @default {
            <span class="pastille pastille--attente">En attente de validation</span>
          }
        }
      </div>
      <a class="bouton-rond" [routerLink]="['/vehicules', v().id]" [attr.aria-label]="'Modifier ' + v().marque + ' ' + v().modele">
        <app-icone nom="crayon" [taille]="17" />
      </a>
    </article>
  `,
  styles: `
    .vehicule {
      display: flex;
      align-items: flex-start;
      gap: 14px;
    }
    .vehicule__photo {
      display: grid;
      place-items: center;
      flex: none;
      width: 72px;
      height: 72px;
      overflow: hidden;
      border-radius: 14px;
      background: var(--surface-2);
      color: var(--texte-3);
      img {
        width: 100%;
        height: 100%;
        object-fit: cover;
      }
    }
    .vehicule__texte {
      display: flex;
      flex: 1;
      flex-direction: column;
      align-items: flex-start;
      gap: 6px;
      min-width: 0;
    }
    .plaque {
      padding: 2px 8px;
      border-radius: 6px;
      background: var(--surface-2);
      font-size: 13px;
      font-weight: 700;
      letter-spacing: 0.04em;
    }
    .caracteristiques {
      display: flex;
      flex-wrap: wrap;
      gap: 6px;
      span {
        padding: 2px 8px;
        border-radius: 999px;
        background: var(--info-fond);
        font-size: 12.5px;
        color: var(--texte-2);
      }
    }
  `,
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class CarteVehicule {
  readonly v = input.required<Vehicule>();
  protected readonly photo = computed(() => urlFichier(this.v().photo));
  protected readonly energie = computed(() => LIBELLES_ENERGIE[this.v().typeEnergie]);
}
