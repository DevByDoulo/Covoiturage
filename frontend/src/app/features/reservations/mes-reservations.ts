import { DatePipe } from '@angular/common';
import { ChangeDetectionStrategy, Component, DestroyRef, OnInit, inject, input, signal } from '@angular/core';
import { RouterLink } from '@angular/router';
import { ErreurApi, lireErreur } from '../../core/api/erreur-api';
import { FcfaPipe } from '../../shared/format/formats';
import { Alerte } from '../../shared/ui/alerte';
import { Icone } from '../../shared/ui/icone';
import { AvisADonnerBloc } from '../avis/avis-a-donner';
import {
  CodeEmbarquement,
  LIBELLES_MOYEN,
  LIBELLES_STATUT_PAIEMENT,
  LIBELLES_STATUT_RESERVATION,
  MoyenPaiement,
  Reservation,
  paiementEnLigneAttendu,
} from './reservations.models';
import { ReservationsService } from './reservations.service';

/**
 * 04 — Réservations du passager : suivi, paiement en ligne (Wave), code d'embarquement et annulation.
 * Wave renvoie ici après paiement : /reservations?paiement=succes|echec&ref=…
 */
@Component({
  selector: 'app-mes-reservations',
  imports: [RouterLink, DatePipe, FcfaPipe, Icone, Alerte, AvisADonnerBloc],
  template: `
    <header class="entete">
      <h1>Mes réservations</h1>
      <a routerLink="/paiements" class="bouton-lien"><app-icone nom="info" [taille]="16" /> Mes paiements et reçus</a>
    </header>

    <!-- 05 — voyages terminés à noter -->
    <app-avis-a-donner />

    @if (paiement() === 'succes') {
      <app-alerte type="succes">Paiement envoyé. La confirmation de Wave peut prendre quelques secondes.</app-alerte>
    } @else if (paiement() === 'echec') {
      <app-alerte type="avertissement">Le paiement n'a pas abouti. Vous pouvez réessayer ou payer en espèces au conducteur.</app-alerte>
    }
    @if (erreur(); as e) {
      <app-alerte type="erreur">{{ e.message }}</app-alerte>
    }

    @if (reservations(); as liste) {
      @if (liste.length === 0) {
        <section class="carte bloc vide">
          <p>Vous n'avez pas encore réservé de trajet.</p>
          <a class="bouton bouton--primaire" routerLink="/rechercher"><app-icone nom="recherche" /> Rechercher un trajet</a>
        </section>
      }
      @for (r of liste; track r.id) {
        <article class="carte bloc">
          <a class="trajet" [routerLink]="['/trajets', r.trajet.id]">
            <strong>{{ r.trajet.lieuDepart }} → {{ r.trajet.lieuArrivee }}</strong>
            <span>{{ r.trajet.dateHeureDepart | date: 'EEEE d MMMM à HH:mm' }} · avec {{ r.trajet.conducteur.prenom }}</span>
          </a>
          <p class="details">
            {{ r.nombrePlaces }} place{{ r.nombrePlaces > 1 ? 's' : '' }} · <strong>{{ r.montantTotal | fcfa }}</strong>
            · <span class="pastille" [class.pastille--succes]="r.statut === 'ACCEPTEE' || r.statut === 'TERMINEE'"
                    [class.pastille--attente]="r.statut === 'EN_ATTENTE'"
                    [class.pastille--erreur]="r.statut === 'REFUSEE' || r.statut === 'ANNULEE'">{{ statuts[r.statut] }}</span>
          </p>
          @if (r.moyenPaiement && r.statutPaiement) {
            <p class="aide">{{ moyens[r.moyenPaiement] }} : {{ paiements[r.statutPaiement] }}</p>
          }
          @if (r.motifAnnulation && (r.statut === 'ANNULEE' || r.statut === 'REFUSEE')) {
            <p class="aide">{{ r.motifAnnulation }}</p>
          }

          @if (r.statut === 'ACCEPTEE' && !r.embarque) {
            <div class="actions">
              @if (aPayerEnLigne(r)) {
                <button type="button" class="bouton bouton--primaire" [disabled]="action()" (click)="payer(r)">
                  Payer {{ r.montantTotal | fcfa }} par {{ moyens[r.moyenPaiement!] }}
                </button>
                <button type="button" class="bouton-lien" [disabled]="action()" (click)="payer(r, 'ESPECES')">
                  Payer plutôt en espèces au conducteur
                </button>
              }
              <button type="button" class="bouton bouton--secondaire" (click)="afficherCode(r)">
                <app-icone nom="valide" [taille]="16" /> Code d'embarquement
              </button>
            </div>
            @if (codes()[r.id]; as c) {
              <div class="code" aria-live="polite">
                <span>Donnez ce code au conducteur au moment de monter</span>
                <strong>{{ c.codePin }}</strong>
                @if (c.montantAPayer > 0) {
                  <span>À régler en espèces : {{ c.montantAPayer | fcfa }}</span>
                } @else {
                  <span>Déjà payé : rien à régler au conducteur.</span>
                }
              </div>
            }
          }

          @if ((r.statut === 'EN_ATTENTE' || r.statut === 'ACCEPTEE') && !r.embarque) {
            @if (aAnnuler() === r.id) {
              <div class="confirmation">
                <p>Annuler cette réservation ?
                  @if (r.statutPaiement === 'REUSSI') { Le montant payé vous sera remboursé intégralement. }</p>
                <button type="button" class="bouton bouton--secondaire" (click)="aAnnuler.set(null)">Garder</button>
                <button type="button" class="bouton bouton--secondaire" [disabled]="action()" (click)="annuler(r)">Annuler la réservation</button>
              </div>
            } @else {
              <button type="button" class="bouton-lien" (click)="aAnnuler.set(r.id)">Annuler la réservation</button>
            }
          }
        </article>
      }
    } @else {
      <p class="centre"><span class="chargement chargement--sombre"></span> Chargement…</p>
    }
  `,
  styles: `
    :host {
      display: grid;
      gap: 16px;
      max-width: 720px;
      margin: 0 auto;
      padding: 16px;
    }
    .entete {
      display: flex;
      flex-wrap: wrap;
      align-items: baseline;
      justify-content: space-between;
      gap: 8px;
    }
    h1 {
      margin: 0;
    }
    .trajet {
      display: grid;
      gap: 2px;
      color: inherit;
      text-decoration: none;
    }
    .trajet span,
    .aide {
      color: var(--texte-2);
    }
    .details {
      margin: 10px 0 4px;
    }
    .actions,
    .confirmation {
      display: flex;
      flex-wrap: wrap;
      align-items: center;
      gap: 8px;
      margin-top: 12px;
    }
    .confirmation p {
      flex-basis: 100%;
      margin: 0;
    }
    .code {
      display: grid;
      justify-items: center;
      gap: 4px;
      margin-top: 12px;
      padding: 12px;
      border-radius: var(--rayon-petit);
      background: var(--vert-clair);
      text-align: center;
    }
    .code strong {
      font-size: 32px;
      letter-spacing: 0.3em;
    }
    .vide,
    .centre {
      text-align: center;
    }
  `,
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class MesReservations implements OnInit {
  private readonly service = inject(ReservationsService);
  private readonly destroyRef = inject(DestroyRef);

  /** Paramètres de retour de Wave (liés depuis l'URL). */
  readonly paiement = input<string>();

  protected readonly statuts = LIBELLES_STATUT_RESERVATION;
  protected readonly paiements = LIBELLES_STATUT_PAIEMENT;
  protected readonly moyens = LIBELLES_MOYEN;
  protected readonly reservations = signal<Reservation[] | null>(null);
  protected readonly codes = signal<Record<number, CodeEmbarquement>>({});
  protected readonly aAnnuler = signal<number | null>(null);
  protected readonly action = signal(false);
  protected readonly erreur = signal<ErreurApi | null>(null);

  ngOnInit(): void {
    this.charger();
    // Retour de Wave : le webhook confirme le paiement quelques secondes après ; on rafraîchit une fois.
    if (this.paiement() === 'succes') {
      const minuteur = setTimeout(() => this.charger(), 4000);
      this.destroyRef.onDestroy(() => clearTimeout(minuteur));
    }
  }

  protected readonly aPayerEnLigne = paiementEnLigneAttendu;

  protected payer(r: Reservation, moyen?: MoyenPaiement): void {
    this.action.set(true);
    this.erreur.set(null);
    this.service.payer(r.id, moyen).subscribe({
      next: (s) => {
        if (s.urlPaiement) {
          // Page de paiement de l'opérateur (Wave interdit de l'ouvrir dans une vue intégrée).
          window.location.href = s.urlPaiement;
          return;
        }
        this.action.set(false);
        this.charger();
      },
      error: (e) => {
        this.erreur.set(lireErreur(e));
        this.action.set(false);
      },
    });
  }

  protected afficherCode(r: Reservation): void {
    this.service.codeEmbarquement(r.id).subscribe({
      next: (c) => this.codes.update((m) => ({ ...m, [r.id]: c })),
      error: (e) => this.erreur.set(lireErreur(e)),
    });
  }

  protected annuler(r: Reservation): void {
    this.action.set(true);
    this.erreur.set(null);
    this.service.annuler(r.id, null).subscribe({
      next: () => {
        this.aAnnuler.set(null);
        this.action.set(false);
        this.charger();
      },
      error: (e) => {
        this.erreur.set(lireErreur(e));
        this.action.set(false);
      },
    });
  }

  private charger(): void {
    this.service.mesReservations().subscribe({
      next: (l) => this.reservations.set(l),
      error: (e) => {
        this.erreur.set(lireErreur(e));
        this.reservations.set([]);
      },
    });
  }
}
