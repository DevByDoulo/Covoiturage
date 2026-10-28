import { DatePipe } from '@angular/common';
import { ChangeDetectionStrategy, Component, OnInit, inject, signal } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { ErreurApi, lireErreur } from '../../core/api/erreur-api';
import { Alerte } from '../../shared/ui/alerte';
import { AvisADonner } from './avis.models';
import { AvisService } from './avis.service';
import { Etoiles } from './etoiles';

/**
 * 05 — « Donnez votre avis » : voyages terminés pas encore notés (le conducteur pour un passager, chaque passager
 * pour un conducteur). Rien n'est affiché quand il n'y a rien à noter.
 */
@Component({
  selector: 'app-avis-a-donner',
  imports: [FormsModule, DatePipe, Alerte, Etoiles],
  template: `
    @if (merci()) {
      <app-alerte type="succes">Merci pour votre avis !</app-alerte>
    }
    @if (aDonner().length) {
      <section class="carte bloc" aria-labelledby="titre-avis">
        <h2 id="titre-avis">Donnez votre avis</h2>
        @for (a of aDonner(); track a.idReservation) {
          <form class="avis" (submit)="$event.preventDefault(); envoyer(a)">
            <p>
              <strong>{{ a.role === 'CONDUCTEUR' ? 'Votre conducteur' : 'Votre passager' }} {{ a.aNoter.prenom }} {{ a.aNoter.nomInitiale }}</strong>
              <small>{{ a.trajet }} · {{ a.dateHeureDepart | date: 'd MMMM' }} · avant le {{ a.dateLimite | date: 'd MMMM' }}</small>
            </p>
            <app-etoiles [modifiable]="true" [(note)]="notes[a.idReservation]"
                         [libelle]="'Note pour ' + a.aNoter.prenom" />
            <textarea [name]="'commentaire-' + a.idReservation" rows="2" maxlength="500"
                      [placeholder]="a.role === 'CONDUCTEUR' ? 'Ponctualité, conduite, ambiance… (facultatif)' : 'Ponctualité, respect… (facultatif)'"
                      [(ngModel)]="commentaires[a.idReservation]"></textarea>
            @if (erreurs()[a.idReservation]; as e) {
              <app-alerte type="erreur">{{ e.message }}</app-alerte>
            }
            <button type="submit" class="bouton bouton--primaire" [disabled]="!notes[a.idReservation] || envoi() === a.idReservation">
              Publier mon avis
            </button>
          </form>
        }
      </section>
    }
  `,
  styles: `
    .avis {
      display: grid;
      gap: 8px;
      padding: 12px 0;
      border-top: 1px solid var(--bord);
    }
    .avis:first-of-type {
      border-top: 0;
    }
    .avis p {
      display: grid;
      gap: 2px;
      margin: 0;
    }
    small {
      color: var(--texte-2);
    }
    textarea {
      width: 100%;
      padding: 8px 10px;
      border: 1px solid var(--bord);
      border-radius: var(--rayon-petit);
      font: inherit;
      resize: vertical;
    }
  `,
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class AvisADonnerBloc implements OnInit {
  private readonly service = inject(AvisService);

  protected readonly aDonner = signal<AvisADonner[]>([]);
  protected readonly envoi = signal<number | null>(null);
  protected readonly erreurs = signal<Record<number, ErreurApi>>({});
  protected readonly merci = signal(false);
  protected notes: Record<number, number | null> = {};
  protected commentaires: Record<number, string> = {};

  ngOnInit(): void {
    this.service.aDonner().subscribe({ next: (l) => this.aDonner.set(l), error: () => this.aDonner.set([]) });
  }

  protected envoyer(a: AvisADonner): void {
    const note = this.notes[a.idReservation];
    if (!note) return;
    this.envoi.set(a.idReservation);
    this.merci.set(false);
    const commentaire = (this.commentaires[a.idReservation] ?? '').trim() || null;
    this.service.evaluer(a.idReservation, note, commentaire).subscribe({
      next: () => {
        this.envoi.set(null);
        this.merci.set(true);
        this.aDonner.update((l) => l.filter((x) => x.idReservation !== a.idReservation));
      },
      error: (e) => {
        this.envoi.set(null);
        this.erreurs.update((m) => ({ ...m, [a.idReservation]: lireErreur(e) }));
      },
    });
  }
}
