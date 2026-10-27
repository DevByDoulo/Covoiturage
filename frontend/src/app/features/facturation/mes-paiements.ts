import { DatePipe } from '@angular/common';
import { ChangeDetectionStrategy, Component, OnInit, computed, inject, signal } from '@angular/core';
import { RouterLink } from '@angular/router';
import { ErreurApi, lireErreur } from '../../core/api/erreur-api';
import { FcfaPipe } from '../../shared/format/formats';
import { Alerte } from '../../shared/ui/alerte';
import { LIBELLES_MOYEN, LIBELLES_STATUT_PAIEMENT, LignePaiement, totalEncaisse } from '../reservations/reservations.models';
import { ReservationsService } from '../reservations/reservations.service';

/** 04 — Historique : paiements effectués (passager) et encaissements (conducteur), avec accès aux reçus. */
@Component({
  selector: 'app-mes-paiements',
  imports: [RouterLink, DatePipe, FcfaPipe, Alerte],
  template: `
    <h1>Mes paiements</h1>
    @if (erreur(); as e) {
      <app-alerte type="erreur">{{ e.message }}</app-alerte>
    }
    @if (lignes(); as liste) {
      @if (encaisse() > 0) {
        <p class="resume">Encaissé comme conducteur : <strong>{{ encaisse() | fcfa }}</strong></p>
      }
      @if (liste.length === 0) {
        <p class="aide">Aucun paiement pour l'instant.</p>
      }
      <ul>
        @for (l of liste; track l.referenceTransaction) {
          <li class="carte">
            <div>
              <strong>{{ l.trajet }}</strong>
              <small>{{ l.dateHeureDepart | date: 'd MMM y, HH:mm' }} ·
                {{ l.role === 'PASSAGER' ? 'Conducteur' : 'Passager' }} : {{ l.contrepartie }}</small>
              <small>{{ moyens[l.moyen] }} · {{ statuts[l.statut] }} · réf. {{ l.referenceTransaction }}</small>
            </div>
            <div class="montant">
              <strong [class.entree]="l.role === 'CONDUCTEUR'">{{ l.role === 'CONDUCTEUR' ? '+' : '−' }} {{ l.montant | fcfa }}</strong>
              @if (l.statut === 'REUSSI' || l.statut === 'REMBOURSE') {
                <a [routerLink]="['/paiements', l.referenceTransaction, 'recu']">Reçu</a>
              }
            </div>
          </li>
        }
      </ul>
    } @else {
      <p class="aide"><span class="chargement chargement--sombre"></span> Chargement…</p>
    }
  `,
  styles: `
    :host {
      display: block;
      max-width: 720px;
      margin: 0 auto;
      padding: 16px;
    }
    ul {
      display: grid;
      gap: 10px;
      margin: 0;
      padding: 0;
      list-style: none;
    }
    li {
      display: flex;
      justify-content: space-between;
      gap: 12px;
      padding: 12px 14px;
    }
    li div {
      display: grid;
      gap: 2px;
    }
    small,
    .aide {
      color: var(--texte-2);
    }
    .montant {
      justify-items: end;
      text-align: right;
      white-space: nowrap;
    }
    .entree {
      color: var(--vert);
    }
    .resume {
      margin: 0 0 12px;
    }
  `,
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class MesPaiements implements OnInit {
  private readonly service = inject(ReservationsService);

  protected readonly moyens = LIBELLES_MOYEN;
  protected readonly statuts = LIBELLES_STATUT_PAIEMENT;
  protected readonly lignes = signal<LignePaiement[] | null>(null);
  protected readonly erreur = signal<ErreurApi | null>(null);
  protected readonly encaisse = computed(() => totalEncaisse(this.lignes() ?? []));

  ngOnInit(): void {
    this.service.historique().subscribe({
      next: (l) => this.lignes.set(l),
      error: (e) => {
        this.erreur.set(lireErreur(e));
        this.lignes.set([]);
      },
    });
  }
}
