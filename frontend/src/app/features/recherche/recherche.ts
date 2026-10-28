import { DatePipe } from '@angular/common';
import { ChangeDetectionStrategy, Component, computed, effect, inject, input, signal, untracked } from '@angular/core';
import { takeUntilDestroyed, toObservable } from '@angular/core/rxjs-interop';
import { FormBuilder, ReactiveFormsModule } from '@angular/forms';
import { ActivatedRoute, Router } from '@angular/router';
import { catchError, of, switchMap, tap } from 'rxjs';
import { ErreurApi, lireErreur } from '../../core/api/erreur-api';
import { SessionService } from '../../core/auth/session.service';
import { Lieu } from '../../core/carte/geocodage';
import { Carte, MarqueurCarte } from '../../shared/carte/carte';
import { Coordonnee, decoderPolyline } from '../../shared/carte/polyline';
import { Alerte } from '../../shared/ui/alerte';
import { Icone } from '../../shared/ui/icone';
import { AlertesService } from '../alertes/alertes.service';
import { MesAlertes } from '../alertes/mes-alertes';
import { CarteTrajet } from '../trajets/carte-trajet/carte-trajet';
import { ChampLieu } from '../trajets/champ-lieu/champ-lieu';
import { CriteresRecherche, Trajet } from '../trajets/trajets.models';
import { TrajetsService } from '../trajets/trajets.service';

type Tri = 'heure' | 'prix' | 'proximite';

/**
 * F5 — Recherche de trajets. Les critères sont portés par l'URL (?de=…&dlat=…&date=…) : la recherche
 * se relance au retour depuis le détail d'un trajet et peut être partagée.
 */
@Component({
  selector: 'app-recherche',
  imports: [ReactiveFormsModule, DatePipe, Carte, ChampLieu, CarteTrajet, Icone, Alerte, MesAlertes],
  templateUrl: './recherche.html',
  styleUrl: './recherche.scss',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class Recherche {
  private readonly service = inject(TrajetsService);
  private readonly router = inject(Router);
  private readonly route = inject(ActivatedRoute);
  protected readonly session = inject(SessionService);
  private readonly alertes = inject(AlertesService);

  // ---- Paramètres d'URL (liés automatiquement)
  readonly de = input<string>();
  readonly dlat = input<string>();
  readonly dlng = input<string>();
  readonly a = input<string>();
  readonly alat = input<string>();
  readonly alng = input<string>();
  readonly date = input<string>();
  readonly places = input<string>();
  readonly hmin = input<string>();
  readonly hmax = input<string>();
  readonly prix = input<string>();
  readonly note = input<string>();
  readonly rayon = input<string>();
  readonly femmes = input<string>();
  readonly conducteur = input<string>();

  protected readonly aujourdhui = new Date().toISOString().slice(0, 10);
  protected readonly depart = signal<Lieu | null>(null);
  protected readonly arrivee = signal<Lieu | null>(null);
  protected readonly champActif = signal<'depart' | 'arrivee'>('depart');
  protected readonly filtresOuverts = signal(false);
  protected readonly erreurFormulaire = signal<string | null>(null);
  protected readonly estFemme = computed(() => this.session.utilisateur()?.sexe === 'FEMME');

  protected readonly form = inject(FormBuilder).nonNullable.group({
    date: [this.aujourdhui],
    places: [1],
    hmin: [''],
    hmax: [''],
    prix: [''],
    note: [''],
    rayon: ['5'],
    femmes: [false],
    conducteur: [''],
  });

  /** Critères complets issus de l'URL, ou null tant qu'aucune recherche n'a été lancée. */
  protected readonly criteres = computed<CriteresRecherche | null>(() => {
    const [dlat, dlng, alat, alng, date] = [this.dlat(), this.dlng(), this.alat(), this.alng(), this.date()];
    if (!dlat || !dlng || !alat || !alng || !date) return null;
    return {
      latDepart: +dlat,
      lngDepart: +dlng,
      latArrivee: +alat,
      lngArrivee: +alng,
      date,
      places: this.places() ? +this.places()! : 1,
      heureMin: this.hmin() || undefined,
      heureMax: this.hmax() || undefined,
      rayonKm: this.rayon() ? +this.rayon()! : undefined,
      prixMax: this.prix() ? +this.prix()! : undefined,
      noteMin: this.note() ? +this.note()! : undefined,
      femmesUniquement: this.femmes() === '1' || undefined,
      conducteur: this.conducteur() || undefined,
    };
  });

  protected readonly resultats = signal<Trajet[] | null>(null);
  protected readonly chargement = signal(false);
  protected readonly erreur = signal<ErreurApi | null>(null);
  protected readonly tri = signal<Tri>('heure');
  protected readonly selection = signal<number | null>(null);

  protected readonly resultatsTries = computed(() => {
    const liste = [...(this.resultats() ?? [])];
    const t = this.tri();
    if (t === 'prix') liste.sort((x, y) => x.prixParPlace - y.prixParPlace);
    else if (t === 'proximite')
      liste.sort((x, y) => distanceTotale(x) - distanceTotale(y));
    else liste.sort((x, y) => x.dateHeureDepart.localeCompare(y.dateHeureDepart));
    return liste;
  });
  protected readonly creationAlerte = signal(false);
  protected readonly erreurAlerte = signal<string | null>(null);
  /** Une alerte existe déjà pour ce trajet et ce jour (coordonnées arrondies à ~10 m). */
  protected readonly alerteExistante = computed(() => {
    const c = this.criteres();
    const proche = (x: number, y: number) => Math.abs(x - y) < 1e-4;
    return !!c && !!this.alertes.alertes()?.some((a) => a.date === c.date
      && proche(a.depart.latitude, c.latDepart) && proche(a.depart.longitude, c.lngDepart)
      && proche(a.arrivee.latitude, c.latArrivee) && proche(a.arrivee.longitude, c.lngArrivee));
  });
  protected readonly trajetSelectionne = computed(() => this.resultats()?.find((t) => t.id === this.selection()) ?? null);

  protected readonly trace = computed<Coordonnee[]>(() => decoderPolyline(this.trajetSelectionne()?.itinerairePolyline));
  protected readonly marqueurs = computed<MarqueurCarte[]>(() => {
    const m: MarqueurCarte[] = [];
    const d = this.depart();
    const a = this.arrivee();
    if (d) m.push({ ...d, type: 'depart', etiquette: 'A', libelle: 'Votre départ : ' + d.libelle });
    if (a) m.push({ ...a, type: 'arrivee', etiquette: 'B', libelle: 'Votre arrivée : ' + a.libelle });
    const c = this.trajetSelectionne()?.correspondance;
    if (c) {
      m.push({ latitude: c.latitudeRamassage, longitude: c.longitudeRamassage, type: 'ramassage', libelle: 'Point de prise en charge' });
      m.push({ latitude: c.latitudeDepose, longitude: c.longitudeDepose, type: 'depose', libelle: 'Point de dépose' });
    }
    return m;
  });

  constructor() {
    // L'URL fait foi : on recopie ses critères dans le formulaire et les champs de lieu.
    effect(() => {
      const c = this.criteres();
      if (!c) return;
      untracked(() => {
        this.depart.set({ libelle: this.de() ?? 'Départ', latitude: c.latDepart, longitude: c.lngDepart });
        this.arrivee.set({ libelle: this.a() ?? 'Arrivée', latitude: c.latArrivee, longitude: c.lngArrivee });
        this.form.patchValue({
          date: c.date,
          places: c.places ?? 1,
          hmin: c.heureMin ?? '',
          hmax: c.heureMax ?? '',
          prix: c.prixMax?.toString() ?? '',
          note: c.noteMin?.toString() ?? '',
          rayon: c.rayonKm?.toString() ?? '5',
          femmes: !!c.femmesUniquement,
          conducteur: c.conducteur ?? '',
        });
      });
    });

    toObservable(this.criteres)
      .pipe(
        tap(() => {
          this.selection.set(null);
          this.erreur.set(null);
        }),
        switchMap((c) => {
          if (!c) return of(null);
          this.chargement.set(true);
          return this.service.rechercher(c).pipe(
            catchError((e) => {
              this.erreur.set(lireErreur(e));
              return of([] as Trajet[]);
            }),
          );
        }),
        takeUntilDestroyed(),
      )
      .subscribe((r) => {
        this.chargement.set(false);
        this.resultats.set(r);
        if (r?.length) this.selection.set(this.resultatsTries()[0].id);
      });
  }

  protected definirLieu(cle: 'depart' | 'arrivee', lieu: Lieu): void {
    (cle === 'depart' ? this.depart : this.arrivee).set(lieu);
    if (cle === 'depart' && !this.arrivee()) this.champActif.set('arrivee');
  }

  protected placerSurCarte(point: Coordonnee): void {
    this.definirLieu(this.champActif(), {
      libelle: `Point sur la carte (${point.latitude.toFixed(4)}, ${point.longitude.toFixed(4)})`,
      ...point,
    });
  }

  protected inverser(): void {
    const d = this.depart();
    this.depart.set(this.arrivee());
    this.arrivee.set(d);
  }

  protected changerPlaces(delta: number): void {
    const n = this.form.controls.places.value + delta;
    if (n >= 1 && n <= 8) this.form.controls.places.setValue(n);
  }

  /** Lance la recherche en écrivant les critères dans l'URL. */
  protected rechercher(): void {
    const d = this.depart();
    const a = this.arrivee();
    if (!d || !a) {
      this.erreurFormulaire.set('Choisissez un lieu de départ et un lieu d\'arrivée.');
      return;
    }
    this.erreurFormulaire.set(null);
    const v = this.form.getRawValue();
    this.router.navigate([], {
      relativeTo: this.route,
      queryParams: {
        de: d.libelle,
        dlat: d.latitude.toFixed(6),
        dlng: d.longitude.toFixed(6),
        a: a.libelle,
        alat: a.latitude.toFixed(6),
        alng: a.longitude.toFixed(6),
        date: v.date || this.aujourdhui,
        places: v.places > 1 ? v.places : null,
        hmin: v.hmin || null,
        hmax: v.hmax || null,
        prix: v.prix || null,
        note: v.note || null,
        rayon: v.rayon !== '5' ? v.rayon : null,
        femmes: v.femmes && this.estFemme() ? 1 : null,
        conducteur: v.conducteur.trim() || null,
      },
    });
  }

  /** Enregistre la recherche courante comme alerte : une notification arrivera à la publication d'un trajet correspondant. */
  protected creerAlerte(): void {
    const c = this.criteres();
    if (!c) return;
    this.creationAlerte.set(true);
    this.erreurAlerte.set(null);
    this.alertes
      .creer({
        depart: { lieu: this.de() ?? 'Départ', latitude: c.latDepart, longitude: c.lngDepart },
        arrivee: { lieu: this.a() ?? 'Arrivée', latitude: c.latArrivee, longitude: c.lngArrivee },
        date: c.date,
        rayonKm: c.rayonKm,
        prixMax: c.prixMax,
      })
      .subscribe({
        next: () => this.creationAlerte.set(false),
        error: (e) => {
          this.creationAlerte.set(false);
          this.erreurAlerte.set(lireErreur(e).message);
        },
      });
  }

  protected reinitialiserFiltres(): void {
    this.form.patchValue({ hmin: '', hmax: '', prix: '', note: '', rayon: '5', femmes: false, conducteur: '' });
  }

  protected nombreFiltres(): number {
    const v = this.form.getRawValue();
    return [v.hmin, v.hmax, v.prix, v.note, v.conducteur.trim(), v.femmes ? '1' : '', v.rayon !== '5' ? '1' : ''].filter(Boolean)
      .length;
  }
}

function distanceTotale(t: Trajet): number {
  return (t.correspondance?.distanceRamassageM ?? 0) + (t.correspondance?.distanceDeposeM ?? 0);
}
