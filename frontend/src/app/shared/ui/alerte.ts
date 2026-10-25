import { ChangeDetectionStrategy, Component, computed, input } from '@angular/core';
import { Icone, NomIcone } from './icone';

export type TypeAlerte = 'erreur' | 'avertissement' | 'info' | 'succes';

const ICONE_PAR_TYPE: Record<TypeAlerte, NomIcone> = {
  erreur: 'alerte',
  avertissement: 'cadenas',
  info: 'info',
  succes: 'valide',
};

/** Encadré de message (erreur, blocage, information, succès) tel que dans les maquettes. */
@Component({
  selector: 'app-alerte',
  imports: [Icone],
  template: `
    <div class="alerte" [class]="'alerte alerte--' + type()" [attr.role]="type() === 'erreur' ? 'alert' : 'status'">
      <span class="alerte__icone"><app-icone [nom]="icone()" [taille]="18" /></span>
      <div>
        @if (titre()) {
          <p class="alerte__titre">{{ titre() }}</p>
        }
        <p class="alerte__texte"><ng-content /></p>
      </div>
    </div>
  `,
  styles: `
    .alerte {
      display: flex;
      align-items: center;
      gap: 12px;
      padding: 14px;
      border-radius: 14px;
      font-size: 13.5px;
    }
    .alerte__icone {
      display: grid;
      place-items: center;
      flex: none;
      width: 34px;
      height: 34px;
      border-radius: 10px;
      color: #fff;
    }
    .alerte__titre {
      margin: 0 0 2px;
      font-size: 15px;
      font-weight: 800;
    }
    .alerte__texte {
      margin: 0;
    }
    .alerte--erreur {
      background: var(--erreur-fond);
      color: var(--erreur);
      .alerte__icone {
        background: var(--erreur);
        border-radius: 50%;
      }
    }
    .alerte--avertissement {
      background: var(--orange-clair);
      color: var(--orange-fonce);
      .alerte__titre {
        color: var(--texte);
      }
      .alerte__icone {
        background: var(--orange);
      }
    }
    .alerte--info {
      background: var(--info-fond);
      color: var(--info);
      .alerte__icone {
        width: auto;
        height: auto;
        color: var(--info);
      }
    }
    .alerte--succes {
      background: var(--vert-clair);
      color: var(--vert-fonce);
      .alerte__icone {
        background: var(--vert);
        border-radius: 50%;
      }
    }
  `,
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class Alerte {
  readonly type = input<TypeAlerte>('erreur');
  readonly titre = input<string>();
  protected readonly icone = computed(() => ICONE_PAR_TYPE[this.type()]);
}
