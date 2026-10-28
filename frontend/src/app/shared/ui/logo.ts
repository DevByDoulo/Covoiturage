import { ChangeDetectionStrategy, Component, input } from '@angular/core';

/** Logo YOBALEMAsn : repère de localisation avec une route, « YOBALEMA » en vert et « sn » en orange. */
@Component({
  selector: 'app-logo',
  template: `
    <span class="logo" [class.logo--compact]="compact()" role="img" aria-label="YOBALEMAsn">
      <svg viewBox="0 0 40 48" class="logo__pin" aria-hidden="true">
        <path
          d="M20 46c-1 0-15-15.3-15-27A15 15 0 0 1 35 19c0 11.7-14 27-15 27z"
          fill="#0c6b3f"
        />
        <circle cx="20" cy="19" r="10.5" fill="#fff" />
        <path d="M13 23.5c2.2-5.3 4.3-8 7-8s4.8 2.7 7 8" fill="none" stroke="#f29a1f" stroke-width="2.6" stroke-linecap="round" />
        <path d="M20 17.5v1.6M20 21.3v1.6" stroke="#0c6b3f" stroke-width="1.6" stroke-linecap="round" />
        <path d="M27.5 9.5c-3 .2-5 2.2-5.2 5 2.9-.1 4.9-2.1 5.2-5z" fill="#2fa36a" />
      </svg>
      @if (!compact()) {
        <span class="logo__texte">YOBALEMA<span class="logo__suffixe">sn</span></span>
      }
    </span>
  `,
  styles: `
    .logo {
      display: inline-flex;
      align-items: center;
      gap: 6px;
    }
    .logo__pin {
      width: 30px;
      height: 36px;
    }
    .logo--compact .logo__pin {
      width: 20px;
      height: 24px;
    }
    .logo__texte {
      font-size: 22px;
      font-weight: 800;
      letter-spacing: -0.03em;
      /* Surchargeable par le parent (ex. blanc sur le menu vert). */
      color: var(--logo-texte, #0c6b3f);
    }
    .logo__suffixe {
      color: #f29a1f;
    }
  `,
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class Logo {
  readonly compact = input(false);
}
