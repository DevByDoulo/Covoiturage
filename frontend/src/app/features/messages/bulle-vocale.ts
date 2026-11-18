import { ChangeDetectionStrategy, Component, DestroyRef, computed, inject, input, output, signal } from '@angular/core';
import { lireErreur } from '../../core/api/erreur-api';
import { Icone } from '../../shared/ui/icone';
import { MessageConversation, MessagesService } from './messages.service';
import { formaterDuree, formaterDureeTotale } from './vocal';

const VITESSES = [1, 1.5, 2] as const;
/** Forme d'onde affichée quand l'application n'en a pas envoyé. */
const ONDE_PAR_DEFAUT = Array.from({ length: 32 }, (_, i) => 30 + ((i * 37) % 50));

/** Un seul vocal joue à la fois, comme sur WhatsApp. */
let lecteurEnCours: HTMLAudioElement | null = null;

/**
 * 09 — Bulle d'un message vocal : lecture / pause, forme d'onde cliquable (et pilotable au clavier), durée,
 * vitesse 1x / 1,5x / 2x, micro bleu une fois écouté par le destinataire. Le fichier n'est chargé qu'à la première
 * lecture, avec le jeton de session.
 */
@Component({
  selector: 'app-bulle-vocale',
  imports: [Icone],
  template: `
    @if (!message().audioDisponible) {
      <p class="indispo"><app-icone nom="micro" [taille]="16" /> {{ message().contenu ?? 'Message vocal expiré' }}</p>
    } @else {
      <div class="vocal">
        <button type="button" class="lire" (click)="basculer()" [disabled]="chargement()"
                [attr.aria-label]="lecture() ? 'Mettre en pause' : 'Écouter le message vocal'">
          <app-icone [nom]="lecture() ? 'pause' : 'jouer'" [taille]="18" />
        </button>
        <div class="onde" role="slider" tabindex="0" aria-label="Position de lecture"
             [attr.aria-valuemin]="0" [attr.aria-valuemax]="secondes()" [attr.aria-valuenow]="positionS()"
             [attr.aria-valuetext]="temps()" (click)="chercher($event)" (keydown)="clavier($event)">
          @for (n of barres(); track $index) {
            <span [style.height.%]="10 + n * 0.9" [class.joue]="$index < barresJouees()"></span>
          }
        </div>
        <button type="button" class="vitesse" (click)="changerVitesse()" aria-label="Vitesse de lecture">{{ libelleVitesse() }}</button>
      </div>
      <div class="infos">
        <span class="micro" [class.micro--ecoute]="message().ecoute" [attr.title]="message().ecoute ? 'Écouté' : 'Pas encore écouté'">
          <app-icone nom="micro" [taille]="14" />
        </span>
        <span>{{ temps() }}</span>
        @if (erreur(); as e) { <span class="erreur">{{ e }}</span> }
      </div>
    }
  `,
  styles: `
    :host { display: block; min-width: 230px; }
    .vocal { display: flex; align-items: center; gap: 8px; }
    .lire {
      display: grid; place-items: center; flex: none; width: 36px; height: 36px; padding: 0;
      border: 0; border-radius: 50%; background: var(--vert); color: #fff; cursor: pointer;
    }
    :host-context(.bulle--moi) .lire { background: #fff; color: var(--vert); }
    .onde {
      display: flex; flex: 1; align-items: center; gap: 2px; height: 30px; cursor: pointer;
      span { flex: 1; min-width: 2px; border-radius: 2px; background: currentColor; opacity: 0.35; }
      span.joue { opacity: 1; }
      &:focus-visible { outline: 2px solid currentColor; outline-offset: 2px; }
    }
    .vitesse {
      flex: none; min-width: 38px; padding: 2px 6px; border: 0; border-radius: 10px;
      background: rgba(0, 0, 0, 0.12); color: inherit; font: inherit; font-size: 12px; font-weight: 700; cursor: pointer;
    }
    .infos { display: flex; align-items: center; gap: 4px; margin-top: 2px; font-size: 11px; opacity: 0.85; }
    .micro { display: inline-flex; color: var(--vert); }
    :host-context(.bulle--moi) .micro { color: rgba(255, 255, 255, 0.75); }
    .micro--ecoute, :host-context(.bulle--moi) .micro--ecoute { color: #34b7f1; }
    .erreur { color: var(--rouge, #c62828); }
    .indispo { display: flex; align-items: center; gap: 6px; margin: 0; font-style: italic; opacity: 0.8; }
  `,
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class BulleVocale {
  private readonly service = inject(MessagesService);

  readonly idConversation = input.required<number>();
  readonly message = input.required<MessageConversation>();
  /** Le destinataire vient d'écouter le vocal (message mis à jour par le serveur). */
  readonly ecoute = output<MessageConversation>();

  protected readonly lecture = signal(false);
  protected readonly chargement = signal(false);
  protected readonly positionMs = signal(0);
  protected readonly vitesse = signal<(typeof VITESSES)[number]>(1);
  protected readonly erreur = signal<string | null>(null);

  private audio: HTMLAudioElement | null = null;
  private url: string | null = null;
  private ecouteSignalee = false;

  protected readonly dureeMs = computed(() => this.message().dureeMs ?? 0);
  protected readonly barres = computed(() => (this.message().formeOnde.length ? this.message().formeOnde : ONDE_PAR_DEFAUT));
  protected readonly barresJouees = computed(() =>
    this.dureeMs() ? Math.round((this.positionMs() / this.dureeMs()) * this.barres().length) : 0,
  );
  protected readonly temps = computed(() =>
    this.lecture() || this.positionMs() > 0 ? formaterDuree(this.positionMs()) : formaterDureeTotale(this.dureeMs()),
  );
  protected readonly secondes = computed(() => Math.round(this.dureeMs() / 1000));
  protected readonly positionS = computed(() => Math.round(this.positionMs() / 1000));
  protected readonly libelleVitesse = computed(() => `${String(this.vitesse()).replace('.', ',')}x`);

  constructor() {
    inject(DestroyRef).onDestroy(() => {
      this.audio?.pause();
      if (lecteurEnCours === this.audio) lecteurEnCours = null;
      if (this.url) URL.revokeObjectURL(this.url);
    });
  }

  protected basculer(): void {
    if (this.lecture()) {
      this.audio?.pause();
      return;
    }
    if (this.audio) {
      void this.jouer();
      return;
    }
    this.chargement.set(true);
    this.erreur.set(null);
    this.service.audio(this.idConversation(), this.message().id).subscribe({
      next: (blob) => {
        this.chargement.set(false);
        this.preparer(blob);
        void this.jouer();
      },
      error: (e) => {
        this.chargement.set(false);
        this.erreur.set(lireErreur(e).message);
      },
    });
  }

  protected changerVitesse(): void {
    const suivante = VITESSES[(VITESSES.indexOf(this.vitesse()) + 1) % VITESSES.length];
    this.vitesse.set(suivante);
    if (this.audio) this.audio.playbackRate = suivante;
  }

  /** Clic sur la forme d'onde : aller à cet endroit. */
  protected chercher(evenement: MouseEvent): void {
    const zone = (evenement.currentTarget as HTMLElement).getBoundingClientRect();
    if (!zone.width) return;
    this.allerA(((evenement.clientX - zone.left) / zone.width) * this.dureeMs());
  }

  /** Flèches : ± 5 secondes ; Début / Fin. */
  protected clavier(evenement: KeyboardEvent): void {
    const pas: Record<string, number> = { ArrowRight: 5000, ArrowLeft: -5000, ArrowUp: 5000, ArrowDown: -5000 };
    if (evenement.key in pas) this.allerA(this.positionMs() + pas[evenement.key]);
    else if (evenement.key === 'Home') this.allerA(0);
    else if (evenement.key === 'End') this.allerA(this.dureeMs());
    else return;
    evenement.preventDefault();
  }

  private allerA(ms: number): void {
    const cible = Math.min(Math.max(0, ms), this.dureeMs());
    this.positionMs.set(cible);
    if (this.audio) this.audio.currentTime = cible / 1000;
  }

  private preparer(blob: Blob): void {
    this.url = URL.createObjectURL(blob);
    const audio = new Audio(this.url);
    audio.playbackRate = this.vitesse();
    audio.currentTime = this.positionMs() / 1000;
    audio.addEventListener('timeupdate', () => this.positionMs.set(Math.min(audio.currentTime * 1000, this.dureeMs())));
    audio.addEventListener('play', () => this.lecture.set(true));
    audio.addEventListener('pause', () => this.lecture.set(false));
    audio.addEventListener('ended', () => {
      this.lecture.set(false);
      this.positionMs.set(0);
      audio.currentTime = 0;
    });
    this.audio = audio;
  }

  private async jouer(): Promise<void> {
    const audio = this.audio;
    if (!audio) return;
    if (lecteurEnCours && lecteurEnCours !== audio) lecteurEnCours.pause();
    lecteurEnCours = audio;
    try {
      await audio.play();
    } catch {
      this.erreur.set('Lecture impossible sur ce navigateur.');
      return;
    }
    const m = this.message();
    if (!m.deMoi && !m.ecoute && !this.ecouteSignalee) {
      this.ecouteSignalee = true;
      this.service.marquerEcoute(this.idConversation(), m.id).subscribe({
        next: (maj) => this.ecoute.emit(maj),
        error: () => (this.ecouteSignalee = false),
      });
    }
  }
}
