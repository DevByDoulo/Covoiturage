import { ChangeDetectionStrategy, Component } from '@angular/core';

@Component({
  selector: 'app-drapeau-senegal',
  template: `<svg viewBox="0 0 30 20" width="21" height="14" aria-hidden="true">
    <rect width="10" height="20" fill="#00853f" />
    <rect x="10" width="10" height="20" fill="#fdef42" />
    <rect x="20" width="10" height="20" fill="#e31b23" />
    <path d="M15 6.2l1 3h3.1l-2.5 1.8 1 3-2.6-1.9-2.6 1.9 1-3-2.5-1.8H14z" fill="#00853f" />
  </svg>`,
  styles: `:host { display: inline-flex; border-radius: 2px; overflow: hidden; }`,
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class DrapeauSenegal {}
