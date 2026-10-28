import { ChangeDetectionStrategy, Component, inject } from '@angular/core';
import { RouterLink } from '@angular/router';
import { Icone } from '../../shared/ui/icone';
import { NotificationsService } from './notifications.service';

/** Cloche de l'en-tête : ouvre la liste des notifications, avec le nombre de non lues en pastille. */
@Component({
  selector: 'app-cloche',
  imports: [RouterLink, Icone],
  template: `
    <a class="cloche" routerLink="/notifications"
      [attr.aria-label]="notifications.nonLues() ? notifications.nonLues() + ' notification(s) non lue(s)' : 'Notifications'">
      <app-icone nom="cloche" [taille]="21" />
      @if (notifications.nonLues(); as n) {
        <span class="cloche__pastille">{{ n > 99 ? '99+' : n }}</span>
      }
    </a>
  `,
  styles: `
    .cloche {
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
    .cloche__pastille {
      position: absolute;
      top: -3px;
      right: -4px;
      min-width: 20px;
      padding: 1px 6px;
      border: 2px solid var(--surface);
      border-radius: 999px;
      background: var(--erreur);
      font-size: 11px;
      font-weight: 800;
      text-align: center;
      color: #fff;
    }
  `,
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class Cloche {
  protected readonly notifications = inject(NotificationsService);
}
