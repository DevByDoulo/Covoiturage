import {
  ChangeDetectionStrategy,
  Component,
  ElementRef,
  OnDestroy,
  ViewEncapsulation,
  afterNextRender,
  effect,
  input,
  output,
  viewChild,
} from '@angular/core';
import * as L from 'leaflet';
import { Coordonnee } from './polyline';

/** « moi » : position de l'utilisateur (guidage) ; « voiture » : position partagée du conducteur. */
export type TypeMarqueur = 'depart' | 'arrivee' | 'escale' | 'ramassage' | 'depose' | 'moi' | 'voiture';

const RONDS: TypeMarqueur[] = ['ramassage', 'depose', 'moi', 'voiture'];

export interface MarqueurCarte extends Coordonnee {
  type: TypeMarqueur;
  libelle?: string;
  /** Texte court dans la pastille (ex. numéro d'escale). */
  etiquette?: string;
}

/** Centre par défaut : Sénégal entier. */
const CENTRE_SENEGAL: L.LatLngTuple = [14.5, -14.45];

/**
 * Carte interactive (Leaflet + tuiles OpenStreetMap). C'est le SEUL composant qui connaît la
 * bibliothèque de carte : pour passer à Google Maps, on remplace son implémentation en gardant
 * les mêmes entrées/sorties (marqueurs, tracé, clic).
 */
@Component({
  selector: 'app-carte',
  template: `<div #conteneur class="carte" role="region" [attr.aria-label]="libelle()"></div>`,
  styles: `
    app-carte {
      display: block;
    }
    app-carte .carte {
      width: 100%;
      height: 100%;
      min-height: 220px;
      border-radius: 16px;
      overflow: hidden;
      background: #e8eef3;
      z-index: 0;
    }
    .pin {
      display: grid;
      place-items: center;
      width: 28px;
      height: 28px;
      border: 3px solid #fff;
      border-radius: 50% 50% 50% 0;
      transform: rotate(-45deg);
      box-shadow: 0 2px 6px rgba(0, 0, 0, 0.3);
      font: 700 12px var(--police);
      color: #fff;
    }
    .pin > span {
      transform: rotate(45deg);
    }
    .pin--depart { background: #0c6b3f; }
    .pin--arrivee { background: #c0262d; }
    .pin--escale { background: #f29a1f; }
    .pin--ramassage, .pin--depose {
      width: 18px;
      height: 18px;
      border-radius: 50%;
      transform: none;
      background: #3f5d9a;
    }
    .pin--moi {
      width: 20px;
      height: 20px;
      border-radius: 50%;
      transform: none;
      background: #1a73e8;
      box-shadow: 0 0 0 8px rgba(26, 115, 232, 0.2);
    }
    .pin--voiture {
      width: 32px;
      height: 32px;
      border-radius: 50%;
      transform: none;
      background: #f29a1f;
      font-size: 17px;
    }
    .pin--moi > span,
    .pin--voiture > span {
      transform: none;
    }
  `,
  encapsulation: ViewEncapsulation.None,
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class Carte implements OnDestroy {
  readonly marqueurs = input<MarqueurCarte[]>([]);
  readonly trace = input<Coordonnee[]>([]);
  readonly libelle = input('Carte');
  /**
   * Mode suivi (guidage, voiture en direct) : la carte reste centrée sur ce point au lieu de recadrer sur tous
   * les marqueurs à chaque mise à jour. Le premier affichage cadre l'ensemble, puis la carte suit le point.
   */
  readonly suivre = input<Coordonnee | null>(null);
  private suiviDemarre = false;
  /** Clic sur la carte (pour placer un point). */
  readonly clic = output<Coordonnee>();

  private readonly conteneur = viewChild.required<ElementRef<HTMLElement>>('conteneur');
  private carte?: L.Map;
  private readonly calque = L.layerGroup();
  private observateur?: ResizeObserver;
  /** Points à garder visibles (recadrage après redimensionnement du conteneur). */
  private limites: L.LatLngTuple[] = [];

  constructor() {
    afterNextRender(() => {
      this.carte = L.map(this.conteneur().nativeElement, { zoomControl: true, attributionControl: true })
        .setView(CENTRE_SENEGAL, 7);
      L.tileLayer('https://tile.openstreetmap.org/{z}/{x}/{y}.png', {
        maxZoom: 19,
        attribution: '&copy; contributeurs <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a>',
      }).addTo(this.carte);
      this.calque.addTo(this.carte);
      this.carte.on('click', (e: L.LeafletMouseEvent) =>
        this.clic.emit({ latitude: e.latlng.lat, longitude: e.latlng.lng }),
      );
      this.dessiner();
      // La taille du conteneur peut changer après l'affichage (mise en page, rotation, mobile/bureau) :
      // Leaflet doit alors recalculer ses tuiles et recadrer sur le trajet.
      this.observateur = new ResizeObserver(() => {
        this.carte?.invalidateSize();
        this.cadrer();
      });
      this.observateur.observe(this.conteneur().nativeElement);
    });
    effect(() => {
      this.marqueurs();
      this.trace();
      this.suivre();
      this.dessiner();
    });
  }

  ngOnDestroy(): void {
    this.observateur?.disconnect();
    this.carte?.remove();
  }

  /** Recentre sur le point suivi (bouton « Recentrer » de l'écran de guidage). */
  recentrer(): void {
    const p = this.suivre();
    if (this.carte && p) this.carte.setView([p.latitude, p.longitude], Math.max(this.carte.getZoom(), 16));
  }

  private cadrer(): void {
    if (!this.carte) return;
    const suivi = this.suivre();
    if (suivi && this.suiviDemarre) {
      this.carte.panTo([suivi.latitude, suivi.longitude], { animate: true });
      return;
    }
    if (suivi) {
      this.suiviDemarre = true;
      this.carte.setView([suivi.latitude, suivi.longitude], 17);
      return;
    }
    if (this.limites.length === 1) this.carte.setView(this.limites[0], 13);
    else if (this.limites.length > 1)
      this.carte.fitBounds(L.latLngBounds(this.limites), { padding: [32, 32], maxZoom: 14 });
  }

  private dessiner(): void {
    if (!this.carte) return;
    this.calque.clearLayers();
    const limites: L.LatLngTuple[] = [];

    const trace = this.trace();
    if (trace.length > 1) {
      const ligne = trace.map((p) => [p.latitude, p.longitude] as L.LatLngTuple);
      L.polyline(ligne, { color: '#0c6b3f', weight: 5, opacity: 0.85 }).addTo(this.calque);
      limites.push(...ligne);
    }
    for (const m of this.marqueurs()) {
      const position: L.LatLngTuple = [m.latitude, m.longitude];
      const icone = L.divIcon({
        className: '',
        html: `<div class="pin pin--${m.type}"><span>${m.type === 'voiture' ? '🚗' : (m.etiquette ?? '')}</span></div>`,
        iconSize: [28, 28],
        iconAnchor: m.type === 'voiture' ? [16, 16] : m.type === 'moi' ? [10, 10] : RONDS.includes(m.type) ? [9, 9] : [14, 28],
      });
      // Les positions en direct passent au-dessus des autres marqueurs.
      const marqueur = L.marker(position, {
        icon: icone,
        keyboard: false,
        zIndexOffset: m.type === 'moi' || m.type === 'voiture' ? 1000 : 0,
      });
      if (m.libelle) marqueur.bindTooltip(m.libelle);
      marqueur.addTo(this.calque);
      limites.push(position);
    }

    this.limites = limites;
    this.cadrer();
  }
}
