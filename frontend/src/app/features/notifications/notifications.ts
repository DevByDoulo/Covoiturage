import { DatePipe } from '@angular/common';
import { ChangeDetectionStrategy, Component, inject, signal } from '@angular/core';
import { Router } from '@angular/router';
import { ErreurApi, lireErreur } from '../../core/api/erreur-api';
import { Alerte } from '../../shared/ui/alerte';
import { Icone, NomIcone } from '../../shared/ui/icone';
import { Notification, NotificationsService, TypeNotification } from './notifications.service';

const ICONES: Record<TypeNotification, NomIcone> = {
  RESERVATION_DEMANDEE: 'utilisateurs',
  RESERVATION_CONFIRMEE: 'valide',
  RESERVATION_REFUSEE: 'croix',
  RESERVATION_ANNULEE: 'croix',
  TRAJET_MODIFIE: 'crayon',
  TRAJET_ANNULE: 'alerte',
  RAPPEL_TRAJET: 'horloge',
  EMBARQUEMENT_CONFIRME: 'voiture',
  DOCUMENT_VALIDE: 'document',
  DOCUMENT_REFUSE: 'document',
  COMPTE_SUSPENDU: 'bouclier',
  COMPTE_REACTIVE: 'bouclier',
  ALERTE_TRAJET: 'recherche',
};

/** Ton de l'icône : vert (bonne nouvelle), orange (à regarder), rouge (annulation, refus). */
const TONS: Partial<Record<TypeNotification, 'succes' | 'attente' | 'erreur'>> = {
  RESERVATION_CONFIRMEE: 'succes',
  EMBARQUEMENT_CONFIRME: 'succes',
  DOCUMENT_VALIDE: 'succes',
  COMPTE_REACTIVE: 'succes',
  RESERVATION_DEMANDEE: 'attente',
  TRAJET_MODIFIE: 'attente',
  RAPPEL_TRAJET: 'attente',
  RESERVATION_REFUSEE: 'erreur',
  RESERVATION_ANNULEE: 'erreur',
  TRAJET_ANNULE: 'erreur',
  DOCUMENT_REFUSE: 'erreur',
  COMPTE_SUSPENDU: 'erreur',
};

/** Écran « Notifications » (module 06) : liste, non lues mises en avant, ouverture de l'écran concerné au clic. */
@Component({
  selector: 'app-notifications',
  imports: [DatePipe, Icone, Alerte],
  template: `
    <div class="page">
      <header class="titre">
        <h1>Notifications</h1>
        @if (service.nonLues()) {
          <button class="bouton-lien" type="button" (click)="toutLire()">Tout marquer comme lu</button>
        }
      </header>

      @if (erreur(); as e) {
        <app-alerte type="erreur">{{ e.message }}</app-alerte>
      }

      <ul class="liste">
        @for (n of liste(); track n.id) {
          <li>
            <button type="button" class="carte notification" [class.notification--non-lue]="!n.lu" (click)="ouvrir(n)">
              <span class="pictogramme" [class]="'pictogramme pictogramme--' + (tons[n.type] || 'neutre')">
                <app-icone [nom]="icones[n.type]" [taille]="20" />
              </span>
              <span class="texte">
                <strong>{{ n.titre }}</strong>
                <span>{{ n.contenu }}</span>
                <small>{{ n.dateEnvoi | date: "EEEE d MMMM 'à' HH'h'mm" }}</small>
              </span>
              @if (!n.lu) {
                <span class="point" aria-label="Non lue"></span>
              }
            </button>
          </li>
        } @empty {
          @if (charge()) {
            <li class="vide">
              <app-icone nom="cloche" [taille]="32" />
              <strong>Aucune notification</strong>
              <span>Vous serez prévenu ici de vos réservations, de vos trajets et de vos documents.</span>
            </li>
          }
        }
      </ul>

      @if (page() + 1 < pages()) {
        <button class="bouton bouton--secondaire" type="button" (click)="suite()">Voir plus</button>
      }
    </div>
  `,
  styles: `
    .page {
      display: flex;
      flex-direction: column;
      gap: 14px;
      max-width: 720px;
      margin: 0 auto;
    }
    .titre {
      display: flex;
      align-items: center;
      justify-content: space-between;
      h1 {
        font-size: 26px;
      }
    }
    .liste {
      display: flex;
      flex-direction: column;
      gap: 8px;
      margin: 0;
      padding: 0;
      list-style: none;
    }
    .notification {
      display: flex;
      align-items: flex-start;
      gap: 14px;
      width: 100%;
      border: 0;
      text-align: left;
      font: inherit;
      color: var(--texte);
      cursor: pointer;
      &:hover {
        box-shadow: 0 0 0 2px var(--vert-clair), var(--ombre);
      }
    }
    .notification--non-lue {
      background: #f2fbf6;
    }
    .pictogramme {
      display: grid;
      place-items: center;
      flex: none;
      width: 42px;
      height: 42px;
      border-radius: 50%;
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
    .texte {
      display: flex;
      flex: 1;
      flex-direction: column;
      gap: 3px;
      min-width: 0;
      span {
        color: var(--texte-2);
      }
      small {
        color: var(--texte-3);
      }
    }
    .point {
      flex: none;
      width: 10px;
      height: 10px;
      margin-top: 6px;
      border-radius: 50%;
      background: var(--vert);
    }
    .vide {
      display: flex;
      flex-direction: column;
      align-items: center;
      gap: 6px;
      padding: 40px 16px;
      text-align: center;
      color: var(--texte-2);
      app-icone {
        color: var(--texte-3);
      }
    }
  `,
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class NotificationsPage {
  protected readonly service = inject(NotificationsService);
  private readonly router = inject(Router);

  protected readonly icones = ICONES;
  protected readonly tons = TONS;
  protected readonly liste = signal<Notification[]>([]);
  protected readonly page = signal(0);
  protected readonly pages = signal(0);
  protected readonly charge = signal(false);
  protected readonly erreur = signal<ErreurApi | null>(null);

  constructor() {
    this.charger(0);
    this.service.compter();
  }

  protected suite(): void {
    this.charger(this.page() + 1);
  }

  /** Marque comme lue puis ouvre l'écran concerné. */
  protected ouvrir(n: Notification): void {
    if (!n.lu) {
      this.service.marquerLue(n).subscribe({ error: () => {} });
      this.liste.update((l) => l.map((x) => (x.id === n.id ? { ...x, lu: true } : x)));
    }
    if (n.lien) this.router.navigateByUrl(n.lien);
  }

  protected toutLire(): void {
    this.service.toutesLues().subscribe({
      next: () => this.liste.update((l) => l.map((x) => ({ ...x, lu: true }))),
      error: (e) => this.erreur.set(lireErreur(e)),
    });
  }

  private charger(page: number): void {
    this.service.lister(page).subscribe({
      next: (p) => {
        this.liste.update((l) => (page === 0 ? p.content : [...l, ...p.content]));
        this.page.set(p.page.number);
        this.pages.set(p.page.totalPages);
        this.charge.set(true);
      },
      error: (e) => this.erreur.set(lireErreur(e)),
    });
  }
}
