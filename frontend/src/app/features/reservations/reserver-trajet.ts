import { ChangeDetectionStrategy, Component, OnInit, computed, inject, input, signal } from '@angular/core';
import { RouterLink } from '@angular/router';
import { ErreurApi, lireErreur } from '../../core/api/erreur-api';
import { FcfaPipe } from '../../shared/format/formats';
import { Alerte } from '../../shared/ui/alerte';
import { Icone } from '../../shared/ui/icone';
import { Trajet } from '../trajets/trajets.models';
import { LIBELLES_MOYEN, MoyenDisponible, MoyenPaiement, Reservation } from './reservations.models';
import { ReservationsService } from './reservations.service';

/** 04 — Réservation d'un trajet par un passager : nombre de places et moyen de paiement. */
@Component({
  selector: 'app-reserver-trajet',
  imports: [RouterLink, FcfaPipe, Icone, Alerte],
  template: `
    <section class="carte bloc" aria-labelledby="titre-reserver">
      <h2 id="titre-reserver"><app-icone nom="valide" /> Réserver</h2>
      @if (reservation(); as r) {
        <app-alerte type="succes">
          @if (r.statut === 'ACCEPTEE') {
            Place confirmée ! Retrouvez votre code d'embarquement dans « Mes réservations ».
          } @else {
            Demande envoyée : le conducteur doit l'accepter. Vous la suivez dans « Mes réservations ».
          }
        </app-alerte>
        <a class="bouton bouton--primaire" routerLink="/reservations">Mes réservations</a>
      } @else if (trajet().nombrePlacesDisponibles === 0) {
        <p class="aide">Ce trajet est complet.</p>
      } @else {
        <div class="ligne">
          <span>Places</span>
          <div class="compteur">
            <button type="button" (click)="changer(-1)" [disabled]="places() <= 1" aria-label="Une place de moins">−</button>
            <strong aria-live="polite">{{ places() }}</strong>
            <button type="button" (click)="changer(1)" [disabled]="places() >= trajet().nombrePlacesDisponibles"
                    aria-label="Une place de plus">+</button>
          </div>
        </div>

        <fieldset class="moyens">
          <legend>Paiement</legend>
          @for (m of moyens(); track m.moyen) {
            <label [class.indisponible]="!m.disponible">
              <input type="radio" name="moyen" [value]="m.moyen" [checked]="moyen() === m.moyen"
                     [disabled]="!m.disponible" (change)="moyen.set(m.moyen)" />
              {{ libelles[m.moyen] }}
              @if (!m.disponible) { <small>(bientôt)</small> }
              @if (m.moyen === 'ESPECES') { <small>— au conducteur, à l'embarquement</small> }
            </label>
          }
        </fieldset>

        <p class="total">Total <strong>{{ total() | fcfa }}</strong></p>
        @if (moyen() !== 'ESPECES') {
          <p class="aide">Vous paierez par {{ libelles[moyen()] }} une fois la réservation acceptée.
            Annulation avant le départ : remboursement intégral.</p>
        }
        @if (erreur(); as e) {
          <app-alerte type="erreur">{{ e.message }}</app-alerte>
        }
        <button type="button" class="bouton bouton--primaire" [disabled]="envoi()" (click)="reserver()">
          @if (envoi()) { <span class="chargement" aria-hidden="true"></span> } Réserver {{ places() }} place{{ places() > 1 ? 's' : '' }}
        </button>
      }
    </section>
  `,
  styles: `
    .ligne, .total {
      display: flex;
      align-items: center;
      justify-content: space-between;
      margin: 0 0 12px;
    }
    .compteur {
      display: flex;
      align-items: center;
      gap: 14px;
    }
    .compteur button {
      width: 36px;
      height: 36px;
      border: 1px solid var(--bord);
      border-radius: 50%;
      background: var(--surface);
      font-size: 18px;
    }
    .moyens {
      display: grid;
      gap: 8px;
      margin: 0 0 12px;
      padding: 0;
      border: 0;
    }
    .moyens legend {
      margin-bottom: 6px;
      font-weight: 600;
    }
    .moyens label {
      display: flex;
      align-items: center;
      gap: 8px;
    }
    .indisponible {
      color: var(--texte-2);
    }
    .total strong {
      font-size: 20px;
    }
  `,
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class ReserverTrajet implements OnInit {
  private readonly service = inject(ReservationsService);

  readonly trajet = input.required<Trajet>();

  protected readonly libelles = LIBELLES_MOYEN;
  protected readonly places = signal(1);
  protected readonly moyen = signal<MoyenPaiement>('ESPECES');
  protected readonly moyens = signal<MoyenDisponible[]>([{ moyen: 'ESPECES', disponible: true }]);
  protected readonly total = computed(() => this.trajet().prixParPlace * this.places());
  protected readonly envoi = signal(false);
  protected readonly erreur = signal<ErreurApi | null>(null);
  protected readonly reservation = signal<Reservation | null>(null);

  ngOnInit(): void {
    this.service.moyens().subscribe({ next: (m) => this.moyens.set(m), error: () => undefined });
  }

  protected changer(delta: number): void {
    this.places.update((n) => Math.min(this.trajet().nombrePlacesDisponibles, Math.max(1, n + delta)));
  }

  protected reserver(): void {
    this.envoi.set(true);
    this.erreur.set(null);
    this.service.reserver(this.trajet().id, this.places(), this.moyen()).subscribe({
      next: (r) => {
        this.reservation.set(r);
        this.envoi.set(false);
      },
      error: (e) => {
        this.erreur.set(lireErreur(e));
        this.envoi.set(false);
      },
    });
  }
}
