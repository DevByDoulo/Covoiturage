import { signal } from '@angular/core';

/** 09 — Messages vocaux : logique d'enregistrement indépendante du navigateur (testée avec une fausse plateforme). */

/** Un enregistrement plus court est ignoré ; au-delà de la limite, il est envoyé automatiquement. */
export const DUREE_MIN_MS = 1000;
export const DUREE_MAX_MS = 5 * 60_000;
/** Nombre de barres de la forme d'onde envoyée au serveur (64 au plus côté API). */
export const BARRES = 48;
/** Formats essayés dans l'ordre (Chrome / Edge / Firefox : WebM Opus ; Safari : MP4). */
export const TYPES_PREFERES = ['audio/webm;codecs=opus', 'audio/ogg;codecs=opus', 'audio/mp4', 'audio/webm'];

export type EtatEnregistrement = 'inactif' | 'demande' | 'enregistrement';

/** « 0:07 », « 1:23 », « 5:00 ». */
export function formaterDuree(ms: number): string {
  const s = Math.max(0, Math.floor(ms / 1000));
  return `${Math.floor(s / 60)}:${String(s % 60).padStart(2, '0')}`;
}

/** Durée totale d'un vocal, arrondie à la seconde comme les aperçus du serveur (« 🎤 Message vocal (0:03) »). */
export function formaterDureeTotale(ms: number): string {
  return formaterDuree(Math.round(ms / 1000) * 1000);
}

/** Premier format accepté par le navigateur, '' pour laisser le navigateur choisir. */
export function choisirType(supporte: (type: string) => boolean): string {
  return TYPES_PREFERES.find((t) => supporte(t)) ?? '';
}

/** Extension du fichier envoyé, d'après le type produit par le navigateur. */
export function extensionPour(type: string): string {
  if (type.includes('ogg')) return 'ogg';
  if (type.includes('mp4') || type.includes('m4a')) return 'm4a';
  if (type.includes('aac')) return 'aac';
  return 'webm';
}

/** Ramène des niveaux mesurés (0 à 100, un tous les 100 ms) à {@link BARRES} barres (maximum de chaque tranche). */
export function reduireNiveaux(niveaux: number[], barres = BARRES): number[] {
  if (!niveaux.length) return [];
  if (niveaux.length <= barres) return niveaux.map(borner);
  const resultat: number[] = [];
  for (let i = 0; i < barres; i++) {
    const debut = Math.floor((i * niveaux.length) / barres);
    const fin = Math.max(debut + 1, Math.floor(((i + 1) * niveaux.length) / barres));
    resultat.push(borner(Math.max(...niveaux.slice(debut, fin))));
  }
  return resultat;
}

function borner(n: number): number {
  return Math.min(100, Math.max(0, Math.round(n)));
}

/** Message clair pour chaque échec d'accès au micro. */
export function messageErreurMicro(e: unknown): string {
  const nom = e instanceof DOMException || (e && typeof e === 'object' && 'name' in e) ? String((e as { name: string }).name) : '';
  switch (nom) {
    case 'NotAllowedError':
    case 'SecurityError':
      return "L'accès au micro a été refusé. Autorisez-le dans les réglages du navigateur (icône à gauche de l'adresse), puis réessayez.";
    case 'NotFoundError':
    case 'OverconstrainedError':
      return 'Aucun micro détecté sur cet appareil.';
    case 'NotReadableError':
    case 'AbortError':
      return 'Le micro est utilisé par une autre application. Fermez-la, puis réessayez.';
    default:
      return "Impossible d'accéder au micro.";
  }
}

export const MESSAGE_INCOMPATIBLE =
  "Votre navigateur ne permet pas d'enregistrer des messages vocaux (ou la page n'est pas en HTTPS). Essayez avec Chrome, Firefox, Edge ou Safari à jour.";

/** Chronomètre avec pause, sur une horloge fournie (performance.now en vrai, une horloge factice en test). */
export class Chrono {
  private debut = 0;
  private cumul = 0;
  private enCours = false;

  constructor(private readonly maintenant: () => number) {}

  demarrer(): void {
    this.cumul = 0;
    this.debut = this.maintenant();
    this.enCours = true;
  }

  pause(): void {
    if (!this.enCours) return;
    this.cumul += this.maintenant() - this.debut;
    this.enCours = false;
  }

  reprendre(): void {
    if (this.enCours) return;
    this.debut = this.maintenant();
    this.enCours = true;
  }

  get enPause(): boolean {
    return !this.enCours;
  }

  ecoule(): number {
    return this.cumul + (this.enCours ? this.maintenant() - this.debut : 0);
  }
}

/** Ce dont l'enregistreur a besoin de MediaRecorder (pour pouvoir le simuler). */
export interface EnregistreurNatif {
  readonly mimeType: string;
  ondataavailable: ((e: { data: Blob }) => void) | null;
  onstop: (() => void) | null;
  start(intervalleMs?: number): void;
  stop(): void;
}

/** Accès du navigateur au micro, à l'enregistrement et au temps. */
export interface PlateformeAudio {
  compatible(): boolean;
  typeSupporte(type: string): boolean;
  micro(): Promise<MediaStream>;
  enregistreur(flux: MediaStream, type: string): EnregistreurNatif;
  /** Niveau sonore instantané (0 à 100), ou null si l'API Web Audio manque. */
  analyseur(flux: MediaStream): { niveau(): number; fermer(): void } | null;
  liberer(flux: MediaStream): void;
  maintenant(): number;
  /** Appelle {@code fn} toutes les {@code ms} ; renvoie la fonction qui arrête l'appel. */
  repeter(fn: () => void, ms: number): () => void;
}

export interface VocalEnregistre {
  blob: Blob;
  type: string;
  dureeMs: number;
  niveaux: number[];
}

/**
 * Enregistrement d'un message vocal : demande du micro, minuteur, niveaux pour la forme d'onde, limite de
 * 5 minutes ({@code surLimite} est alors appelé pour envoyer), enregistrement trop court ignoré.
 */
export class EnregistreurVocal {
  readonly etat = signal<EtatEnregistrement>('inactif');
  readonly ecouleMs = signal(0);
  readonly niveau = signal(0);
  readonly erreur = signal<string | null>(null);

  private readonly chrono: Chrono;
  private flux: MediaStream | null = null;
  private natif: EnregistreurNatif | null = null;
  private analyse: { niveau(): number; fermer(): void } | null = null;
  private arreterTic: (() => void) | null = null;
  private morceaux: Blob[] = [];
  private niveaux: number[] = [];
  private type = '';

  constructor(
    private readonly plateforme: PlateformeAudio,
    private readonly surLimite: () => void = () => {},
  ) {
    this.chrono = new Chrono(() => plateforme.maintenant());
  }

  get compatible(): boolean {
    return this.plateforme.compatible();
  }

  /** @returns vrai si l'enregistrement a commencé. */
  async demarrer(): Promise<boolean> {
    if (this.etat() !== 'inactif') return false;
    this.erreur.set(null);
    if (!this.plateforme.compatible()) {
      this.erreur.set(MESSAGE_INCOMPATIBLE);
      return false;
    }
    this.etat.set('demande');
    let flux: MediaStream;
    try {
      flux = await this.plateforme.micro();
    } catch (e) {
      this.etat.set('inactif');
      this.erreur.set(messageErreurMicro(e));
      return false;
    }
    if (this.etat() !== 'demande') {
      // Annulé pendant la demande d'autorisation.
      this.plateforme.liberer(flux);
      return false;
    }
    try {
      this.type = choisirType((t) => this.plateforme.typeSupporte(t));
      this.natif = this.plateforme.enregistreur(flux, this.type);
    } catch {
      this.plateforme.liberer(flux);
      this.etat.set('inactif');
      this.erreur.set(MESSAGE_INCOMPATIBLE);
      return false;
    }
    this.flux = flux;
    this.morceaux = [];
    this.niveaux = [];
    this.natif.ondataavailable = (e) => {
      if (e.data.size > 0) this.morceaux.push(e.data);
    };
    this.natif.start(250);
    this.analyse = this.plateforme.analyseur(flux);
    this.chrono.demarrer();
    this.ecouleMs.set(0);
    this.etat.set('enregistrement');
    this.arreterTic = this.plateforme.repeter(() => this.tic(), 100);
    return true;
  }

  /** Arrête et renvoie l'enregistrement, ou null s'il dure moins d'une seconde (ignoré). */
  async terminer(): Promise<VocalEnregistre | null> {
    if (this.etat() !== 'enregistrement' || !this.natif) {
      this.annuler();
      return null;
    }
    const duree = Math.min(this.chrono.ecoule(), DUREE_MAX_MS);
    const natif = this.natif;
    const arrete = new Promise<void>((fin) => (natif.onstop = () => fin()));
    natif.stop();
    await arrete;
    const vocal: VocalEnregistre = {
      blob: new Blob(this.morceaux, { type: natif.mimeType || this.type || 'audio/webm' }),
      type: natif.mimeType || this.type || 'audio/webm',
      dureeMs: duree,
      niveaux: reduireNiveaux(this.niveaux),
    };
    this.liberer();
    return duree < DUREE_MIN_MS || vocal.blob.size === 0 ? null : vocal;
  }

  /** Abandonne l'enregistrement en cours (ou la demande d'autorisation). */
  annuler(): void {
    if (this.natif) {
      this.natif.onstop = null;
      try {
        this.natif.stop();
      } catch {
        // déjà arrêté
      }
    }
    this.liberer();
  }

  private tic(): void {
    const ecoule = this.chrono.ecoule();
    this.ecouleMs.set(ecoule);
    const n = this.analyse?.niveau() ?? 0;
    this.niveau.set(n);
    this.niveaux.push(n);
    if (ecoule >= DUREE_MAX_MS) {
      this.arreterTic?.();
      this.arreterTic = null;
      this.surLimite();
    }
  }

  private liberer(): void {
    this.arreterTic?.();
    this.arreterTic = null;
    this.analyse?.fermer();
    this.analyse = null;
    if (this.flux) this.plateforme.liberer(this.flux);
    this.flux = null;
    this.natif = null;
    this.morceaux = [];
    this.etat.set('inactif');
    this.niveau.set(0);
  }
}

/** Plateforme réelle : getUserMedia, MediaRecorder et Web Audio (niveau = moyenne quadratique du signal). */
export function plateformeNavigateur(): PlateformeAudio {
  return {
    compatible: () =>
      typeof window !== 'undefined' &&
      window.isSecureContext &&
      typeof MediaRecorder !== 'undefined' &&
      !!navigator.mediaDevices?.getUserMedia,
    typeSupporte: (t) => typeof MediaRecorder !== 'undefined' && MediaRecorder.isTypeSupported(t),
    micro: () =>
      navigator.mediaDevices.getUserMedia({ audio: { echoCancellation: true, noiseSuppression: true, channelCount: 1 } }),
    enregistreur: (flux, type) => {
      const r = new MediaRecorder(flux, type ? { mimeType: type, audioBitsPerSecond: 32_000 } : { audioBitsPerSecond: 32_000 });
      const adapte: EnregistreurNatif = {
        get mimeType() {
          return r.mimeType;
        },
        ondataavailable: null,
        onstop: null,
        start: (ms) => r.start(ms),
        stop: () => r.stop(),
      };
      r.ondataavailable = (e) => adapte.ondataavailable?.(e);
      r.onstop = () => adapte.onstop?.();
      return adapte;
    },
    analyseur: (flux) => {
      const Contexte = window.AudioContext ?? (window as unknown as { webkitAudioContext?: typeof AudioContext }).webkitAudioContext;
      if (!Contexte) return null;
      const contexte = new Contexte();
      const noeud = contexte.createAnalyser();
      noeud.fftSize = 512;
      contexte.createMediaStreamSource(flux).connect(noeud);
      const donnees = new Uint8Array(noeud.fftSize);
      return {
        niveau: () => {
          noeud.getByteTimeDomainData(donnees);
          let somme = 0;
          for (const v of donnees) somme += ((v - 128) / 128) ** 2;
          return Math.min(100, Math.round(Math.sqrt(somme / donnees.length) * 400));
        },
        fermer: () => void contexte.close(),
      };
    },
    liberer: (flux) => flux.getTracks().forEach((p) => p.stop()),
    maintenant: () => performance.now(),
    repeter: (fn, ms) => {
      const id = setInterval(fn, ms);
      return () => clearInterval(id);
    },
  };
}
