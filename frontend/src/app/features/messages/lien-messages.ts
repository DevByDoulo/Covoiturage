import { ChangeDetectionStrategy, Component, inject } from '@angular/core';
import { RouterLink } from '@angular/router';
import { Icone } from '../../shared/ui/icone';
import { MessagesService } from './messages.service';

/** Bouton « Messages » de l'en-tête, à côté de la cloche, avec le nombre de messages non lus. */
@Component({
  selector: 'app-lien-messages',
  imports: [RouterLink, Icone],
  template: `
    <a class="lien" routerLink="/messages"
      [attr.aria-label]="messages.nonLus() ? messages.nonLus() + ' message(s) non lu(s)' : 'Messages'">
      <app-icone nom="discussion" [taille]="20" />
      @if (messages.nonLus(); as n) {
        <span class="lien__pastille">{{ n > 99 ? '99+' : n }}</span>
      }
    </a>
  `,
  styles: `
    .lien {
      position: relative;
      display: grid;
      place-items: center;
      width: 42px;
      height: 42px;
      border-radius: 50%;
      background: var(--surface-2);
      color: var(--texte);
      text-decoration: none !important;
      &:hover {
        background: var(--vert-clair);
        color: var(--vert);
      }
    }
    .lien__pastille {
      position: absolute;
      top: -3px;
      right: -4px;
      min-width: 20px;
      padding: 1px 6px;
      border: 2px solid var(--surface);
      border-radius: 999px;
      background: var(--vert);
      font-size: 11px;
      font-weight: 800;
      text-align: center;
      color: #fff;
    }
  `,
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class LienMessages {
  protected readonly messages = inject(MessagesService);
}
