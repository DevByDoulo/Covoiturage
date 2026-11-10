import { DatePipe } from '@angular/common';
import { ChangeDetectionStrategy, Component, OnInit, inject, input, signal } from '@angular/core';
import { FormControl, ReactiveFormsModule } from '@angular/forms';
import { RouterLink } from '@angular/router';
import { ErreurApi, lireErreur } from '../../core/api/erreur-api';
import { Alerte } from '../../shared/ui/alerte';
import {
  Decision,
  LIBELLES_DECISION,
  LIBELLES_MOTIF,
  LIBELLES_STATUT_SIGNALEMENT,
  StatutSignalement,
  estOuvert,
} from '../signalements/signalements.models';
import { SignalementAdmin, SignalementsService } from '../signalements/signalements.service';
import { Page } from './admin.service';

type DecisionFinale = Exclude<Decision, 'PRENDRE_EN_CHARGE'>;

/** File de modération des signalements (module 10) : filtre par statut, prise en charge et décision motivée. */
@Component({
  selector: 'app-signalements-admin',
  imports: [ReactiveFormsModule, RouterLink, DatePipe, Alerte],
  template: `
    <h1>Signalements</h1>
    <form class="filtres" (submit)="$event.preventDefault(); aller(0)">
      <select [formControl]="statut" aria-label="Statut du signalement" (change)="aller(0)">
        <option value="">Tous les statuts</option>
        @for (s of statuts; track s[0]) {
          <option [value]="s[0]">{{ s[1] }}</option>
        }
      </select>
      @if (utilisateur()) {
        <a class="bouton-lien" routerLink="/admin/signalements">Voir tous les utilisateurs</a>
      }
    </form>

    @if (erreur(); as e) {
      <app-alerte type="erreur">{{ e.message }}</app-alerte>
    }

    @if (resultat(); as r) {
      <p class="compte">{{ r.page.totalElements }} signalement{{ r.page.totalElements > 1 ? 's' : '' }}</p>
      @for (s of r.content; track s.id) {
        <article class="carte bloc">
          <header>
            <strong>{{ motifs[s.motif] }}</strong>
            <span class="pastille" [class.pastille--attente]="ouvert(s.statut)" [class.pastille--succes]="s.statut === 'TRAITE'">
              {{ libellesStatut[s.statut] }}
            </span>
          </header>
          <p class="parties">
            <span>Signalé par <strong>{{ s.signaleur.prenom }} {{ s.signaleur.nom }}</strong></span>
            <span>Personne visée :
              <a [routerLink]="['/admin/utilisateurs', s.signale.id]">{{ s.signale.prenom }} {{ s.signale.nom }}</a>
              ({{ s.totalContreSignale }} signalement{{ s.totalContreSignale > 1 ? 's' : '' }} au total)</span>
            @if (s.trajet) { <span>Trajet : {{ s.trajet }}</span> }
          </p>
          @if (s.description) {
            <p class="description">{{ s.description }}</p>
          }
          <small>Reçu le {{ s.dateSignalement | date: 'dd/MM/yyyy HH:mm' }}</small>

          @if (!ouvert(s.statut)) {
            <p class="decision">Décision de {{ s.admin }} : {{ s.decisionAdmin }}</p>
          } @else if (ouverte() === s.id) {
            <div class="decider">
              <select [formControl]="decision" aria-label="Décision">
                @for (d of decisions; track d[0]) {
                  <option [value]="d[0]">{{ d[1] }}</option>
                }
              </select>
              <textarea [formControl]="message" rows="3" maxlength="500" aria-label="Motif de la décision"
                placeholder="Motif de la décision (obligatoire, enregistré dans l'historique)"></textarea>
              <div class="actions">
                <button class="bouton bouton--secondaire" type="button" (click)="ouverte.set(null)">Annuler</button>
                <button class="bouton bouton--primaire" type="button" [disabled]="envoi()" (click)="valider(s)">Valider la décision</button>
              </div>
            </div>
          } @else {
            <div class="actions">
              @if (s.statut === 'EN_ATTENTE') {
                <button class="bouton bouton--secondaire" type="button" [disabled]="envoi()" (click)="prendreEnCharge(s)">Prendre en charge</button>
              }
              <button class="bouton bouton--primaire" type="button" (click)="ouvrir(s)">Décider</button>
            </div>
          }
        </article>
      } @empty {
        <p class="vide">Aucun signalement pour ce filtre.</p>
      }
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
      align-items: center;
      gap: 12px;
      select {
        min-height: 50px;
        padding: 0 12px;
        border: 0;
        border-radius: var(--rayon);
        background: var(--surface);
        box-shadow: var(--ombre);
        font: inherit;
      }
    }
    .compte {
      color: var(--texte-2);
    }
    article {
      display: grid;
      gap: 8px;
      margin-bottom: 10px;
    }
    header {
      display: flex;
      align-items: center;
      justify-content: space-between;
      gap: 8px;
    }
    p {
      margin: 0;
    }
    .parties {
      display: grid;
      gap: 2px;
    }
    .description,
    .decision {
      padding: 8px 10px;
      border-radius: var(--rayon-petit);
      background: var(--fond);
    }
    small {
      color: var(--texte-3);
    }
    .decider {
      display: grid;
      gap: 8px;
      select,
      textarea {
        width: 100%;
        padding: 8px 10px;
        border: 1px solid var(--bord);
        border-radius: var(--rayon-petit);
        font: inherit;
      }
    }
    .actions {
      display: flex;
      flex-wrap: wrap;
      gap: 8px;
      .bouton {
        width: auto;
        padding: 0 18px;
      }
    }
    .pagination {
      display: flex;
      align-items: center;
      justify-content: center;
      gap: 16px;
    }
  `,
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class SignalementsAdmin implements OnInit {
  private readonly service = inject(SignalementsService);

  /** Paramètre de requête facultatif : n'afficher que les signalements visant cet utilisateur. */
  readonly utilisateur = input<string>();

  protected readonly motifs = LIBELLES_MOTIF;
  protected readonly libellesStatut = LIBELLES_STATUT_SIGNALEMENT;
  protected readonly statuts = Object.entries(LIBELLES_STATUT_SIGNALEMENT);
  protected readonly decisions = Object.entries(LIBELLES_DECISION);
  protected readonly ouvert = estOuvert;

  protected readonly statut = new FormControl<StatutSignalement | ''>('EN_ATTENTE', { nonNullable: true });
  protected readonly decision = new FormControl<DecisionFinale>('CLASSER_SANS_SUITE', { nonNullable: true });
  protected readonly message = new FormControl('', { nonNullable: true });

  protected readonly resultat = signal<Page<SignalementAdmin> | null>(null);
  protected readonly ouverte = signal<number | null>(null);
  protected readonly envoi = signal(false);
  protected readonly erreur = signal<ErreurApi | null>(null);

  ngOnInit(): void {
    if (this.utilisateur()) this.statut.setValue('');
    this.aller(0);
  }

  protected aller(page: number): void {
    this.erreur.set(null);
    this.service.liste(this.statut.value, this.utilisateur() ? Number(this.utilisateur()) : null, page).subscribe({
      next: (r) => this.resultat.set(r),
      error: (e) => this.erreur.set(lireErreur(e)),
    });
  }

  protected ouvrir(s: SignalementAdmin): void {
    this.decision.setValue('CLASSER_SANS_SUITE');
    this.message.setValue('');
    this.erreur.set(null);
    this.ouverte.set(s.id);
  }

  protected prendreEnCharge(s: SignalementAdmin): void {
    this.appliquer(s, 'PRENDRE_EN_CHARGE', null);
  }

  protected valider(s: SignalementAdmin): void {
    const texte = this.message.value.trim();
    if (!texte) {
      this.erreur.set({ status: 400, message: 'Indiquez le motif de la décision.' });
      return;
    }
    this.appliquer(s, this.decision.value, texte);
  }

  private appliquer(s: SignalementAdmin, decision: Decision, message: string | null): void {
    this.envoi.set(true);
    this.erreur.set(null);
    this.service.decider(s.id, decision, message).subscribe({
      next: () => {
        this.envoi.set(false);
        this.ouverte.set(null);
        this.aller(this.resultat()?.page.number ?? 0);
      },
      error: (e) => {
        this.envoi.set(false);
        this.erreur.set(lireErreur(e));
      },
    });
  }
}
