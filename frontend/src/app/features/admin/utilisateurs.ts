import { DatePipe } from '@angular/common';
import { ChangeDetectionStrategy, Component, inject, signal } from '@angular/core';
import { FormControl, ReactiveFormsModule } from '@angular/forms';
import { RouterLink } from '@angular/router';
import { ErreurApi, lireErreur } from '../../core/api/erreur-api';
import { StatutCompte } from '../../core/auth/auth.models';
import { Alerte } from '../../shared/ui/alerte';
import { Icone } from '../../shared/ui/icone';
import { formaterTelephone, initiales } from '../profil/profil.service';
import { AdminService, LIBELLES_STATUT, Page, UtilisateurLigne } from './admin.service';

/** Liste des utilisateurs du back-office : recherche (nom, email, téléphone), filtre par statut, pagination. */
@Component({
  selector: 'app-admin-utilisateurs',
  imports: [ReactiveFormsModule, RouterLink, DatePipe, Icone, Alerte],
  template: `
    <h1>Utilisateurs</h1>
    <form class="filtres" (submit)="$event.preventDefault(); aller(0)">
      <div class="saisie">
        <app-icone nom="recherche" [taille]="18" />
        <input [formControl]="recherche" placeholder="Nom, email ou téléphone…" aria-label="Rechercher un utilisateur" />
      </div>
      <select [formControl]="statut" aria-label="Statut du compte">
        <option value="">Tous les statuts</option>
        @for (s of statuts; track s[0]) {
          <option [value]="s[0]">{{ s[1] }}</option>
        }
      </select>
      <button class="bouton bouton--primaire" type="submit">Rechercher</button>
    </form>

    @if (erreur(); as e) {
      <app-alerte type="erreur">{{ e.message }}</app-alerte>
    }

    @if (resultat(); as r) {
      <p class="compte">{{ r.page.totalElements }} utilisateur{{ r.page.totalElements > 1 ? 's' : '' }}</p>
      <ul class="liste">
        @for (u of r.content; track u.id) {
          <li>
            <a class="carte ligne" [routerLink]="['/admin/utilisateurs', u.id]">
              <span class="avatar">{{ initiales(u.prenom + ' ' + u.nom) }}</span>
              <span class="ligne__texte">
                <strong>{{ u.prenom }} {{ u.nom }}</strong>
                <small>{{ u.email || '—' }} • {{ u.telephone ? telephone(u.telephone) : '—' }}</small>
              </span>
              <span class="ligne__etats">
                <span class="pastille" [class.pastille--succes]="u.statut === 'ACTIF'"
                  [class.pastille--erreur]="u.statut === 'BLOQUE' || u.statut === 'BANNI'"
                  [class.pastille--attente]="u.statut === 'DESACTIVE' || u.statut === 'EN_ATTENTE_OTP'">{{ libelles[u.statut] }}</span>
                <span class="role">{{ u.role === 'ADMIN' ? 'Admin' : u.role === 'CONDUCTEUR' ? (u.conducteurValide ? 'Conducteur vérifié' : 'Conducteur') : 'Passager' }}</span>
              </span>
              <small class="ligne__date">Inscrit le {{ u.dateCreation | date: 'dd/MM/yyyy' }}</small>
            </a>
          </li>
        } @empty {
          <li class="vide">Aucun utilisateur ne correspond à cette recherche.</li>
        }
      </ul>
      @if (r.page.totalPages > 1) {
        <nav class="pagination" aria-label="Pages">
          <button class="bouton-lien" type="button" [disabled]="r.page.number === 0" (click)="aller(r.page.number - 1)">Précédent</button>
          <span>Page {{ r.page.number + 1 }} / {{ r.page.totalPages }}</span>
          <button class="bouton-lien" type="button" [disabled]="r.page.number + 1 >= r.page.totalPages" (click)="aller(r.page.number + 1)">Suivant</button>
        </nav>
      }
    }
  `,
  styles: `
    h1 {
      margin-bottom: 16px;
      font-size: 28px;
    }
    .filtres {
      display: flex;
      flex-wrap: wrap;
      gap: 10px;
      .saisie {
        flex: 1 1 260px;
      }
      select {
        min-height: 50px;
        padding: 0 12px;
        border: 0;
        border-radius: var(--rayon);
        background: var(--surface);
        box-shadow: var(--ombre);
        font: inherit;
      }
      .bouton {
        width: auto;
        padding: 0 20px;
      }
    }
    .compte {
      color: var(--texte-2);
    }
    .liste {
      display: flex;
      flex-direction: column;
      gap: 8px;
      margin: 0;
      padding: 0;
      list-style: none;
    }
    .ligne {
      display: flex;
      flex-wrap: wrap;
      align-items: center;
      gap: 12px 14px;
      padding: 14px 16px;
      color: var(--texte);
      font-weight: 400;
      &:hover {
        text-decoration: none;
        box-shadow: 0 0 0 2px var(--vert-clair), var(--ombre);
      }
    }
    .avatar {
      display: grid;
      place-items: center;
      flex: none;
      width: 42px;
      height: 42px;
      border-radius: 50%;
      background: var(--menthe);
      font-weight: 700;
      color: var(--vert-fonce);
    }
    .ligne__texte {
      display: flex;
      flex: 1 1 220px;
      flex-direction: column;
      min-width: 0;
      small {
        overflow: hidden;
        text-overflow: ellipsis;
        white-space: nowrap;
        color: var(--texte-3);
      }
    }
    .ligne__etats {
      display: flex;
      align-items: center;
      gap: 8px;
    }
    .role,
    .ligne__date {
      font-size: 13px;
      color: var(--texte-2);
    }
    .vide {
      padding: 24px;
      text-align: center;
      color: var(--texte-3);
    }
    .pagination {
      display: flex;
      align-items: center;
      justify-content: center;
      gap: 16px;
      margin-top: 16px;
    }
  `,
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class AdminUtilisateurs {
  private readonly admin = inject(AdminService);

  protected readonly libelles = LIBELLES_STATUT;
  protected readonly statuts = Object.entries(LIBELLES_STATUT) as [StatutCompte, string][];
  protected readonly initiales = initiales;
  protected readonly telephone = formaterTelephone;
  protected readonly recherche = new FormControl('', { nonNullable: true });
  protected readonly statut = new FormControl<StatutCompte | ''>('', { nonNullable: true });
  protected readonly resultat = signal<Page<UtilisateurLigne> | null>(null);
  protected readonly erreur = signal<ErreurApi | null>(null);

  constructor() {
    this.aller(0);
    this.statut.valueChanges.subscribe(() => this.aller(0));
  }

  protected aller(page: number): void {
    this.erreur.set(null);
    this.admin.utilisateurs(this.recherche.value, this.statut.value, page).subscribe({
      next: (r) => this.resultat.set(r),
      error: (e) => this.erreur.set(lireErreur(e)),
    });
  }
}
