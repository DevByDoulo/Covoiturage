import { DatePipe } from '@angular/common';
import { ChangeDetectionStrategy, Component, OnInit, computed, inject, input, signal } from '@angular/core';
import { FormBuilder, ReactiveFormsModule, Validators } from '@angular/forms';
import { RouterLink } from '@angular/router';
import { Observable } from 'rxjs';
import { ErreurApi, lireErreur } from '../../../core/api/erreur-api';
import { SessionService } from '../../../core/auth/session.service';
import { Carte, MarqueurCarte } from '../../../shared/carte/carte';
import { decoderPolyline } from '../../../shared/carte/polyline';
import { DureePipe, FcfaPipe } from '../../../shared/format/formats';
import { Alerte } from '../../../shared/ui/alerte';
import { Icone } from '../../../shared/ui/icone';
import { DemandesTrajet } from '../../reservations/demandes-trajet';
import { ReserverTrajet } from '../../reservations/reserver-trajet';
import {
  LIBELLES_BAGAGE,
  LIBELLES_ROUTE,
  LIBELLES_STATUT,
  ModeReservation,
  TailleBagage,
  Trajet,
} from '../trajets.models';
import { TrajetsService } from '../trajets.service';

type Panneau = 'aucun' | 'modifier' | 'annuler';

/**
 * 03 — Détail d'un trajet ; le conducteur peut le modifier, l'annuler, le démarrer et le terminer.
 * 04 — Le passager y réserve ; le conducteur y traite les demandes et valide l'embarquement.
 */
@Component({
  selector: 'app-detail-trajet',
  imports: [ReactiveFormsModule, RouterLink, DatePipe, FcfaPipe, DureePipe, Carte, Icone, Alerte, ReserverTrajet, DemandesTrajet],
  templateUrl: './detail-trajet.html',
  styleUrl: './detail-trajet.scss',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class DetailTrajet implements OnInit {
  private readonly service = inject(TrajetsService);
  private readonly session = inject(SessionService);
  private readonly fb = inject(FormBuilder);

  /** Paramètres de route (liés automatiquement). */
  readonly id = input.required<string>();
  readonly publie = input<string>();

  protected readonly libellesStatut = LIBELLES_STATUT;
  protected readonly libellesBagage = LIBELLES_BAGAGE;
  protected readonly libellesRoute = LIBELLES_ROUTE;
  protected readonly flexibilites = [15, 20, 25, 30];
  protected readonly bagages: TailleBagage[] = ['PETIT', 'MOYEN', 'GRAND'];

  protected readonly trajet = signal<Trajet | null>(null);
  protected readonly erreurChargement = signal<ErreurApi | null>(null);
  protected readonly erreurAction = signal<ErreurApi | null>(null);
  protected readonly succes = signal<string | null>(null);
  protected readonly action = signal(false);
  protected readonly panneau = signal<Panneau>('aucun');

  protected readonly estConducteur = computed(
    () => !!this.trajet() && this.trajet()!.conducteur.id === this.session.utilisateur()?.id,
  );
  protected readonly modifiable = computed(() => {
    const t = this.trajet();
    return !!t && (t.statut === 'PUBLIE' || t.statut === 'COMPLET') && new Date(t.dateHeureDepart) > new Date();
  });
  /** Le backend autorise le démarrage à partir d'une heure avant le départ. */
  protected readonly demarrable = computed(() => {
    const t = this.trajet();
    return !!t && new Date(t.dateHeureDepart).getTime() - 60 * 60_000 <= Date.now();
  });
  protected readonly placesReservees = computed(() => {
    const t = this.trajet();
    return t ? t.nombrePlacesTotal - t.nombrePlacesDisponibles : 0;
  });

  protected readonly trace = computed(() => decoderPolyline(this.trajet()?.itinerairePolyline));
  protected readonly marqueurs = computed<MarqueurCarte[]>(() => {
    const t = this.trajet();
    if (!t) return [];
    return [
      { ...t.depart, type: 'depart', etiquette: 'A', libelle: t.depart.lieu },
      ...t.escales.map((e, i) => ({ ...e, type: 'escale' as const, etiquette: String(i + 1), libelle: e.lieu })),
      { ...t.arrivee, type: 'arrivee', etiquette: 'B', libelle: t.arrivee.lieu },
    ];
  });

  protected readonly formModif = this.fb.nonNullable.group({
    dateHeureDepart: ['', Validators.required],
    flexibiliteMinutes: [20],
    nombrePlaces: [1, Validators.min(1)],
    modeReservation: ['MANUELLE' as ModeReservation],
    tailleBagage: ['MOYEN' as TailleBagage],
    prixParPlace: [0],
  });
  protected readonly motif = this.fb.nonNullable.control('', Validators.maxLength(500));

  ngOnInit(): void {
    if (this.publie()) this.succes.set('Votre trajet est publié ! Les passagers peuvent maintenant le trouver.');
    this.service.detail(Number(this.id())).subscribe({
      next: (t) => this.trajet.set(t),
      error: (e) => this.erreurChargement.set(lireErreur(e)),
    });
  }

  protected ouvrirModification(): void {
    const t = this.trajet();
    if (!t) return;
    this.formModif.setValue({
      dateHeureDepart: t.dateHeureDepart.slice(0, 16),
      flexibiliteMinutes: t.flexibiliteMinutes,
      nombrePlaces: t.nombrePlacesTotal,
      modeReservation: t.modeReservation,
      tailleBagage: t.tailleBagage,
      prixParPlace: t.prixParPlace,
    });
    this.erreurAction.set(null);
    this.panneau.set('modifier');
  }

  protected changerPlaces(delta: number): void {
    const c = this.formModif.controls.nombrePlaces;
    const n = c.value + delta;
    if (n >= Math.max(1, this.placesReservees())) c.setValue(n);
  }

  protected enregistrer(): void {
    const id = this.trajet()?.id;
    if (!id || this.formModif.invalid) return;
    this.executer(this.service.modifier(id, this.formModif.getRawValue()), 'Trajet modifié. Les passagers concernés sont prévenus.');
  }

  protected annuler(): void {
    const id = this.trajet()?.id;
    if (!id) return;
    this.executer(this.service.annuler(id, this.motif.value.trim() || null), 'Trajet annulé. Les passagers ont été prévenus.');
  }

  protected demarrer(): void {
    const id = this.trajet()?.id;
    if (id) this.executer(this.service.demarrer(id), 'Bon voyage ! Le trajet est en cours.');
  }

  protected terminer(): void {
    const id = this.trajet()?.id;
    if (id) this.executer(this.service.terminer(id), 'Trajet terminé. Merci !');
  }

  private executer(appel: Observable<Trajet>, message: string): void {
    this.action.set(true);
    this.erreurAction.set(null);
    this.succes.set(null);
    appel.subscribe({
      next: (t) => {
        this.trajet.set(t);
        this.succes.set(message);
        this.panneau.set('aucun');
        this.action.set(false);
      },
      error: (e) => {
        this.erreurAction.set(lireErreur(e));
        this.action.set(false);
      },
    });
  }
}
