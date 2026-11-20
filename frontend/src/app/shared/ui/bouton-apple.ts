import { ChangeDetectionStrategy, Component, input, output, signal } from '@angular/core';
import { environment } from '../../../environments/environment';

/** Réponse de « Se connecter avec Apple » utile au backend. Prénom et nom : au premier accès seulement. */
export interface ReponseApple {
  idToken: string;
  prenom?: string;
  nom?: string;
}

/** Sous-ensemble de la bibliothèque « Sign in with Apple JS » utilisé ici. */
interface AppleIdAuth {
  auth: {
    init(config: { clientId: string; scope: string; redirectURI: string; usePopup: boolean }): void;
    signIn(): Promise<{
      authorization: { id_token: string };
      user?: { name?: { firstName?: string; lastName?: string } };
    }>;
  };
}

const SCRIPT_APPLE = 'https://appleid.cdn-apple.com/appleauth/static/jsapi/appleid/1/fr_FR/appleid.auth.js';
let chargementApple: Promise<AppleIdAuth> | null = null;

function chargerApple(): Promise<AppleIdAuth> {
  chargementApple ??= new Promise((resolve, reject) => {
    const script = document.createElement('script');
    script.src = SCRIPT_APPLE;
    script.async = true;
    script.onload = () => resolve((window as unknown as { AppleID: AppleIdAuth }).AppleID);
    script.onerror = () => {
      chargementApple = null;
      reject(new Error('Sign in with Apple indisponible'));
    };
    document.head.appendChild(script);
  });
  return chargementApple;
}

/** Fenêtre fermée ou refus de la personne : rien à signaler. */
export function estAbandonApple(erreur: unknown): boolean {
  const code = (erreur as { error?: string } | null)?.error;
  return code === 'popup_closed_by_user' || code === 'user_cancelled_authorize' || code === 'user_trigger_new_signin_flow';
}

/**
 * « Continuer avec Apple » (fenêtre Apple, bibliothèque officielle chargée au premier clic). Sans Services ID
 * configuré (`environment.apple`), le clic signale que la connexion Apple n'est pas activée.
 */
@Component({
  selector: 'app-bouton-apple',
  template: `
    <button type="button" class="bouton bouton--secondaire bouton-apple" [class.rond]="variante() === 'icone'"
            [attr.aria-label]="variante() === 'icone' ? libelle() : null" [disabled]="ouverture()" (click)="ouvrir()">
      <svg viewBox="0 0 17 20" width="17" height="20" aria-hidden="true">
        <path fill="currentColor" d="M14.1 10.6c0-2.6 2.1-3.8 2.2-3.9-1.2-1.8-3.1-2-3.7-2-1.6-.2-3.1.9-3.9.9-.8 0-2-.9-3.4-.9-1.7 0-3.3 1-4.2 2.6-1.8 3.1-.5 7.7 1.3 10.2.8 1.2 1.8 2.6 3.1 2.5 1.2 0 1.7-.8 3.2-.8s1.9.8 3.2.8c1.3 0 2.2-1.2 3-2.5 1-1.4 1.4-2.8 1.4-2.9 0 0-2.7-1-2.7-4zM11.6 3c.7-.8 1.1-1.9 1-3-1 0-2.1.7-2.8 1.5-.6.7-1.2 1.8-1 2.9 1 .1 2.1-.6 2.8-1.4z" />
      </svg>
      @if (variante() === 'bouton') { {{ libelle() }} }
    </button>
  `,
  styles: `
    :host { display: block; }
    .bouton-apple svg { flex: none; }
    /* Variante « icône » : pastille ronde, libellé gardé pour les lecteurs d'écran. */
    .rond {
      width: 56px;
      min-height: 56px;
      padding: 0;
      border-radius: 50%;
    }
  `,
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class BoutonApple {
  readonly libelle = input('Continuer avec Apple');
  /** « bouton » (avec le libellé) ou « icone » : la pomme seule, dans une pastille ronde. */
  readonly variante = input<'bouton' | 'icone'>('bouton');
  /** Jeton Apple (et nom au premier accès) à transmettre au backend. */
  readonly reponse = output<ReponseApple>();
  /** Apple n'est pas configuré, ou sa bibliothèque n'a pas pu être chargée. */
  readonly indisponible = output<void>();
  /** Autre échec de la fenêtre Apple. */
  readonly echec = output<void>();

  protected readonly ouverture = signal(false);

  protected async ouvrir(): Promise<void> {
    const { clientId, redirectUri } = environment.apple;
    if (!clientId || !redirectUri) {
      this.indisponible.emit();
      return;
    }
    this.ouverture.set(true);
    try {
      let apple: AppleIdAuth;
      try {
        apple = await chargerApple();
      } catch {
        this.indisponible.emit();
        return;
      }
      apple.auth.init({ clientId, scope: 'name email', redirectURI: redirectUri, usePopup: true });
      const r = await apple.auth.signIn();
      this.reponse.emit({
        idToken: r.authorization.id_token,
        prenom: r.user?.name?.firstName || undefined,
        nom: r.user?.name?.lastName || undefined,
      });
    } catch (e) {
      if (!estAbandonApple(e)) this.echec.emit();
    } finally {
      this.ouverture.set(false);
    }
  }
}
