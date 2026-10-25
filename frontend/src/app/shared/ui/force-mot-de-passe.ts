import { ChangeDetectionStrategy, Component, computed, input } from '@angular/core';

/** 0 = vide, 1 = faible, 2 = moyen, 3 = sécurisé. */
export function forceMotDePasse(mdp: string): 0 | 1 | 2 | 3 {
  if (!mdp) return 0;
  let points = 0;
  if (mdp.length >= 8) points++;
  if (mdp.length >= 12) points++;
  if (/[a-z]/.test(mdp) && /[A-Z]/.test(mdp)) points++;
  if (/\d/.test(mdp)) points++;
  if (/[^A-Za-z0-9]/.test(mdp)) points++;
  const regleDeBase = mdp.length >= 8 && /[A-Za-z]/.test(mdp) && /\d/.test(mdp);
  if (!regleDeBase) return 1;
  return points >= 4 ? 3 : 2;
}

const LIBELLES = ['', 'Faible', 'Moyen', 'Sécurisé'];

@Component({
  selector: 'app-force-mot-de-passe',
  template: `
    <div class="force" [attr.data-niveau]="niveau()">
      <div class="force__entete">
        <span>Sécurité du mot de passe</span>
        <strong aria-live="polite">{{ libelle() }}</strong>
      </div>
      <div class="force__barres" aria-hidden="true">
        @for (i of [1, 2, 3]; track i) {
          <span [class.active]="niveau() >= i"></span>
        }
      </div>
    </div>
  `,
  styles: `
    .force {
      padding: 10px 12px;
      border-radius: 10px;
      background: var(--surface-2);
      font-size: 12.5px;
      color: var(--texte-2);
    }
    .force__entete {
      display: flex;
      justify-content: space-between;
      margin-bottom: 8px;
    }
    .force__barres {
      display: grid;
      grid-template-columns: repeat(3, 1fr);
      gap: 6px;
      span {
        height: 5px;
        border-radius: 3px;
        background: #d5dbe7;
      }
    }
    [data-niveau='1'] { strong { color: var(--erreur); } .active { background: var(--erreur); } }
    [data-niveau='2'] { strong { color: var(--orange-fonce); } .active { background: var(--orange); } }
    [data-niveau='3'] { strong { color: var(--vert); } .active { background: var(--vert); } }
  `,
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class ForceMotDePasse {
  readonly motDePasse = input('');
  protected readonly niveau = computed(() => forceMotDePasse(this.motDePasse()));
  protected readonly libelle = computed(() => LIBELLES[this.niveau()]);
}
