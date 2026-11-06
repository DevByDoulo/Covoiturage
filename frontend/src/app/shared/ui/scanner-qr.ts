import {
  ChangeDetectionStrategy,
  Component,
  DestroyRef,
  ElementRef,
  OnInit,
  inject,
  output,
  signal,
  viewChild,
} from '@angular/core';
import { Icone } from './icone';

/** Décodeur natif de Chrome / Edge sur Android, macOS et ChromeOS (absent de Firefox et de Chrome Windows). */
interface DetecteurNatif {
  detect(source: CanvasImageSource): Promise<{ rawValue: string }[]>;
}
type ConstructeurDetecteur = new (options: { formats: string[] }) => DetecteurNatif;

/** Le navigateur peut-il ouvrir la caméra ? (HTTPS ou localhost, et appareil avec caméra). */
export function cameraDisponible(): boolean {
  return typeof navigator !== 'undefined' && !!navigator.mediaDevices?.getUserMedia && window.isSecureContext;
}

/**
 * Lecture d'un QR code avec la caméra (caméra arrière sur téléphone). Émet le contenu lu, une seule fois.
 * Utilise le décodeur natif du navigateur s'il existe, sinon la bibliothèque jsQR chargée à la demande.
 */
@Component({
  selector: 'app-scanner-qr',
  imports: [Icone],
  template: `
    <div class="cadre" [hidden]="!!erreur()">
      <video #video playsinline muted aria-label="Image de la caméra"></video>
      <span class="viseur" aria-hidden="true"></span>
    </div>
    @if (erreur(); as e) {
      <p class="erreur" role="alert">{{ e }}</p>
    } @else {
      <p class="aide">Placez le QR code du passager dans le cadre.</p>
    }
    <button type="button" class="bouton bouton--secondaire" (click)="fermer.emit()">
      <app-icone nom="croix" [taille]="16" /> Fermer la caméra
    </button>
  `,
  styles: `
    :host {
      display: grid;
      gap: 8px;
      margin-top: 12px;
    }
    .cadre {
      position: relative;
      overflow: hidden;
      border-radius: var(--rayon-petit);
      background: #000;
      aspect-ratio: 4 / 3;
    }
    video {
      width: 100%;
      height: 100%;
      object-fit: cover;
    }
    .viseur {
      position: absolute;
      inset: 18%;
      border: 3px solid var(--orange);
      border-radius: 14px;
    }
    .aide,
    .erreur {
      margin: 0;
      text-align: center;
    }
    .erreur {
      color: var(--erreur);
    }
  `,
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class ScannerQr implements OnInit {
  readonly lu = output<string>();
  readonly fermer = output<void>();

  private readonly video = viewChild.required<ElementRef<HTMLVideoElement>>('video');
  protected readonly erreur = signal<string | null>(null);

  private flux: MediaStream | null = null;
  private image = 0;
  private termine = false;
  private readonly canvas = document.createElement('canvas');

  constructor() {
    inject(DestroyRef).onDestroy(() => this.arreter());
  }

  ngOnInit(): void {
    this.demarrer();
  }

  private async demarrer(): Promise<void> {
    if (!cameraDisponible()) {
      this.erreur.set('La caméra n\'est pas accessible ici (il faut une connexion sécurisée et une caméra).');
      return;
    }
    try {
      this.flux = await navigator.mediaDevices.getUserMedia({
        video: { facingMode: { ideal: 'environment' } },
        audio: false,
      });
    } catch (e) {
      const nom = (e as DOMException)?.name;
      this.erreur.set(
        nom === 'NotAllowedError'
          ? 'Accès à la caméra refusé. Autorisez-le dans le navigateur, ou saisissez le code à 6 chiffres.'
          : 'Aucune caméra disponible. Saisissez le code à 6 chiffres du passager.',
      );
      return;
    }
    if (this.termine) return this.arreter();
    const video = this.video().nativeElement;
    video.srcObject = this.flux;
    await video.play().catch(() => undefined);
    const lire = await this.decodeur();
    const boucle = async () => {
      if (this.termine) return;
      const valeur = video.readyState >= 2 ? await lire(video).catch(() => null) : null;
      if (valeur && !this.termine) {
        this.termine = true;
        this.arreter();
        this.lu.emit(valeur);
        return;
      }
      this.image = requestAnimationFrame(boucle);
    };
    this.image = requestAnimationFrame(boucle);
  }

  /** Fonction qui lit un QR code dans l'image courante de la vidéo (null si aucun). */
  private async decodeur(): Promise<(video: HTMLVideoElement) => Promise<string | null>> {
    const Natif = (window as unknown as { BarcodeDetector?: ConstructeurDetecteur }).BarcodeDetector;
    if (Natif) {
      try {
        const detecteur = new Natif({ formats: ['qr_code'] });
        return async (video) => (await detecteur.detect(video))[0]?.rawValue ?? null;
      } catch {
        /* format non pris en charge : on passe à jsQR */
      }
    }
    const jsQR = (await import('jsqr')).default;
    const contexte = this.canvas.getContext('2d', { willReadFrequently: true })!;
    return async (video) => {
      // Image réduite : plus rapide, et suffisant pour un QR code tenu devant la caméra.
      const echelle = Math.min(1, 640 / video.videoWidth);
      const l = Math.round(video.videoWidth * echelle);
      const h = Math.round(video.videoHeight * echelle);
      if (!l || !h) return null;
      this.canvas.width = l;
      this.canvas.height = h;
      contexte.drawImage(video, 0, 0, l, h);
      const pixels = contexte.getImageData(0, 0, l, h);
      return jsQR(pixels.data, l, h, { inversionAttempts: 'dontInvert' })?.data ?? null;
    };
  }

  private arreter(): void {
    this.termine = true;
    cancelAnimationFrame(this.image);
    this.flux?.getTracks().forEach((t) => t.stop());
    this.flux = null;
  }
}
