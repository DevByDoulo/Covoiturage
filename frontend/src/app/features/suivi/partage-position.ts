import { ChangeDetectionStrategy, Component, DestroyRef, computed, inject, input, signal } from '@angular/core';
import { Alerte } from '../../shared/ui/alerte';
import { Icone } from '../../shared/ui/icone';
import { Trajet } from '../trajets/trajets.models';
import { PartagePosition } from './partage-position.service';

/** Le partage n'est accepté par le serveur qu'à partir d'une heure avant le départ. */
const OUVERTURE_AVANT_DEPART_MS = 60 * 60_000;

/** 08 — Bloc du conducteur (détail de son trajet) : partager sa position en direct avec ses passagers. */
@Component({
  selector: 'app-partage-position',
  imports: [Icone, Alerte],
  template: `
    <section class="carte bloc" aria-labelledby="titre-partage">
      <h2 id="titre-partage"><app-icone nom="position" /> Position en direct</h2>
      @if (actif()) {
        <p class="etat"><span class="point" aria-hidden="true"></span> Vos passagers voient votre position.
          @if (depuis(); as s) { <small>Dernier envoi il y a {{ s }} s.</small> }</p>
        <p class="aide">Gardez cette page (ou le site) ouverte pendant le trajet ; vous pouvez changer d'écran.</p>
        <button type="button" class="bouton bouton--secondaire" (click)="partage.arreter()">
          <app-icone nom="croix" [taille]="16" /> Arrêter le partage
        </button>
      } @else if (ouvert()) {
        <p class="aide">Vos passagers acceptés pourront suivre votre arrivée au point de rendez-vous, avec des annonces
          vocales. Votre position est effacée à l'arrêt du partage et à la fin du trajet.</p>
        <button type="button" class="bouton bouton--primaire" (click)="partage.demarrer(trajet().id)">
          <app-icone nom="position" [taille]="16" /> Partager ma position
        </button>
      } @else {
        <p class="aide">Vous pourrez partager votre position à partir d'une heure avant le départ.</p>
      }
      @if (partage.erreur(); as e) {
        <app-alerte type="erreur">{{ e }}</app-alerte>
      }
    </section>
  `,
  styles: `
    .etat {
      display: flex;
      flex-wrap: wrap;
      align-items: center;
      gap: 8px;
      margin: 0 0 6px;
      font-weight: 600;
      small { font-weight: 400; color: var(--texte-2); }
    }
    .point {
      width: 10px;
      height: 10px;
      border-radius: 50%;
      background: var(--vert);
      animation: pulsation 1.6s infinite;
    }
    @keyframes pulsation {
      0% { box-shadow: 0 0 0 0 rgba(12, 107, 63, 0.5); }
      100% { box-shadow: 0 0 0 10px rgba(12, 107, 63, 0); }
    }
  `,
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class PartagePositionBloc {
  protected readonly partage = inject(PartagePosition);
  readonly trajet = input.required<Trajet>();

  /** Horloge pour « il y a N s » et l'ouverture du partage. */
  private readonly maintenant = signal(Date.now());

  protected readonly actif = computed(() => this.partage.idTrajet() === this.trajet().id);
  protected readonly ouvert = computed(() => {
    const t = this.trajet();
    if (t.statut === 'EN_COURS') return true;
    return (t.statut === 'PUBLIE' || t.statut === 'COMPLET')
      && new Date(t.dateHeureDepart).getTime() - OUVERTURE_AVANT_DEPART_MS <= this.maintenant();
  });
  protected readonly depuis = computed(() => {
    const d = this.partage.dernierEnvoi();
    return d ? Math.max(0, Math.round((this.maintenant() - d.getTime()) / 1000)) : null;
  });

  constructor() {
    const horloge = setInterval(() => this.maintenant.set(Date.now()), 1000);
    inject(DestroyRef).onDestroy(() => clearInterval(horloge));
  }
}
