import { ChangeDetectionStrategy, Component, computed, input } from '@angular/core';

/** Tracés (24×24, trait) inspirés de Lucide. Les cercles sont exprimés en arcs pour n'utiliser que <path>. */
const ICONES = {
  'alerte': ['M2 12a10 10 0 1 0 20 0a10 10 0 1 0 -20 0', 'M12 8v4', 'M12 16h.01'],
  'arobase': ['M8 12a4 4 0 1 0 8 0a4 4 0 1 0 -8 0', 'M16 8v5a3 3 0 0 0 6 0v-1a10 10 0 1 0-4 8'],
  'cadenas': ['M5 11h14a2 2 0 0 1 2 2v7a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-7a2 2 0 0 1 2-2z', 'M7 11V7a5 5 0 0 1 10 0v4'],
  'cadenas-rotation': [
    'M3 12a9 9 0 1 0 2.64-6.36L3 8.3',
    'M3 3v5.3h5.3',
    'M10 12.5h4a1 1 0 0 1 1 1v2.5a1 1 0 0 1-1 1h-4a1 1 0 0 1-1-1v-2.5a1 1 0 0 1 1-1z',
    'M10.5 12.5v-1a1.5 1.5 0 0 1 3 0v1',
  ],
  'cle': [
    'm15.5 7.5 2.3 2.3a1 1 0 0 0 1.4 0l2.1-2.1a1 1 0 0 0 0-1.4L19 4',
    'm21 2-9.6 9.6',
    'M2 15.5a5.5 5.5 0 1 0 11 0a5.5 5.5 0 1 0 -11 0',
  ],
  'connexion': ['M15 3h4a2 2 0 0 1 2 2v14a2 2 0 0 1-2 2h-4', 'm10 17 5-5-5-5', 'M15 12H3'],
  'deconnexion': ['M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4', 'm16 17 5-5-5-5', 'M21 12H9'],
  'effacer': [
    'M10 5a2 2 0 0 0-1.344.519l-6.328 5.74a1 1 0 0 0 0 1.481l6.328 5.741A2 2 0 0 0 10 19h10a2 2 0 0 0 2-2V7a2 2 0 0 0-2-2z',
    'm12 9 6 6',
    'm18 9-6 6',
  ],
  'eclair': [
    'M4 14a1 1 0 0 1-.78-1.63l9.9-10.2a.5.5 0 0 1 .86.46l-1.92 6.02A1 1 0 0 0 13 10h7a1 1 0 0 1 .78 1.63l-9.9 10.2a.5.5 0 0 1-.86-.46l1.92-6.02A1 1 0 0 0 11 14z',
  ],
  'envoyer': [
    'M14.536 21.686a.5.5 0 0 0 .937-.024l6.5-19a.496.496 0 0 0-.635-.635l-19 6.5a.5.5 0 0 0-.024.937l7.93 3.18a2 2 0 0 1 1.112 1.11z',
    'm21.854 2.147-10.94 10.939',
  ],
  'feuille': [
    'M11 20A7 7 0 0 1 9.8 6.1C15.5 5 17 4.48 19 2c1 2 2 4.18 2 8 0 5.5-4.78 10-10 10Z',
    'M2 21c0-3 1.85-5.36 5.08-6C9.5 14.52 12 13 13 12',
  ],
  'fleche-droite': ['M5 12h14', 'm12 5 7 7-7 7'],
  'fleche-gauche': ['m12 19-7-7 7-7', 'M19 12H5'],
  'horloge': ['M2 12a10 10 0 1 0 20 0a10 10 0 1 0 -20 0', 'M12 6v6l4 2'],
  'homme': ['M16 3h5v5', 'm21 3-6.75 6.75', 'M4 14a6 6 0 1 0 12 0a6 6 0 1 0 -12 0'],
  'femme': ['M12 15v7', 'M9 19h6', 'M6 9a6 6 0 1 0 12 0a6 6 0 1 0 -12 0'],
  'info': ['M2 12a10 10 0 1 0 20 0a10 10 0 1 0 -20 0', 'M12 16v-4', 'M12 8h.01'],
  'mail': [
    'M4 4h16a2 2 0 0 1 2 2v12a2 2 0 0 1-2 2H4a2 2 0 0 1-2-2V6a2 2 0 0 1 2-2z',
    'm22 7-8.97 5.7a1.94 1.94 0 0 1-2.06 0L2 7',
  ],
  'oeil': [
    'M2.06 12.35a1 1 0 0 1 0-.7 10.75 10.75 0 0 1 19.88 0 1 1 0 0 1 0 .7 10.75 10.75 0 0 1-19.88 0',
    'M9 12a3 3 0 1 0 6 0a3 3 0 1 0 -6 0',
  ],
  'oeil-barre': [
    'M10.73 5.08A10.43 10.43 0 0 1 12 5c7 0 10 7 10 7a13.16 13.16 0 0 1-1.67 2.68',
    'M6.61 6.61A13.53 13.53 0 0 0 2 12s3 7 10 7a9.74 9.74 0 0 0 5.39-1.61',
    'M14.12 14.12a3 3 0 1 1-4.24-4.24',
    'm2 2 20 20',
  ],
  'rafraichir': [
    'M3 12a9 9 0 0 1 9-9 9.75 9.75 0 0 1 6.74 2.74L21 8',
    'M21 3v5h-5',
    'M21 12a9 9 0 0 1-9 9 9.75 9.75 0 0 1-6.74-2.74L3 16',
    'M8 16H3v5',
  ],
  'telephone': ['M7 2h10a2 2 0 0 1 2 2v16a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2V4a2 2 0 0 1 2-2z', 'M12 18h.01'],
  'valide': ['M2 12a10 10 0 1 0 20 0a10 10 0 1 0 -20 0', 'm9 12 2 2 4-4'],
  'bouclier': [
    'M20 13c0 5-3.5 7.5-7.66 8.95a1 1 0 0 1-.67-.01C7.5 20.5 4 18 4 13V6a1 1 0 0 1 1-1c2 0 4.5-1.2 6.24-2.72a1.17 1.17 0 0 1 1.52 0C14.51 3.81 17 5 19 5a1 1 0 0 1 1 1z',
    'm9 12 2 2 4-4',
  ],
} as const;

export type NomIcone = keyof typeof ICONES;

@Component({
  selector: 'app-icone',
  template: `<svg
    viewBox="0 0 24 24"
    [attr.width]="taille()"
    [attr.height]="taille()"
    fill="none"
    stroke="currentColor"
    [attr.stroke-width]="epaisseur()"
    stroke-linecap="round"
    stroke-linejoin="round"
    aria-hidden="true"
    focusable="false"
  >
    @for (d of chemins(); track $index) {
      <path [attr.d]="d" />
    }
  </svg>`,
  styles: `
    :host {
      display: inline-flex;
      flex: none;
    }
  `,
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class Icone {
  readonly nom = input.required<NomIcone>();
  readonly taille = input(20);
  readonly epaisseur = input(2);
  protected readonly chemins = computed(() => ICONES[this.nom()]);
}
