import { BoutonMessage } from '../messages/bouton-message';
import { ChangeDetectionStrategy, Component, OnInit, computed, inject, input, signal } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { ErreurApi, lireErreur } from '../../core/api/erreur-api';
import { FcfaPipe } from '../../shared/format/formats';
import { Alerte } from '../../shared/ui/alerte';
import { Icone } from '../../shared/ui/icone';
import {
  EmbarquementConfirme,
  LIBELLES_MOYEN,
  LIBELLES_STATUT_PAIEMENT,
  LIBELLES_STATUT_RESERVATION,
  Reservation,
} from './reservations.models';
import { ReservationsService } from './reservations.service';

/** 04 — Côté conducteur : demandes reçues sur un trajet (accepter / refuser) et embarquement par PIN. */
@Component({
  selector: 'app-demandes-trajet',
  imports: [FormsModule, FcfaPipe, Icone, Alerte, BoutonMessage],
  template: `
    <section class="carte bloc" aria-labelledby="titre-passagers">
      <h2 id="titre-passagers"><app-icone nom="utilisateurs" /> Passagers</h2>
      @if (erreur(); as e) {
        <app-alerte type="erreur">{{ e.message }}</app-alerte>
      }
      @if (reservations().length === 0) {
        <p class="aide">Aucune réservation pour l'instant.</p>
      }
      <ul class="liste">
        @for (r of reservations(); track r.id) {
          <li>
            <div>
              <strong>{{ r.passager.prenom }} {{ r.passager.nomInitiale }}</strong> · {{ r.nombrePlaces }} place{{ r.nombrePlaces > 1 ? 's' : '' }}
              · {{ r.montantTotal | fcfa }}<br />
              <small>{{ statuts[r.statut] }}
                @if (r.moyenPaiement && r.statut === 'ACCEPTEE') {
                  · {{ moyens[r.moyenPaiement] }} : {{ r.statutPaiement ? paiements[r.statutPaiement] : '' }}
                }
                @if (r.embarque) { · <span class="ok">à bord</span> }
              </small>
              <br /><app-bouton-message variante="lien" [idTrajet]="idTrajet()" [idPassager]="r.passager.id"
                                        [libelle]="'Écrire à ' + r.passager.prenom" />
            </div>
            @if (r.statut === 'EN_ATTENTE') {
              <div class="actions">
                <button type="button" class="bouton bouton--primaire" [disabled]="action()" (click)="accepter(r)">Accepter</button>
                <button type="button" class="bouton bouton--secondaire" [disabled]="action()" (click)="refuser(r)">Refuser</button>
              </div>
            }
          </li>
        }
      </ul>

      @if (aBord()) {
        <form class="embarquement" (submit)="$event.preventDefault(); embarquer()">
          <label for="code-pin">Code d'embarquement du passager</label>
          <div class="saisie">
            <input id="code-pin" name="code" inputmode="numeric" autocomplete="off" maxlength="64"
                   placeholder="6 chiffres" [(ngModel)]="code" />
            <button type="submit" class="bouton bouton--primaire" [disabled]="action() || !code.trim()">Valider</button>
          </div>
        </form>
        @if (embarque(); as e) {
          <app-alerte type="succes" [titre]="e.passager.prenom + ' est à bord'">
            @if (e.montantAEncaisser > 0) {
              Encaissez {{ e.montantAEncaisser | fcfa }} en espèces.
            } @else {
              Déjà payé en ligne : rien à encaisser.
            }
          </app-alerte>
        }
      }
    </section>
  `,
  styles: `
    .liste {
      display: grid;
      gap: 12px;
      margin: 0;
      padding: 0;
      list-style: none;
    }
    .liste li {
      display: flex;
      flex-wrap: wrap;
      align-items: center;
      justify-content: space-between;
      gap: 8px;
      padding-bottom: 12px;
      border-bottom: 1px solid var(--bord);
    }
    .actions {
      display: flex;
      gap: 8px;
    }
    .ok {
      color: var(--vert);
      font-weight: 600;
    }
    .embarquement {
      display: grid;
      gap: 6px;
      margin-top: 16px;
    }
    .embarquement .saisie {
      display: flex;
      gap: 8px;
    }
    .embarquement input {
      flex: 1;
      letter-spacing: 0.2em;
    }
  `,
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class DemandesTrajet implements OnInit {
  private readonly service = inject(ReservationsService);

  readonly idTrajet = input.required<number>();

  protected readonly statuts = LIBELLES_STATUT_RESERVATION;
  protected readonly paiements = LIBELLES_STATUT_PAIEMENT;
  protected readonly moyens = LIBELLES_MOYEN;
  protected readonly reservations = signal<Reservation[]>([]);
  protected readonly aBord = computed(() => this.reservations().some((r) => r.statut === 'ACCEPTEE' && !r.embarque));
  protected readonly action = signal(false);
  protected readonly erreur = signal<ErreurApi | null>(null);
  protected readonly embarque = signal<EmbarquementConfirme | null>(null);
  protected code = '';

  ngOnInit(): void {
    this.charger();
  }

  protected accepter(r: Reservation): void {
    this.executer(() => this.service.accepter(r.id).subscribe(this.observateur()));
  }

  protected refuser(r: Reservation): void {
    this.executer(() => this.service.refuser(r.id, null).subscribe(this.observateur()));
  }

  protected embarquer(): void {
    this.executer(() =>
      this.service.confirmerEmbarquement(this.idTrajet(), this.code.trim()).subscribe({
        next: (e) => {
          this.embarque.set(e);
          this.code = '';
          this.action.set(false);
          this.charger();
        },
        error: (e) => {
          this.erreur.set(lireErreur(e));
          this.action.set(false);
        },
      }),
    );
  }

  private executer(appel: () => void): void {
    this.action.set(true);
    this.erreur.set(null);
    this.embarque.set(null);
    appel();
  }

  private observateur() {
    return {
      next: () => {
        this.action.set(false);
        this.charger();
      },
      error: (e: unknown) => {
        this.erreur.set(lireErreur(e));
        this.action.set(false);
      },
    };
  }

  private charger(): void {
    this.service.reservationsDuTrajet(this.idTrajet()).subscribe({
      next: (l) => this.reservations.set(l),
      error: (e) => this.erreur.set(lireErreur(e)),
    });
  }
}
