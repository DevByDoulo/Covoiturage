import { DatePipe } from '@angular/common';
import { ChangeDetectionStrategy, Component, OnInit, inject, input, signal } from '@angular/core';
import { RouterLink } from '@angular/router';
import { ErreurApi, lireErreur } from '../../core/api/erreur-api';
import { FcfaPipe } from '../../shared/format/formats';
import { Alerte } from '../../shared/ui/alerte';
import { Logo } from '../../shared/ui/logo';
import { LIBELLES_MOYEN, LIBELLES_STATUT_PAIEMENT, Recu } from '../reservations/reservations.models';
import { ReservationsService } from '../reservations/reservations.service';

/** 04 — Reçu d'un paiement, imprimable (ou enregistrable en PDF depuis le navigateur). */
@Component({
  selector: 'app-recu',
  imports: [RouterLink, DatePipe, FcfaPipe, Alerte, Logo],
  template: `
    @if (erreur(); as e) {
      <app-alerte type="erreur">{{ e.message }}</app-alerte>
      <a routerLink="/paiements">Retour à mes paiements</a>
    } @else if (recu(); as r) {
      <article class="carte recu">
        <header>
          <app-logo />
          <div>
            <h1>Reçu de paiement</h1>
            <span>N° {{ r.referenceTransaction }}</span>
          </div>
        </header>
        @if (r.statut === 'REMBOURSE') {
          <p class="rembourse">Remboursé intégralement le {{ r.dateRemboursement | date: 'd MMMM y à HH:mm' }}</p>
        }
        <dl>
          <div><dt>Date du paiement</dt><dd>{{ r.dateConfirmation | date: 'd MMMM y à HH:mm' }}</dd></div>
          <div><dt>Trajet</dt><dd>{{ r.trajet }}, le {{ r.dateHeureDepart | date: 'd MMMM y à HH:mm' }}</dd></div>
          <div><dt>Passager</dt><dd>{{ r.passager }}</dd></div>
          <div><dt>Conducteur</dt><dd>{{ r.conducteur }}</dd></div>
          <div><dt>Places</dt><dd>{{ r.nombrePlaces }} × {{ r.prixUnitaire | fcfa }}</dd></div>
          <div><dt>Moyen de paiement</dt><dd>{{ moyens[r.moyen] }}@if (r.referenceOperateur) { (réf. {{ r.referenceOperateur }}) }</dd></div>
          <div><dt>Commission YOBALEMAsn</dt><dd>{{ r.commission | fcfa }}</dd></div>
          <div class="total"><dt>Montant payé</dt><dd>{{ r.montant | fcfa }}</dd></div>
          <div><dt>Statut</dt><dd>{{ statuts[r.statut] }}</dd></div>
        </dl>
        <p class="mention">Covoiturage entre particuliers : le montant correspond au partage des frais du trajet.</p>
      </article>
      <div class="actions">
        <a routerLink="/paiements" class="bouton bouton--secondaire">Retour</a>
        <button type="button" class="bouton bouton--primaire" (click)="imprimer()">Imprimer / PDF</button>
      </div>
    } @else {
      <p><span class="chargement chargement--sombre"></span> Chargement…</p>
    }
  `,
  styles: `
    :host {
      display: grid;
      gap: 16px;
      max-width: 640px;
      margin: 0 auto;
      padding: 16px;
    }
    .recu {
      padding: 24px;
    }
    header {
      display: flex;
      align-items: center;
      justify-content: space-between;
      gap: 12px;
      margin-bottom: 16px;
    }
    header div {
      text-align: right;
    }
    h1 {
      margin: 0;
      font-size: 20px;
    }
    dl {
      display: grid;
      gap: 8px;
      margin: 0;
    }
    dl div {
      display: flex;
      justify-content: space-between;
      gap: 12px;
    }
    dt {
      color: var(--texte-2);
    }
    dd {
      margin: 0;
      text-align: right;
    }
    .total {
      padding-top: 8px;
      border-top: 1px solid var(--bord);
      font-size: 18px;
      font-weight: 700;
    }
    .rembourse {
      padding: 8px 12px;
      border-radius: var(--rayon-petit);
      background: var(--info-fond);
    }
    .mention {
      margin: 16px 0 0;
      color: var(--texte-3);
      font-size: 13px;
    }
    .actions {
      display: flex;
      justify-content: flex-end;
      gap: 8px;
    }
    @media print {
      .actions {
        display: none;
      }
    }
  `,
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class RecuPage implements OnInit {
  private readonly service = inject(ReservationsService);

  readonly reference = input.required<string>();

  protected readonly moyens = LIBELLES_MOYEN;
  protected readonly statuts = LIBELLES_STATUT_PAIEMENT;
  protected readonly recu = signal<Recu | null>(null);
  protected readonly erreur = signal<ErreurApi | null>(null);

  ngOnInit(): void {
    this.service.recu(this.reference()).subscribe({
      next: (r) => this.recu.set(r),
      error: (e) => this.erreur.set(lireErreur(e)),
    });
  }

  protected imprimer(): void {
    window.print();
  }
}
