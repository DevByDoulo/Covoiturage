import { DatePipe } from '@angular/common';
import { ChangeDetectionStrategy, Component, computed, inject, input, output, signal } from '@angular/core';
import { lireErreur } from '../../core/api/erreur-api';
import { Alerte } from '../../shared/ui/alerte';
import { Icone, NomIcone } from '../../shared/ui/icone';
import { PieceJustificative, TypeDocument, VehiculesService } from './vehicules.service';

const TAILLE_MAX = 5 * 1024 * 1024;

/** Une pièce à fournir (permis, pièce d'identité, carte grise) : statut, motif de refus, envoi ou renvoi du fichier. */
@Component({
  selector: 'app-piece-document',
  imports: [Icone, Alerte, DatePipe],
  template: `
    <article class="carte piece">
      <div class="piece__ligne">
        <span class="pictogramme" [class]="'pictogramme pictogramme--' + ton()"><app-icone [nom]="icone()" [taille]="22" /></span>
        <div class="piece__texte">
          <strong>{{ titre() }}</strong>
          <small>
            @if (piece(); as p) {
              {{ detail() }} • envoyé le {{ p.dateSoumission | date: 'd MMM' }}
            } @else {
              {{ detail() }}
            }
          </small>
        </div>
        @switch (piece()?.statutValidation) {
          @case ('VALIDE') {
            <span class="pastille pastille--succes"><app-icone nom="valide" [taille]="14" /> Validé</span>
          }
          @case ('EN_ATTENTE') {
            <span class="pastille pastille--attente"><app-icone nom="horloge" [taille]="14" /> En attente</span>
          }
          @case ('REFUSE') {
            <span class="pastille pastille--erreur"><app-icone nom="croix" [taille]="14" /> Refusé</span>
          }
          @default {
            <span class="pastille manquant">À fournir</span>
          }
        }
      </div>

      @if (piece()?.statutValidation === 'REFUSE') {
        <app-alerte type="erreur">{{ piece()?.commentaireAdmin || "Document refusé : merci d'en envoyer un nouveau." }}</app-alerte>
      }
      @if (erreur(); as e) {
        <app-alerte type="erreur">{{ e }}</app-alerte>
      }

      <div class="piece__actions">
        @if (piece(); as p) {
          <button class="bouton-lien" type="button" (click)="vehicules.ouvrirFichier(p)">Voir le fichier</button>
        }
        @if (piece()?.statutValidation !== 'VALIDE') {
          <label class="bouton bouton--primaire envoyer" [class.envoyer--occupe]="envoi()">
            <input class="sr-only" type="file" accept="image/jpeg,image/png,application/pdf" (change)="choisir($event)" [disabled]="envoi()" />
            @if (envoi()) {
              <span class="chargement" aria-hidden="true"></span> Envoi…
            } @else {
              <app-icone nom="televerser" [taille]="18" /> {{ piece() ? 'Renvoyer le document' : 'Envoyer le document' }}
            }
          </label>
        }
      </div>
    </article>
  `,
  styles: `
    .piece {
      display: flex;
      flex-direction: column;
      gap: 12px;
    }
    .piece__ligne {
      display: flex;
      align-items: center;
      gap: 12px;
    }
    .pictogramme {
      display: grid;
      place-items: center;
      flex: none;
      width: 48px;
      height: 48px;
      border-radius: 14px;
      background: var(--surface-2);
      color: var(--texte-2);
    }
    .pictogramme--succes {
      background: var(--vert-clair);
      color: var(--vert);
    }
    .pictogramme--attente {
      background: var(--orange-clair);
      color: var(--orange-fonce);
    }
    .pictogramme--erreur {
      background: var(--erreur-fond);
      color: var(--erreur);
    }
    .piece__texte {
      display: flex;
      flex: 1;
      flex-direction: column;
      min-width: 0;
      small {
        color: var(--texte-3);
      }
    }
    .manquant {
      background: var(--surface-2);
      color: var(--texte-2);
    }
    .piece__actions {
      display: flex;
      flex-wrap: wrap;
      align-items: center;
      justify-content: flex-end;
      gap: 12px;
      &:empty {
        display: none;
      }
    }
    .envoyer {
      width: auto;
      padding: 0 18px;
      cursor: pointer;
      &:focus-within {
        outline: 3px solid rgba(12, 107, 63, 0.35);
      }
    }
    .envoyer--occupe {
      cursor: progress;
    }
  `,
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class PieceDocument {
  protected readonly vehicules = inject(VehiculesService);

  readonly type = input.required<TypeDocument>();
  readonly titre = input.required<string>();
  readonly detail = input.required<string>();
  readonly icone = input.required<NomIcone>();
  readonly piece = input<PieceJustificative | null>(null);
  readonly idVehicule = input<number | null>(null);
  readonly envoye = output<PieceJustificative>();

  protected readonly envoi = signal(false);
  protected readonly erreur = signal<string | null>(null);
  protected readonly ton = computed(() => {
    switch (this.piece()?.statutValidation) {
      case 'VALIDE':
        return 'succes';
      case 'EN_ATTENTE':
        return 'attente';
      case 'REFUSE':
        return 'erreur';
      default:
        return 'neutre';
    }
  });

  protected choisir(evenement: Event): void {
    const champ = evenement.target as HTMLInputElement;
    const fichier = champ.files?.[0];
    champ.value = '';
    if (!fichier) return;
    if (fichier.size > TAILLE_MAX) {
      this.erreur.set('Le fichier dépasse 5 Mo. Envoyez une photo ou un PDF plus léger.');
      return;
    }
    this.envoi.set(true);
    this.erreur.set(null);
    this.vehicules.soumettre(this.type(), fichier, this.idVehicule()).subscribe({
      next: (p) => {
        this.envoi.set(false);
        this.envoye.emit(p);
      },
      error: (e) => {
        this.erreur.set(lireErreur(e).message);
        this.envoi.set(false);
      },
    });
  }
}
