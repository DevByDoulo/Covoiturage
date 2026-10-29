import { DatePipe } from '@angular/common';
import {
  ChangeDetectionStrategy,
  Component,
  DestroyRef,
  ElementRef,
  Injector,
  afterNextRender,
  computed,
  effect,
  inject,
  input,
  signal,
  untracked,
  viewChild,
} from '@angular/core';
import { RouterLink } from '@angular/router';
import { ErreurApi, lireErreur } from '../../core/api/erreur-api';
import { Alerte } from '../../shared/ui/alerte';
import { Icone } from '../../shared/ui/icone';
import { initiales, urlFichier } from '../profil/profil.service';
import { ConversationDetail, MessageConversation, MessagesService } from './messages.service';

/** Nouveaux messages vérifiés toutes les 5 s tant que la conversation est affichée et l'onglet visible. */
const INTERVALLE_MS = 5_000;

interface Ligne {
  jour: string | null;
  message: MessageConversation;
}

/** 09 — Une conversation : fil des messages (les miens à droite) et zone de saisie. */
@Component({
  selector: 'app-conversation',
  imports: [RouterLink, DatePipe, Icone, Alerte],
  templateUrl: './conversation.html',
  styleUrl: './conversation.scss',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class ConversationPage {
  private readonly service = inject(MessagesService);
  private readonly injecteur = inject(Injector);
  private readonly fil = viewChild<ElementRef<HTMLElement>>('fil');

  readonly id = input.required<string>();

  protected readonly conversation = signal<ConversationDetail | null>(null);
  protected readonly erreur = signal<ErreurApi | null>(null);
  protected readonly texte = signal('');
  protected readonly envoi = signal(false);
  protected readonly erreurEnvoi = signal<string | null>(null);
  protected readonly maxCaracteres = 1000;

  protected readonly photo = computed(() => urlFichier(this.conversation()?.interlocuteur.photoProfil ?? null));
  protected readonly initiales = computed(() => {
    const i = this.conversation()?.interlocuteur;
    return i ? initiales(`${i.prenom} ${i.nomInitiale}`) : '';
  });

  /** Messages avec le jour affiché au-dessus du premier message de chaque journée. */
  protected readonly lignes = computed<Ligne[]>(() => {
    let precedent = '';
    return (this.conversation()?.messages ?? []).map((m) => {
      const jour = m.dateEnvoi.slice(0, 10);
      const ligne = { jour: jour !== precedent ? m.dateEnvoi : null, message: m };
      precedent = jour;
      return ligne;
    });
  });
  protected readonly dernierEnvoyeId = computed(() => {
    const miens = (this.conversation()?.messages ?? []).filter((m) => m.deMoi);
    return miens.length ? miens[miens.length - 1].id : null;
  });

  constructor() {
    effect(() => {
      const id = Number(this.id());
      untracked(() => {
        this.conversation.set(null);
        this.charger(id, true);
      });
    });
    const minuterie = setInterval(() => {
      const c = this.conversation();
      if (c && document.visibilityState === 'visible') this.charger(c.id, false);
    }, INTERVALLE_MS);
    inject(DestroyRef).onDestroy(() => clearInterval(minuterie));
  }

  protected envoyer(): void {
    const c = this.conversation();
    const contenu = this.texte().trim();
    if (!c || !contenu || this.envoi()) return;
    this.envoi.set(true);
    this.erreurEnvoi.set(null);
    this.service.envoyer(c.id, contenu).subscribe({
      next: (m) => {
        this.texte.set('');
        this.envoi.set(false);
        this.conversation.update((x) => (x ? { ...x, messages: [...x.messages, m] } : x));
        this.defiler();
      },
      error: (e) => {
        this.erreurEnvoi.set(lireErreur(e).message);
        this.envoi.set(false);
      },
    });
  }

  /** Entrée envoie, Maj+Entrée va à la ligne. */
  protected touche(evenement: KeyboardEvent): void {
    if (evenement.key === 'Enter' && !evenement.shiftKey) {
      evenement.preventDefault();
      this.envoyer();
    }
  }

  protected saisir(evenement: Event): void {
    this.texte.set((evenement.target as HTMLTextAreaElement).value);
  }

  private charger(id: number, premier: boolean): void {
    this.service.consulter(id).subscribe({
      next: (c) => {
        const avant = this.conversation()?.messages.length ?? 0;
        this.conversation.set(c);
        this.erreur.set(null);
        if (premier || c.messages.length > avant) this.defiler();
      },
      error: (e) => {
        if (premier) this.erreur.set(lireErreur(e));
      },
    });
  }

  private defiler(): void {
    afterNextRender(
      () => {
        const el = this.fil()?.nativeElement;
        if (el) el.scrollTop = el.scrollHeight;
      },
      { injector: this.injecteur },
    );
  }
}
