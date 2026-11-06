import { ChangeDetectionStrategy, Component, ElementRef, effect, input, signal, viewChild } from '@angular/core';

/**
 * QR code dessiné dans un canvas. La bibliothèque « qrcode » n'est chargée qu'au premier affichage
 * (elle reste hors du paquet principal).
 */
@Component({
  selector: 'app-qr-code',
  template: `
    <canvas #canvas role="img" [attr.aria-label]="libelle()"></canvas>
    @if (erreur()) {
      <small>QR code indisponible : utilisez le code à 6 chiffres.</small>
    }
  `,
  styles: `
    :host {
      display: grid;
      justify-items: center;
    }
    canvas {
      max-width: 100%;
      height: auto;
      border-radius: 8px;
      background: #fff;
    }
  `,
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class QrCode {
  readonly contenu = input.required<string>();
  readonly taille = input(200);
  readonly libelle = input('QR code');

  private readonly canvas = viewChild.required<ElementRef<HTMLCanvasElement>>('canvas');
  protected readonly erreur = signal(false);

  constructor() {
    effect(() => {
      const contenu = this.contenu();
      const taille = this.taille();
      const canvas = this.canvas().nativeElement;
      import('qrcode')
        .then((qr) => qr.toCanvas(canvas, contenu, { width: taille, margin: 2, errorCorrectionLevel: 'M' }))
        .then(() => this.erreur.set(false))
        .catch(() => this.erreur.set(true));
    });
  }
}
