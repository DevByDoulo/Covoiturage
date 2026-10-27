import { ChangeDetectionStrategy, Component, inject, signal } from '@angular/core';
import { RouterLink } from '@angular/router';
import { ErreurApi, lireErreur } from '../../core/api/erreur-api';
import { Alerte } from '../../shared/ui/alerte';
import { Icone, NomIcone } from '../../shared/ui/icone';
import { AdminService, Statistiques } from './admin.service';

interface Indicateur {
  cle: keyof Statistiques;
  libelle: string;
  icone: NomIcone;
}

const INDICATEURS: Indicateur[] = [
  { cle: 'utilisateurs', libelle: 'Utilisateurs inscrits', icone: 'utilisateurs' },
  { cle: 'comptesActifs', libelle: 'Comptes actifs', icone: 'valide' },
  { cle: 'conducteurs', libelle: 'Conducteurs', icone: 'voiture' },
  { cle: 'conducteursValides', libelle: 'Conducteurs vérifiés', icone: 'bouclier' },
  { cle: 'comptesBloques', libelle: 'Comptes bloqués ou bannis', icone: 'utilisateur-barre' },
];

/** Tableau de bord du back-office : chiffres clés et accès direct à la file de validation. */
@Component({
  selector: 'app-tableau-de-bord',
  imports: [RouterLink, Icone, Alerte],
  template: `
    <h1>Tableau de bord</h1>
    @if (erreur(); as e) {
      <app-alerte type="erreur">{{ e.message }}</app-alerte>
    }
    @if (stats(); as s) {
      <a class="carte a-valider" routerLink="/admin/documents" [class.a-valider--vide]="!s.documentsEnAttente">
        <span class="a-valider__icone"><app-icone nom="document" [taille]="26" /></span>
        <span>
          <strong>{{ s.documentsEnAttente }}</strong>
          document{{ s.documentsEnAttente > 1 ? 's' : '' }} en attente de vérification
          <small>{{ s.documentsEnAttente ? 'Les conducteurs attendent votre décision pour publier.' : 'Tout est à jour.' }}</small>
        </span>
        <app-icone nom="chevron-droite" />
      </a>
      <div class="grille">
        @for (i of indicateurs; track i.cle) {
          <div class="carte indicateur">
            <span class="indicateur__icone"><app-icone [nom]="i.icone" /></span>
            <strong>{{ s[i.cle] }}</strong>
            <span>{{ i.libelle }}</span>
          </div>
        }
      </div>
    }
  `,
  styles: `
    h1 {
      margin-bottom: 18px;
      font-size: 28px;
    }
    .a-valider {
      display: flex;
      align-items: center;
      gap: 16px;
      margin-bottom: 18px;
      color: var(--texte);
      font-weight: 400;
      background: var(--orange-clair);
      &:hover {
        text-decoration: none;
      }
      > span:nth-child(2) {
        flex: 1;
      }
      strong {
        font-size: 22px;
      }
      small {
        display: block;
        color: var(--texte-2);
      }
    }
    .a-valider--vide {
      background: var(--vert-clair);
    }
    .a-valider__icone,
    .indicateur__icone {
      display: grid;
      place-items: center;
      width: 52px;
      height: 52px;
      border-radius: 14px;
      background: var(--surface);
      color: var(--vert);
    }
    .grille {
      display: grid;
      grid-template-columns: repeat(auto-fill, minmax(190px, 1fr));
      gap: 14px;
    }
    .indicateur {
      display: flex;
      flex-direction: column;
      gap: 6px;
      strong {
        font-size: 30px;
      }
      span:last-child {
        color: var(--texte-2);
      }
    }
    .indicateur__icone {
      width: 40px;
      height: 40px;
      background: var(--vert-clair);
    }
  `,
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class TableauDeBord {
  private readonly admin = inject(AdminService);
  protected readonly indicateurs = INDICATEURS;
  protected readonly stats = signal<Statistiques | null>(null);
  protected readonly erreur = signal<ErreurApi | null>(null);

  constructor() {
    this.admin.statistiques().subscribe({
      next: (s) => this.stats.set(s),
      error: (e) => this.erreur.set(lireErreur(e)),
    });
  }
}
