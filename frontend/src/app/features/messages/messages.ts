import { DatePipe } from '@angular/common';
import { ChangeDetectionStrategy, Component, inject, signal } from '@angular/core';
import { RouterLink } from '@angular/router';
import { ErreurApi, lireErreur } from '../../core/api/erreur-api';
import { Alerte } from '../../shared/ui/alerte';
import { Icone } from '../../shared/ui/icone';
import { initiales, urlFichier } from '../profil/profil.service';
import { ConversationResume, MessagesService } from './messages.service';

/** 09 — Liste des conversations, la plus récente d'abord, avec les messages non lus. */
@Component({
  selector: 'app-messages',
  imports: [RouterLink, DatePipe, Icone, Alerte],
  template: `
    <header class="entete">
      <h1>Messages</h1>
      <p>Vos échanges avec les conducteurs et les passagers de vos trajets.</p>
    </header>

    @if (erreur(); as e) {
      <app-alerte type="erreur">{{ e.message }}</app-alerte>
    } @else if (conversations(); as liste) {
      @if (liste.length) {
        <ul class="carte liste">
          @for (c of liste; track c.id) {
            <li>
              <a [routerLink]="['/messages', c.id]" [class.non-lu]="c.nonLus">
                <span class="avatar">
                  @if (photo(c); as url) { <img [src]="url" alt="" /> } @else { {{ initialesDe(c) }} }
                </span>
                <span class="texte">
                  <span class="ligne">
                    <strong>{{ c.interlocuteur.prenom }} {{ c.interlocuteur.nomInitiale }}</strong>
                    <small>{{ c.dateDernierMessage | date: 'd MMM, HH:mm' }}</small>
                  </span>
                  <small class="trajet">{{ c.jeSuisConducteur ? 'Passager' : 'Conducteur' }} ·
                    {{ c.trajet.lieuDepart }} → {{ c.trajet.lieuArrivee }}, {{ c.trajet.dateHeureDepart | date: 'd MMM' }}</small>
                  <span class="ligne">
                    <span class="apercu">{{ c.dernierDeMoi ? 'Vous : ' : '' }}{{ c.dernierMessage }}</span>
                    @if (c.nonLus) { <span class="compte">{{ c.nonLus }}</span> }
                  </span>
                </span>
              </a>
            </li>
          }
        </ul>
      } @else {
        <section class="carte vide">
          <app-icone nom="discussion" [taille]="32" />
          <p><strong>Aucune conversation pour l'instant.</strong><br />
            Pour poser une question à un conducteur, ouvrez son trajet et touchez « Écrire au conducteur ».</p>
          <a class="bouton bouton--secondaire" routerLink="/rechercher">Rechercher un trajet</a>
        </section>
      }
    } @else {
      <p class="aide">Chargement…</p>
    }
  `,
  styles: `
    :host { display: flex; flex-direction: column; gap: 16px; max-width: 760px; }
    .entete h1 { font-size: 24px; }
    .entete p { margin: 6px 0 0; color: var(--texte-2); }
    .liste { margin: 0; padding: 6px; list-style: none; }
    li + li { border-top: 1px solid var(--surface-2); }
    a {
      display: flex; gap: 12px; align-items: center; padding: 12px 10px; border-radius: var(--rayon-petit);
      color: var(--texte); font-weight: 400; text-decoration: none !important;
      &:hover { background: var(--surface-2); }
    }
    .avatar {
      display: grid; place-items: center; flex: none; width: 46px; height: 46px; overflow: hidden;
      border-radius: 50%; background: var(--vert-clair); color: var(--vert); font-weight: 800;
      img { width: 100%; height: 100%; object-fit: cover; }
    }
    .texte { display: flex; flex-direction: column; gap: 2px; flex: 1; min-width: 0; }
    .ligne { display: flex; align-items: center; justify-content: space-between; gap: 8px; }
    small { color: var(--texte-3); }
    .trajet { color: var(--texte-2); }
    .apercu { overflow: hidden; color: var(--texte-2); text-overflow: ellipsis; white-space: nowrap; }
    .non-lu .apercu { color: var(--texte); font-weight: 600; }
    .compte {
      flex: none; min-width: 22px; padding: 1px 7px; border-radius: 999px;
      background: var(--vert); color: #fff; font-size: 12px; font-weight: 800; text-align: center;
    }
    .vide { display: flex; flex-direction: column; align-items: center; gap: 10px; text-align: center; color: var(--texte-2); }
  `,
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class MessagesPage {
  private readonly service = inject(MessagesService);

  protected readonly conversations = signal<ConversationResume[] | null>(null);
  protected readonly erreur = signal<ErreurApi | null>(null);

  constructor() {
    this.service.lister().subscribe({
      next: (l) => this.conversations.set(l),
      error: (e) => this.erreur.set(lireErreur(e)),
    });
  }

  protected photo(c: ConversationResume): string | null {
    return urlFichier(c.interlocuteur.photoProfil);
  }

  protected initialesDe(c: ConversationResume): string {
    return initiales(`${c.interlocuteur.prenom} ${c.interlocuteur.nomInitiale}`);
  }
}
