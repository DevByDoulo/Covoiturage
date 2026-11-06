import {
  ChangeDetectionStrategy,
  Component,
  DestroyRef,
  OnInit,
  computed,
  inject,
  input,
  signal,
  viewChild,
} from '@angular/core';
import { RouterLink } from '@angular/router';
import { Subscription, catchError, finalize, of } from 'rxjs';
import { lireErreur } from '../../../core/api/erreur-api';
import { SessionService } from '../../../core/auth/session.service';
import { EtatGuidage, Guide } from '../../../core/carte/guide';
import { Itineraire, ItineraireService, ModeDeplacement } from '../../../core/carte/itineraire';
import { Position, PositionActuelle } from '../../../core/carte/position-actuelle';
import { Voix } from '../../../core/voix';
import { Carte, MarqueurCarte } from '../../../shared/carte/carte';
import { Coordonnee } from '../../../shared/carte/polyline';
import { Alerte } from '../../../shared/ui/alerte';
import { Icone } from '../../../shared/ui/icone';
import { ReservationsService } from '../../reservations/reservations.service';
import { Trajet } from '../trajets.models';
import { TrajetsService } from '../trajets.service';

/** Vitesses moyennes pour l'heure d'arrivée estimée quand l'appareil ne donne pas la sienne. */
const VITESSE_PIED_MS = 1.3;

/** Écran allumé pendant le guidage (API Wake Lock, si le navigateur la propose). */
interface VerrouEcran {
  release(): Promise<void>;
}

/**
 * 08 — Guidage vocal jusqu'au point de rendez-vous : le passager vers son point de prise en charge, le conducteur
 * vers le départ de son trajet. Position suivie en direct, itinéraire OSRM, consignes lues à voix haute,
 * recalcul si l'on s'écarte du tracé.
 */
@Component({
  selector: 'app-guidage',
  imports: [RouterLink, Carte, Icone, Alerte],
  template: `
    <a class="bouton-lien" [routerLink]="['/trajets', id()]"><app-icone nom="fleche-gauche" [taille]="16" /> Retour au trajet</a>
    <h1>Aller au point de rendez-vous</h1>

    @if (erreur(); as e) {
      <app-alerte type="erreur">{{ e }}</app-alerte>
    }

    @if (destination(); as d) {
      @if (!enCours()) {
        <section class="carte bloc">
          <p class="destination"><app-icone nom="position" [taille]="18" /> <strong>{{ d.lieu }}</strong></p>
          <p class="aide">{{ estConducteur() ? 'Départ de votre trajet' : 'Votre point de prise en charge' }}
            · départ prévu {{ heureDepart() }}</p>
          <div class="modes" role="radiogroup" aria-label="Mode de déplacement">
            <button type="button" role="radio" [attr.aria-checked]="mode() === 'pied'" (click)="mode.set('pied')">
              À pied
            </button>
            <button type="button" role="radio" [attr.aria-checked]="mode() === 'voiture'" (click)="mode.set('voiture')">
              <app-icone nom="voiture" [taille]="16" /> En voiture
            </button>
          </div>
          <button type="button" class="bouton bouton--primaire" [disabled]="calcul()" (click)="demarrer()">
            @if (calcul()) {
              <span class="chargement" aria-hidden="true"></span> Recherche de votre position…
            } @else {
              <app-icone nom="jouer" /> Démarrer le guidage vocal
            }
          </button>
          @if (!voix.disponible) {
            <p class="aide">Ce navigateur ne sait pas lire à voix haute : les consignes s'afficheront seulement à l'écran.</p>
          }
          <p class="aide">Gardez cette page ouverte pendant le trajet. Votre position reste sur votre appareil : elle n'est
            envoyée qu'au service d'itinéraire (OpenStreetMap), sans votre nom.</p>
        </section>
      } @else {
        <div class="consigne" [class.consigne--arrive]="etat()?.arrive" aria-live="polite">
          @if (etat()?.arrive) {
            <strong>Vous êtes arrivé</strong>
            <span>{{ d.lieu }}</span>
          } @else if (etat()?.prochaine; as p) {
            <strong>{{ p.instruction }}</strong>
            <span>dans {{ distanceAffichee(etat()!.distanceProchaineM) }}</span>
          } @else {
            <strong>Calcul de l'itinéraire…</strong>
          }
        </div>
      }

      <app-carte class="carte-guidage" [marqueurs]="marqueurs()" [trace]="itineraire()?.trace ?? []"
                 [suivre]="enCours() ? position() : null" libelle="Carte du guidage" />

      @if (enCours()) {
        <div class="pied">
          @if (etat(); as e) {
            @if (!e.arrive) {
              <p><strong>{{ distanceAffichee(e.distanceRestanteM) }}</strong> · arrivée vers {{ arriveeEstimee() }}</p>
            }
          }
          @if (recalcul()) {
            <p class="aide">Recalcul de l'itinéraire…</p>
          }
          <div class="actions">
            @if (voix.disponible) {
              <button type="button" class="bouton bouton--secondaire" (click)="voix.basculer()"
                      [attr.aria-pressed]="voix.active()">
                {{ voix.active() ? '🔊 Voix activée' : '🔇 Voix coupée' }}
              </button>
            }
            <button type="button" class="bouton bouton--secondaire" (click)="carte()?.recentrer()">
              <app-icone nom="cible" [taille]="16" /> Recentrer
            </button>
            <button type="button" class="bouton bouton--secondaire" (click)="arreter()">
              <app-icone nom="croix" [taille]="16" /> Arrêter
            </button>
          </div>
        </div>
      }
    } @else if (!erreur()) {
      <p class="aide"><span class="chargement chargement--sombre"></span> Chargement…</p>
    }
  `,
  styles: `
    h1 { margin: 8px 0 12px; font-size: 22px; }
    .destination { display: flex; align-items: center; gap: 6px; margin: 0; }
    .modes {
      display: grid;
      grid-template-columns: 1fr 1fr;
      gap: 6px;
      margin: 12px 0;
      button {
        display: inline-flex;
        align-items: center;
        justify-content: center;
        gap: 6px;
        min-height: 42px;
        border: 1px solid var(--bord);
        border-radius: var(--rayon-petit);
        background: var(--surface);
        font-weight: 600;
        cursor: pointer;
      }
      button[aria-checked='true'] { border-color: var(--vert); background: var(--vert-clair); color: var(--vert); }
    }
    .consigne {
      display: grid;
      gap: 2px;
      margin-bottom: 10px;
      padding: 14px 16px;
      border-radius: var(--rayon-petit);
      background: var(--vert);
      color: #fff;
      strong { font-size: 20px; }
    }
    .consigne--arrive { background: var(--orange); }
    .carte-guidage { display: block; height: min(60vh, 520px); }
    .pied {
      display: grid;
      gap: 8px;
      margin-top: 10px;
      p { margin: 0; }
    }
    .actions { display: flex; flex-wrap: wrap; gap: 8px; }
    .actions .bouton { width: auto; flex: 1 1 auto; }
  `,
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class Guidage implements OnInit {
  private readonly trajets = inject(TrajetsService);
  private readonly reservations = inject(ReservationsService);
  private readonly session = inject(SessionService);
  private readonly itineraires = inject(ItineraireService);
  private readonly positions = inject(PositionActuelle);
  protected readonly voix = inject(Voix);

  readonly id = input.required<string>();

  protected readonly carte = viewChild(Carte);
  protected readonly trajet = signal<Trajet | null>(null);
  private readonly pointRamassage = signal<string | null>(null);
  protected readonly erreur = signal<string | null>(null);
  protected readonly mode = signal<ModeDeplacement>('pied');
  protected readonly enCours = signal(false);
  protected readonly calcul = signal(false);
  protected readonly recalcul = signal(false);
  protected readonly position = signal<Position | null>(null);
  protected readonly itineraire = signal<Itineraire | null>(null);
  protected readonly etat = signal<EtatGuidage | null>(null);

  private guide: Guide | null = null;
  /** Une seule demande d'itinéraire à la fois (les positions arrivent plus vite que la réponse). */
  private demandeEnCours = false;
  private suivi?: Subscription;
  private verrou: VerrouEcran | null = null;

  protected readonly estConducteur = computed(() => this.trajet()?.conducteur.id === this.session.utilisateur()?.id);

  /** Conducteur : départ du trajet. Passager : son escale de prise en charge si c'en est une, sinon le départ. */
  protected readonly destination = computed(() => {
    const t = this.trajet();
    if (!t) return null;
    const ramassage = this.pointRamassage();
    const escale = this.estConducteur() ? undefined : t.escales.find((e) => e.lieu === ramassage);
    return escale ? { lieu: escale.lieu, latitude: escale.latitude, longitude: escale.longitude } : t.depart;
  });

  protected readonly heureDepart = computed(() => {
    const t = this.trajet();
    return t ? new Date(t.dateHeureDepart).toLocaleString('fr-FR', { weekday: 'long', hour: '2-digit', minute: '2-digit' }) : '';
  });

  protected readonly marqueurs = computed<MarqueurCarte[]>(() => {
    const d = this.destination();
    const p = this.position();
    return [
      ...(d ? [{ ...d, type: 'depart' as const, etiquette: 'A', libelle: d.lieu }] : []),
      ...(p ? [{ latitude: p.latitude, longitude: p.longitude, type: 'moi' as const, libelle: 'Vous' }] : []),
    ];
  });

  protected readonly arriveeEstimee = computed(() => {
    const e = this.etat();
    const it = this.itineraire();
    if (!e || !it) return '';
    const vitesse = this.mode() === 'pied' ? VITESSE_PIED_MS : Math.max(3, it.distanceM / Math.max(1, it.dureeS));
    return new Date(Date.now() + (e.distanceRestanteM / vitesse) * 1000).toLocaleTimeString('fr-FR', {
      hour: '2-digit',
      minute: '2-digit',
    });
  });

  constructor() {
    inject(DestroyRef).onDestroy(() => this.arreter());
  }

  ngOnInit(): void {
    this.trajets.detail(Number(this.id())).subscribe({
      next: (t) => {
        this.trajet.set(t);
        if (this.estConducteur()) {
          this.mode.set('voiture');
          return;
        }
        // Passager : point de prise en charge de sa réservation sur ce trajet.
        this.reservations
          .mesReservations()
          .pipe(catchError(() => of([])))
          .subscribe((liste) => {
            const r = liste.find((x) => x.trajet.id === t.id && (x.statut === 'ACCEPTEE' || x.statut === 'EN_ATTENTE'));
            this.pointRamassage.set(r?.pointRamassage ?? null);
          });
      },
      error: (e) => this.erreur.set(lireErreur(e).message),
    });
  }

  protected distanceAffichee(m: number): string {
    return m < 1000 ? `${Math.max(10, Math.round(m / 10) * 10)} m` : `${(m / 1000).toFixed(1).replace('.', ',')} km`;
  }

  /** Lancé par un clic : nécessaire pour que le navigateur accepte de parler. */
  protected demarrer(): void {
    this.erreur.set(null);
    this.calcul.set(true);
    this.voix.dire('Recherche de votre position.');
    this.suivi = this.positions.suivre().subscribe({
      next: (p) => this.nouvellePosition(p),
      error: (e: Error) => {
        this.erreur.set(e.message);
        this.calcul.set(false);
        this.arreter();
      },
    });
    this.garderEcranAllume();
  }

  protected arreter(): void {
    this.suivi?.unsubscribe();
    this.suivi = undefined;
    this.voix.taire();
    this.verrou?.release().catch(() => undefined);
    this.verrou = null;
    this.enCours.set(false);
    this.calcul.set(false);
    this.guide = null;
    this.etat.set(null);
  }

  private nouvellePosition(p: Position): void {
    this.position.set(p);
    if (!this.guide) {
      if (this.calcul() && !this.demandeEnCours) this.calculerDepuis(p, false);
      return;
    }
    const etat = this.guide.avancer(p);
    this.etat.set(etat);
    for (const a of etat.annonces) this.voix.dire(a, true);
    if (etat.arrive) {
      // Arrivé : on garde la carte mais on arrête de suivre la position.
      this.suivi?.unsubscribe();
      this.verrou?.release().catch(() => undefined);
    } else if (etat.horsRoute && !this.demandeEnCours) {
      this.voix.dire('Vous vous êtes écarté de l’itinéraire. Recalcul.', true);
      this.calculerDepuis(p, true);
    }
  }

  private calculerDepuis(p: Coordonnee, recalcul: boolean): void {
    const d = this.destination();
    if (!d) return;
    this.demandeEnCours = true;
    this.recalcul.set(recalcul);
    this.itineraires.calculer(p, d, this.mode()).pipe(finalize(() => (this.demandeEnCours = false))).subscribe({
      next: (it) => {
        if (!this.suivi) return; // guidage arrêté entre-temps
        this.itineraire.set(it);
        this.guide = new Guide(it, this.mode());
        this.enCours.set(true);
        this.calcul.set(false);
        this.recalcul.set(false);
        if (!recalcul) this.voix.dire(this.guide.annonceDepart());
        const etat = this.guide.avancer(p);
        this.etat.set(etat);
        etat.annonces.forEach((a) => this.voix.dire(a));
      },
      error: () => {
        this.recalcul.set(false);
        if (recalcul) return; // on garde l'ancien itinéraire et on réessaiera à la prochaine position
        this.erreur.set("Impossible de calculer l'itinéraire pour le moment (service OpenStreetMap indisponible). Réessayez.");
        this.arreter();
      },
    });
  }

  private garderEcranAllume(): void {
    const wakeLock = (navigator as Navigator & { wakeLock?: { request(type: 'screen'): Promise<VerrouEcran> } }).wakeLock;
    wakeLock?.request('screen').then((v) => (this.verrou = v)).catch(() => undefined);
  }
}
