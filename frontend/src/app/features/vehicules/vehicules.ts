import { ChangeDetectionStrategy, Component, computed, inject, signal } from '@angular/core';
import { RouterLink } from '@angular/router';
import { forkJoin } from 'rxjs';
import { ErreurApi, lireErreur } from '../../core/api/erreur-api';
import { SessionService } from '../../core/auth/session.service';
import { Alerte } from '../../shared/ui/alerte';
import { EntetePage } from '../../shared/ui/entete-page';
import { Icone } from '../../shared/ui/icone';
import { CarteVehicule } from './carte-vehicule';
import { PieceDocument } from './piece-document';
import { PieceJustificative, Vehicule, VehiculesService, dernierePiece } from './vehicules.service';

/** Écran « Véhicules et documents » (02), d'après la maquette docs/maquettes/Mes véhicules et documents.png. */
@Component({
  selector: 'app-vehicules',
  imports: [RouterLink, EntetePage, Alerte, Icone, CarteVehicule, PieceDocument],
  template: `
    <div class="page">
      <app-entete-page titre="Véhicules et documents" retour="/profil" />

      @if (session.utilisateur()?.conducteurValide) {
        <app-alerte type="succes" titre="Conducteur vérifié">Vous pouvez publier des trajets.</app-alerte>
      } @else {
        <app-alerte type="info">
          Vous pourrez publier des trajets dès que votre permis, votre carte grise et votre pièce d'identité seront validés.
        </app-alerte>
      }

      @if (erreur(); as e) {
        <app-alerte type="erreur">{{ e.message }}</app-alerte>
      }

      <section class="bloc">
        <header class="bloc__entete">
          <h2><app-icone nom="voiture" /> Mes véhicules</h2>
          @if (vehicules().length) {
            <span class="compteur">{{ vehicules().length }} véhicule{{ vehicules().length > 1 ? 's' : '' }}</span>
          }
        </header>
        @for (v of vehicules(); track v.id) {
          <app-carte-vehicule [v]="v" />
        } @empty {
          @if (charge()) {
            <p class="vide">Aucun véhicule pour l'instant. Ajoutez celui avec lequel vous proposerez vos trajets.</p>
          }
        }
        <a class="carte ajouter" routerLink="/vehicules/nouveau"><app-icone nom="plus" [taille]="18" /> Ajouter un véhicule</a>
      </section>

      <section class="bloc">
        <header class="bloc__entete">
          <h2><app-icone nom="document" /> Mes documents</h2>
          @if (charge()) {
            <span class="compteur">{{ valides() }}/{{ attendus() }} validé{{ valides() > 1 ? 's' : '' }}</span>
          }
        </header>

        <app-piece-document type="PERMIS_CONDUIRE" titre="Permis de conduire" detail="Recto et verso" icone="carte-identite"
          [piece]="piece('PERMIS_CONDUIRE')" (envoye)="ajouter($event)" />
        @for (v of vehicules(); track v.id) {
          <app-piece-document type="CARTE_GRISE" titre="Carte grise" [detail]="v.immatriculation" icone="document"
            [idVehicule]="v.id" [piece]="piece('CARTE_GRISE', v.id)" (envoye)="ajouter($event)" />
        }
        <app-piece-document type="PIECE_IDENTITE" titre="Pièce d'identité" detail="CNI sénégalaise ou passeport" icone="utilisateur"
          [piece]="piece('PIECE_IDENTITE')" (envoye)="ajouter($event)" />
        <p class="aide">Formats acceptés : JPEG, PNG ou PDF, 5 Mo au plus. Chaque document est vérifié par notre équipe.</p>
      </section>
    </div>
  `,
  styles: `
    .page {
      display: flex;
      flex-direction: column;
      gap: 18px;
      max-width: 640px;
      margin: 0 auto;
    }
    .compteur {
      padding: 3px 10px;
      border-radius: 999px;
      background: var(--surface-2);
      font-size: 12.5px;
      font-weight: 700;
      color: var(--texte-2);
    }
    .vide {
      margin: 0;
      color: var(--texte-3);
    }
    .ajouter {
      display: flex;
      align-items: center;
      justify-content: center;
      gap: 8px;
      padding: 16px;
      &:hover {
        text-decoration: none;
        box-shadow: 0 0 0 2px var(--vert-clair), var(--ombre);
      }
    }
  `,
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class VehiculesPage {
  protected readonly session = inject(SessionService);
  private readonly api = inject(VehiculesService);

  protected readonly vehicules = signal<Vehicule[]>([]);
  private readonly pieces = signal<PieceJustificative[]>([]);
  protected readonly charge = signal(false);
  protected readonly erreur = signal<ErreurApi | null>(null);

  /** Permis + pièce d'identité + une carte grise par véhicule. */
  protected readonly attendus = computed(() => 2 + this.vehicules().length);
  protected readonly valides = computed(() => {
    const p = this.pieces();
    const cartes = this.vehicules().filter((v) => dernierePiece(p, 'CARTE_GRISE', v.id)?.statutValidation === 'VALIDE');
    return (
      [dernierePiece(p, 'PERMIS_CONDUIRE'), dernierePiece(p, 'PIECE_IDENTITE')].filter((d) => d?.statutValidation === 'VALIDE')
        .length + cartes.length
    );
  });

  constructor() {
    forkJoin([this.api.mesVehicules(), this.api.mesDocuments()]).subscribe({
      next: ([vehicules, pieces]) => {
        this.vehicules.set(vehicules);
        this.pieces.set(pieces);
        this.charge.set(true);
      },
      error: (e) => this.erreur.set(lireErreur(e)),
    });
  }

  protected piece(type: PieceJustificative['typeDocument'], idVehicule: number | null = null): PieceJustificative | null {
    return dernierePiece(this.pieces(), type, idVehicule);
  }

  /** La nouvelle pièce passe en tête : c'est elle qui s'affiche désormais pour son emplacement. */
  protected ajouter(p: PieceJustificative): void {
    this.pieces.update((liste) => [p, ...liste]);
  }
}
