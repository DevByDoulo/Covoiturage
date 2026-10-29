import { ChangeDetectionStrategy, Component, inject, input, signal } from '@angular/core';
import { Router } from '@angular/router';
import { lireErreur } from '../../core/api/erreur-api';
import { Icone } from '../../shared/ui/icone';
import { MessagesService } from './messages.service';

/**
 * Bouton « Écrire » à poser sur un écran de trajet ou de réservation : ouvre (ou crée) la conversation du trajet
 * puis l'affiche. Le passager n'indique que le trajet ; le conducteur indique aussi le passager.
 */
@Component({
  selector: 'app-bouton-message',
  imports: [Icone],
  template: `
    <button type="button" [class]="variante() === 'lien' ? 'bouton-lien' : 'bouton bouton--secondaire'"
            [disabled]="ouverture()" (click)="ouvrir()">
      <app-icone nom="discussion" [taille]="16" /> {{ libelle() }}
    </button>
    @if (erreur(); as e) {
      <p class="message-erreur">{{ e }}</p>
    }
  `,
  styles: `
    :host { display: contents; }
    p { flex-basis: 100%; margin: 4px 0 0; }
  `,
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class BoutonMessage {
  private readonly service = inject(MessagesService);
  private readonly router = inject(Router);

  readonly idTrajet = input.required<number>();
  readonly idPassager = input<number>();
  readonly libelle = input('Écrire');
  readonly variante = input<'bouton' | 'lien'>('bouton');

  protected readonly ouverture = signal(false);
  protected readonly erreur = signal<string | null>(null);

  protected ouvrir(): void {
    this.ouverture.set(true);
    this.erreur.set(null);
    this.service.ouvrir(this.idTrajet(), this.idPassager()).subscribe({
      next: (id) => this.router.navigate(['/messages', id]),
      error: (e) => {
        this.erreur.set(lireErreur(e).message);
        this.ouverture.set(false);
      },
    });
  }
}
