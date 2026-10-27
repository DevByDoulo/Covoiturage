import { ChangeDetectionStrategy, Component, inject, input, signal } from '@angular/core';
import { lireErreur } from '../../core/api/erreur-api';
import { Preferences } from '../../core/auth/auth.models';
import { Alerte } from '../../shared/ui/alerte';
import { Icone, NomIcone } from '../../shared/ui/icone';
import { ProfilService } from './profil.service';

interface Option {
  cle: keyof Preferences;
  titre: string;
  detail: string;
  icone: NomIcone;
}

const OPTIONS: Option[] = [
  { cle: 'fumeurAccepte', titre: 'Fumeur accepté', detail: 'Cigarette autorisée pendant le trajet', icone: 'sans-tabac' },
  { cle: 'musiqueAcceptee', titre: 'Musique', detail: 'Mbalax, acoustique, afro-pop…', icone: 'musique' },
  { cle: 'animauxAcceptes', titre: 'Animaux acceptés', detail: 'Chiens ou chats en cage', icone: 'patte' },
  { cle: 'discussionAcceptee', titre: "J'aime discuter", detail: 'Échanges chaleureux et teranga', icone: 'discussion' },
];

/** Préférences de trajet, enregistrées dès qu'un interrupteur change (annulé en cas d'erreur). */
@Component({
  selector: 'app-preferences-trajet',
  imports: [Icone, Alerte],
  template: `
    <section class="carte bloc">
      <h2><app-icone nom="liste" /> Préférences de trajet</h2>
      <ul class="options">
        @for (o of options; track o.cle) {
          <li>
            <span class="pictogramme"><app-icone [nom]="o.icone" [taille]="19" /></span>
            <label [for]="o.cle">
              <strong>{{ o.titre }}</strong>
              <small>{{ o.detail }}</small>
            </label>
            <input class="interrupteur" type="checkbox" role="switch" [id]="o.cle"
              [checked]="valeurs()[o.cle]" [disabled]="enCours()" (change)="basculer(o.cle, $event)" />
          </li>
        }
      </ul>
      @if (erreur(); as e) {
        <app-alerte type="erreur">{{ e }}</app-alerte>
      }
    </section>
  `,
  styles: `
    .options {
      display: flex;
      flex-direction: column;
      gap: 10px;
      margin: 0;
      padding: 0;
      list-style: none;
    }
    li {
      display: flex;
      align-items: center;
      gap: 12px;
      padding: 12px 14px;
      border-radius: var(--rayon);
      background: var(--surface-2);
    }
    .pictogramme {
      display: grid;
      place-items: center;
      flex: none;
      width: 40px;
      height: 40px;
      border-radius: 50%;
      background: var(--vert-clair);
      color: var(--vert);
    }
    label {
      display: flex;
      flex: 1;
      flex-direction: column;
      min-width: 0;
      cursor: pointer;
      small {
        color: var(--texte-3);
      }
    }
  `,
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class PreferencesTrajet {
  private readonly profils = inject(ProfilService);

  readonly valeurs = input.required<Preferences>();

  protected readonly options = OPTIONS;
  protected readonly enCours = signal(false);
  protected readonly erreur = signal<string | null>(null);

  protected basculer(cle: keyof Preferences, evenement: Event): void {
    const ancienne = this.valeurs()[cle];
    const nouvelles = { ...this.valeurs(), [cle]: !ancienne };
    this.enCours.set(true);
    this.erreur.set(null);
    // La session (et donc valeurs()) est mise à jour par la réponse ; en cas d'erreur, on remet l'interrupteur.
    this.profils.modifierPreferences(nouvelles).subscribe({
      next: () => this.enCours.set(false),
      error: (e) => {
        (evenement.target as HTMLInputElement).checked = ancienne;
        this.erreur.set(lireErreur(e).message);
        this.enCours.set(false);
      },
    });
  }
}
