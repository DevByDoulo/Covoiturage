import { ChangeDetectionStrategy, Component, ElementRef, effect, inject, viewChild } from '@angular/core';
import { SessionService } from '../../core/auth/session.service';
import { Icone } from './icone';

/**
 * Fenêtre « Se déconnecter ? », placée une seule fois dans la racine de l'application. Tous les boutons
 * Déconnexion appellent `session.demanderDeconnexion()` ; la déconnexion n'a lieu qu'après confirmation.
 */
@Component({
  selector: 'app-confirmation-deconnexion',
  imports: [Icone],
  host: { '(document:keydown.escape)': 'annuler()' },
  template: `
    @if (session.confirmationDeconnexion()) {
      <div class="voile" (click)="annuler()"></div>
      <div class="fenetre" role="alertdialog" aria-modal="true" aria-labelledby="titre-deconnexion" aria-describedby="texte-deconnexion">
        <span class="fenetre__icone"><app-icone nom="deconnexion" [taille]="24" /></span>
        <h2 id="titre-deconnexion">Se déconnecter ?</h2>
        <p id="texte-deconnexion">Vous devrez saisir à nouveau votre identifiant et votre mot de passe pour revenir.</p>
        <div class="fenetre__actions">
          <button #annulerBouton class="bouton bouton--secondaire" type="button" (click)="annuler()">Annuler</button>
          <button class="bouton bouton--primaire" type="button" (click)="confirmer()">Se déconnecter</button>
        </div>
      </div>
    }
  `,
  styles: `
    .voile {
      position: fixed;
      inset: 0;
      z-index: 100;
      background: rgba(15, 23, 42, 0.45);
    }
    .fenetre {
      position: fixed;
      top: 50%;
      left: 50%;
      z-index: 101;
      display: flex;
      flex-direction: column;
      align-items: center;
      gap: 10px;
      width: min(400px, calc(100vw - 32px));
      padding: 24px;
      border-radius: 18px;
      background: var(--surface);
      box-shadow: 0 20px 50px rgba(15, 23, 42, 0.25);
      text-align: center;
      transform: translate(-50%, -50%);
      h2 {
        font-size: 20px;
      }
      p {
        margin: 0;
        color: var(--texte-2);
      }
    }
    .fenetre__icone {
      display: grid;
      place-items: center;
      width: 52px;
      height: 52px;
      border-radius: 50%;
      background: var(--vert-clair);
      color: var(--vert);
    }
    .fenetre__actions {
      display: grid;
      grid-template-columns: 1fr 1fr;
      gap: 10px;
      width: 100%;
      margin-top: 8px;
    }
  `,
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class ConfirmationDeconnexion {
  protected readonly session = inject(SessionService);
  private readonly annulerBouton = viewChild<ElementRef<HTMLButtonElement>>('annulerBouton');

  constructor() {
    // Le focus va sur « Annuler » : une touche Entrée par erreur ne déconnecte pas.
    effect(() => this.annulerBouton()?.nativeElement.focus());
  }

  protected annuler(): void {
    this.session.confirmationDeconnexion.set(false);
  }

  protected confirmer(): void {
    this.session.confirmationDeconnexion.set(false);
    this.session.deconnexion();
  }
}
