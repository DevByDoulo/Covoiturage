import { ChangeDetectionStrategy, Component, OnInit, computed, inject, signal } from '@angular/core';
import { toSignal } from '@angular/core/rxjs-interop';
import { FormBuilder, ReactiveFormsModule, Validators } from '@angular/forms';
import { Router, RouterLink } from '@angular/router';
import { catchError, of } from 'rxjs';
import { ErreurApi, lireErreur } from '../../../core/api/erreur-api';
import { SessionService } from '../../../core/auth/session.service';
import { Geocodage, Lieu } from '../../../core/carte/geocodage';
import { Carte, MarqueurCarte } from '../../../shared/carte/carte';
import { Coordonnee, decoderPolyline } from '../../../shared/carte/polyline';
import { DureePipe, FcfaPipe, versDateTimeLocal } from '../../../shared/format/formats';
import { Alerte } from '../../../shared/ui/alerte';
import { Icone } from '../../../shared/ui/icone';
import { ChampLieu } from '../champ-lieu/champ-lieu';
import {
  DemandeEstimation,
  EstimationReponse,
  LIBELLES_ROUTE,
  ModeReservation,
  PointTrajet,
  TailleBagage,
  VehiculeConducteur,
} from '../trajets.models';
import { TrajetsService } from '../trajets.service';

/** Champ de lieu actif : celui que remplit un clic sur la carte. */
type CleLieu = 'depart' | 'arrivee' | number;

type Etat = 'chargement' | 'devenir-conducteur' | 'en-validation' | 'sans-vehicule' | 'pret';

const MAX_ESCALES = 5;
const DELAI_MIN_PUBLICATION_MIN = 30;

/** F4 — Publication d'un trajet : itinéraire sur carte, estimation du prix, ajustement ±10 %. */
@Component({
  selector: 'app-publier',
  imports: [ReactiveFormsModule, RouterLink, Carte, ChampLieu, Icone, Alerte, FcfaPipe, DureePipe],
  templateUrl: './publier.html',
  styleUrl: './publier.scss',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class Publier implements OnInit {
  private readonly trajets = inject(TrajetsService);
  private readonly geocodage = inject(Geocodage);
  private readonly router = inject(Router);
  protected readonly session = inject(SessionService);

  protected readonly libellesRoute = LIBELLES_ROUTE;
  protected readonly bagagesCourts: Record<TailleBagage, string> = { PETIT: 'Petit', MOYEN: 'Moyen', GRAND: 'Grand' };
  protected readonly maxEscales = MAX_ESCALES;
  protected readonly flexibilites = [15, 20, 25, 30];
  protected readonly bagages: TailleBagage[] = ['PETIT', 'MOYEN', 'GRAND'];

  protected readonly etat = signal<Etat>('chargement');
  protected readonly vehicules = signal<VehiculeConducteur[]>([]);
  protected readonly vehiculesValides = computed(() =>
    this.vehicules().filter((v) => v.actif && v.statutValidation === 'VALIDE'),
  );

  // ---- Itinéraire
  protected readonly depart = signal<Lieu | null>(null);
  protected readonly arrivee = signal<Lieu | null>(null);
  protected readonly escales = signal<(Lieu | null)[]>([]);
  protected readonly champActif = signal<CleLieu>('depart');

  // ---- Date, véhicule, options
  protected readonly dateMin = versDateTimeLocal(new Date(Date.now() + DELAI_MIN_PUBLICATION_MIN * 60_000));
  protected readonly form = inject(FormBuilder).nonNullable.group({
    dateHeureDepart: [versDateTimeLocal(demainHuitHeures()), Validators.required],
    flexibiliteMinutes: [20],
    idVehicule: [0, Validators.min(1)],
    nombrePlaces: [3, [Validators.required, Validators.min(1)]],
    modeReservation: ['MANUELLE' as ModeReservation],
    tailleBagage: ['MOYEN' as TailleBagage],
    femmesUniquement: [false],
  });
  private readonly valeurs = toSignal(this.form.valueChanges, { initialValue: this.form.getRawValue() });
  protected readonly vehiculeChoisi = computed(() =>
    this.vehicules().find((v) => v.id === this.valeurs().idVehicule),
  );
  protected readonly placesMax = computed(() => Math.max(1, (this.vehiculeChoisi()?.nombrePlaces ?? 5) - 1));
  protected readonly estConductrice = computed(() => this.session.utilisateur()?.sexe === 'FEMME');

  // ---- Estimation
  protected readonly demande = computed<DemandeEstimation | null>(() => {
    const d = this.depart();
    const a = this.arrivee();
    const escales = this.escales();
    const v = this.valeurs();
    if (!d || !a || escales.some((e) => !e) || !v.idVehicule || !v.dateHeureDepart || !v.nombrePlaces) return null;
    return {
      idVehicule: v.idVehicule,
      depart: versPoint(d),
      arrivee: versPoint(a),
      escales: escales.map((e) => versPoint(e!)),
      dateHeureDepart: v.dateHeureDepart,
      nombrePlaces: v.nombrePlaces,
    };
  });
  private readonly cleDemande = computed(() => JSON.stringify(this.demande()));
  protected readonly estimation = signal<{ cle: string; reponse: EstimationReponse } | null>(null);
  protected readonly estimationAJour = computed(() => this.estimation()?.cle === this.cleDemande());
  protected readonly calculEnCours = signal(false);
  protected readonly prix = signal<number | null>(null);

  protected readonly trace = computed<Coordonnee[]>(() => decoderPolyline(this.estimation()?.reponse.itinerairePolyline));
  protected readonly marqueurs = computed<MarqueurCarte[]>(() => {
    const m: MarqueurCarte[] = [];
    const d = this.depart();
    if (d) m.push({ ...d, type: 'depart', etiquette: 'A', libelle: d.libelle });
    this.escales().forEach((e, i) => e && m.push({ ...e, type: 'escale', etiquette: String(i + 1), libelle: e.libelle }));
    const a = this.arrivee();
    if (a) m.push({ ...a, type: 'arrivee', etiquette: 'B', libelle: a.libelle });
    return m;
  });

  // ---- Envoi
  protected readonly erreur = signal<ErreurApi | null>(null);
  protected readonly publication = signal(false);

  ngOnInit(): void {
    // Jeton et profil frais : le rôle CONDUCTEUR ou la validation des documents ont pu changer depuis la connexion.
    this.session
      .rafraichir()
      .pipe(catchError(() => of(null)))
      .subscribe(() => {
        const u = this.session.utilisateur();
        if (!u || u.role !== 'CONDUCTEUR') return this.etat.set('devenir-conducteur');
        if (!u.conducteurValide) return this.etat.set('en-validation');
        this.trajets.mesVehicules().subscribe({
          next: (vehicules) => {
            this.vehicules.set(vehicules);
            const premier = this.vehiculesValides()[0];
            if (!premier) return this.etat.set('sans-vehicule');
            this.choisirVehicule(premier.id);
            this.etat.set('pret');
          },
          error: (e) => {
            this.erreur.set(lireErreur(e));
            this.etat.set('pret');
          },
        });
      });
  }

  // ---- Lieux

  protected lieuDe(cle: CleLieu): Lieu | null {
    if (cle === 'depart') return this.depart();
    if (cle === 'arrivee') return this.arrivee();
    return this.escales()[cle] ?? null;
  }

  protected definirLieu(cle: CleLieu, lieu: Lieu): void {
    if (cle === 'depart') this.depart.set(lieu);
    else if (cle === 'arrivee') this.arrivee.set(lieu);
    else this.escales.update((liste) => liste.map((e, i) => (i === cle ? lieu : e)));
    // Champ suivant à remplir par la carte.
    if (cle === 'depart' && !this.arrivee()) this.champActif.set('arrivee');
  }

  /** Clic sur la carte : le champ actif prend ce point, avec l'adresse trouvée par géocodage inverse. */
  protected placerSurCarte(point: Coordonnee): void {
    const cle = this.champActif();
    const provisoire = `Point sur la carte (${point.latitude.toFixed(4)}, ${point.longitude.toFixed(4)})`;
    this.definirLieu(cle, { libelle: provisoire, ...point });
    this.geocodage.adresseDe(point.latitude, point.longitude).subscribe((adresse) => {
      const actuel = this.lieuDe(cle);
      if (adresse && actuel?.latitude === point.latitude && actuel.longitude === point.longitude) {
        this.definirLieu(cle, { libelle: adresse, ...point });
      }
    });
  }

  protected ajouterEscale(): void {
    if (this.escales().length >= MAX_ESCALES) return;
    this.escales.update((liste) => [...liste, null]);
    this.champActif.set(this.escales().length - 1);
  }

  protected retirerEscale(index: number): void {
    this.escales.update((liste) => liste.filter((_, i) => i !== index));
    this.champActif.set('depart');
  }

  protected inverser(): void {
    const d = this.depart();
    this.depart.set(this.arrivee());
    this.arrivee.set(d);
    this.escales.update((liste) => [...liste].reverse());
  }

  // ---- Options

  protected choisirVehicule(id: number): void {
    this.form.controls.idVehicule.setValue(id);
    const max = Math.max(1, (this.vehicules().find((v) => v.id === id)?.nombrePlaces ?? 5) - 1);
    if (this.form.controls.nombrePlaces.value > max) this.form.controls.nombrePlaces.setValue(max);
  }

  protected changerPlaces(delta: number): void {
    const n = this.form.controls.nombrePlaces.value + delta;
    if (n >= 1 && n <= this.placesMax()) this.form.controls.nombrePlaces.setValue(n);
  }

  // ---- Estimation et publication

  protected calculer(): void {
    const demande = this.demande();
    if (!demande || this.calculEnCours()) return;
    const cle = this.cleDemande();
    this.calculEnCours.set(true);
    this.erreur.set(null);
    this.trajets.estimer(demande).subscribe({
      next: (reponse) => {
        this.estimation.set({ cle, reponse });
        this.prix.set(reponse.tarif.prixRecommande);
        this.calculEnCours.set(false);
      },
      error: (e) => {
        this.erreur.set(lireErreur(e));
        this.calculEnCours.set(false);
      },
    });
  }

  protected departTropProche(): boolean {
    const v = this.form.controls.dateHeureDepart.value;
    return !!v && new Date(v).getTime() < Date.now() + DELAI_MIN_PUBLICATION_MIN * 60_000;
  }

  protected publier(): void {
    const demande = this.demande();
    if (!demande || !this.estimationAJour() || this.departTropProche() || this.publication()) return;
    const v = this.form.getRawValue();
    this.publication.set(true);
    this.erreur.set(null);
    this.trajets
      .publier({
        ...demande,
        flexibiliteMinutes: v.flexibiliteMinutes,
        modeReservation: v.modeReservation,
        tailleBagage: v.tailleBagage,
        femmesUniquement: this.estConductrice() && v.femmesUniquement,
        prixParPlace: this.prix(),
      })
      .subscribe({
        next: (trajet) => this.router.navigate(['/trajets', trajet.id], { queryParams: { publie: 1 } }),
        error: (e) => {
          this.erreur.set(lireErreur(e));
          this.publication.set(false);
        },
      });
  }

  protected majPrix(evenement: Event): void {
    this.prix.set(Number((evenement.target as HTMLInputElement).value));
  }
}

function versPoint(l: Lieu): PointTrajet {
  return { lieu: l.libelle, latitude: l.latitude, longitude: l.longitude };
}

function demainHuitHeures(): Date {
  const d = new Date();
  d.setDate(d.getDate() + 1);
  d.setHours(8, 0, 0, 0);
  return d;
}
