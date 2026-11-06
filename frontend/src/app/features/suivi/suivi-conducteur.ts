import { ChangeDetectionStrategy, Component, DestroyRef, OnInit, computed, inject, input, signal } from '@angular/core';
import { RouterLink } from '@angular/router';
import { EMPTY, Subscription, catchError, of, switchMap, timer } from 'rxjs';
import { lireErreur } from '../../core/api/erreur-api';
import { distanceM, distanceParlee } from '../../core/carte/itineraire';
import { Voix } from '../../core/voix';
import { Carte, MarqueurCarte } from '../../shared/carte/carte';
import { Alerte } from '../../shared/ui/alerte';
import { Icone } from '../../shared/ui/icone';
import { ReservationsService } from '../reservations/reservations.service';
import { pointDeRendezVous } from '../trajets/rendez-vous';
import { PointTrajet, Trajet } from '../trajets/trajets.models';
import { TrajetsService } from '../trajets/trajets.service';
import { PositionConducteur, SuiviService } from './suivi.service';

/** Rafraîchissement de la position du conducteur. */
const INTERVALLE_MS = 5_000;
/** Paliers annoncés quand le conducteur s'approche (une fois chacun). */
const PALIERS_M = [2000, 1000, 500, 200];
/** En dessous, le conducteur est considéré comme arrivé au point de rendez-vous. */
const ARRIVE_M = 60;
/** Au-delà, la position est signalée comme ancienne (téléphone en veille, réseau coupé). */
const ANCIENNE_S = 60;
/** Vitesse supposée en ville quand le téléphone ne la donne pas (≈ 25 km/h). */
const VITESSE_DEFAUT_MS = 7;
const DETOUR = 1.3;

/**
 * 08 — Le passager suit son conducteur en direct : voiture sur la carte, distance et heure d'arrivée estimée au
 * point de prise en charge, annonces vocales (« Awa est à 500 mètres du point de prise en charge »).
 */
@Component({
  selector: 'app-suivi-conducteur',
  imports: [RouterLink, Carte, Icone, Alerte],
  template: `
    <a class="bouton-lien" [routerLink]="['/trajets', id()]"><app-icone nom="fleche-gauche" [taille]="16" /> Retour au trajet</a>
    <h1>Suivre mon conducteur</h1>

    @if (erreur(); as e) {
      <app-alerte type="erreur">{{ e }}</app-alerte>
    }

    @if (trajet(); as t) {
      <div class="etat" [class.etat--arrive]="arrive()" aria-live="polite">
        @if (!position()) {
          <strong>{{ t.conducteur.prenom }} ne partage pas sa position pour le moment</strong>
          <span>Cette page se met à jour toute seule dès que le partage commence (au plus tôt une heure avant le départ).</span>
        } @else if (arrive()) {
          <strong>{{ t.conducteur.prenom }} est au point de rendez-vous</strong>
          <span>{{ rendezVous()?.lieu }}</span>
        } @else {
          <strong>{{ t.conducteur.prenom }} est à {{ distanceAffichee() }}</strong>
          <span>du point de rendez-vous · arrivée vers {{ arriveeEstimee() }}</span>
        }
        @if (position(); as p) {
          @if (p.ageSecondes > ancienne) {
            <small>Dernière position reçue il y a {{ ageTexte(p.ageSecondes) }}.</small>
          }
        }
      </div>

      <app-carte class="carte-suivi" [marqueurs]="marqueurs()" [suivre]="positionCarte()" libelle="Position du conducteur" />

      <div class="actions">
        @if (voix.disponible) {
          <button type="button" class="bouton bouton--secondaire" (click)="voix.basculer()" [attr.aria-pressed]="voix.active()">
            {{ voix.active() ? '🔊 Annonces vocales activées' : '🔇 Annonces vocales coupées' }}
          </button>
        }
        <a class="bouton bouton--secondaire" [routerLink]="['/trajets', t.id, 'guidage']">
          <app-icone nom="position" [taille]="16" /> Me guider jusqu'au point de rendez-vous
        </a>
      </div>
      <p class="aide">Rendez-vous : <strong>{{ rendezVous()?.lieu }}</strong>. La position de {{ t.conducteur.prenom }}
        n'est visible que par ses passagers, pendant le trajet.</p>
    } @else if (!erreur()) {
      <p class="aide"><span class="chargement chargement--sombre"></span> Chargement…</p>
    }
  `,
  styles: `
    h1 { margin: 8px 0 12px; font-size: 22px; }
    .etat {
      display: grid;
      gap: 2px;
      margin-bottom: 10px;
      padding: 14px 16px;
      border-radius: var(--rayon-petit);
      background: var(--vert);
      color: #fff;
      strong { font-size: 19px; }
      small { opacity: 0.85; }
    }
    .etat--arrive { background: var(--orange); }
    .carte-suivi { display: block; height: min(55vh, 480px); }
    .actions {
      display: flex;
      flex-wrap: wrap;
      gap: 8px;
      margin: 10px 0;
      .bouton { width: auto; flex: 1 1 auto; }
    }
  `,
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class SuiviConducteur implements OnInit {
  private readonly trajets = inject(TrajetsService);
  private readonly reservations = inject(ReservationsService);
  private readonly suivi = inject(SuiviService);
  protected readonly voix = inject(Voix);
  private readonly destroyRef = inject(DestroyRef);

  readonly id = input.required<string>();
  protected readonly ancienne = ANCIENNE_S;

  protected readonly trajet = signal<Trajet | null>(null);
  protected readonly rendezVous = signal<PointTrajet | null>(null);
  protected readonly position = signal<PositionConducteur | null>(null);
  protected readonly erreur = signal<string | null>(null);

  private readonly paliersDits = new Set<number>();
  private annonceArrivee = false;
  private premiereAnnonce = false;
  private abonnement?: Subscription;

  protected readonly distance = computed(() => {
    const p = this.position();
    const r = this.rendezVous();
    return p && r ? distanceM(p, r) : null;
  });
  protected readonly arrive = computed(() => (this.distance() ?? Infinity) <= ARRIVE_M);
  protected readonly positionCarte = computed(() => {
    const p = this.position();
    return p ? { latitude: p.latitude, longitude: p.longitude } : null;
  });

  protected readonly marqueurs = computed<MarqueurCarte[]>(() => {
    const r = this.rendezVous();
    const p = this.position();
    const t = this.trajet();
    return [
      ...(r ? [{ ...r, type: 'depart' as const, etiquette: 'A', libelle: r.lieu }] : []),
      ...(p && t ? [{ latitude: p.latitude, longitude: p.longitude, type: 'voiture' as const, libelle: t.conducteur.prenom }] : []),
    ];
  });

  protected readonly distanceAffichee = computed(() => {
    const d = this.distance() ?? 0;
    return d < 1000 ? `${Math.max(10, Math.round(d / 10) * 10)} m` : `${(d / 1000).toFixed(1).replace('.', ',')} km`;
  });

  protected readonly arriveeEstimee = computed(() => {
    const d = this.distance();
    const p = this.position();
    if (d === null || !p) return '';
    const vitesse = p.vitesse && p.vitesse > 2 ? p.vitesse : VITESSE_DEFAUT_MS;
    // Distance à vol d'oiseau : la route est en moyenne un tiers plus longue en ville.
    return new Date(Date.now() + ((d * DETOUR) / vitesse) * 1000).toLocaleTimeString('fr-FR', { hour: '2-digit', minute: '2-digit' });
  });

  ngOnInit(): void {
    const id = Number(this.id());
    this.trajets.detail(id).subscribe({
      next: (t) => {
        this.trajet.set(t);
        this.rendezVous.set(t.depart);
        this.reservations
          .mesReservations()
          .pipe(catchError(() => of([])))
          .subscribe((liste) => {
            const r = liste.find((x) => x.trajet.id === t.id && x.statut === 'ACCEPTEE');
            this.rendezVous.set(pointDeRendezVous(t, r?.pointRamassage));
          });
        // Une erreur passagère (réseau) n'arrête pas le suivi : on réessaie au tour suivant.
        this.abonnement = timer(0, INTERVALLE_MS)
          .pipe(
            switchMap(() =>
              this.suivi.consulter(id).pipe(
                catchError((e) => {
                  this.erreur.set(lireErreur(e).message);
                  return EMPTY;
                }),
              ),
            ),
          )
          .subscribe((p) => {
            this.erreur.set(null);
            this.nouvellePosition(p);
          });
        this.destroyRef.onDestroy(() => this.abonnement?.unsubscribe());
      },
      error: (e) => this.erreur.set(lireErreur(e).message),
    });
  }

  protected ageTexte(s: number): string {
    return s < 120 ? `${s} s` : `${Math.round(s / 60)} min`;
  }

  /** Annonces : premier signal, puis chaque palier franchi, puis l'arrivée (une fois chacun). */
  private nouvellePosition(p: PositionConducteur | null): void {
    this.position.set(p);
    const d = this.distance();
    const prenom = this.trajet()?.conducteur.prenom ?? 'Votre conducteur';
    if (!p || d === null) return;
    if (d <= ARRIVE_M) {
      if (!this.annonceArrivee) {
        this.annonceArrivee = true;
        this.voix.dire(`${prenom} est au point de rendez-vous.`, true);
      }
      return;
    }
    if (!this.premiereAnnonce) {
      this.premiereAnnonce = true;
      // Paliers déjà dépassés : on ne les annoncera pas après coup.
      PALIERS_M.filter((m) => d <= m).forEach((m) => this.paliersDits.add(m));
      this.voix.dire(`${prenom} est en route. ${prenom} est à ${distanceParlee(d)} du point de rendez-vous.`);
      return;
    }
    const palier = PALIERS_M.filter((m) => d <= m && !this.paliersDits.has(m)).pop();
    if (palier !== undefined) {
      PALIERS_M.filter((m) => m >= palier).forEach((m) => this.paliersDits.add(m));
      this.voix.dire(`${prenom} est à ${distanceParlee(d)} du point de rendez-vous.`, true);
    }
  }
}
