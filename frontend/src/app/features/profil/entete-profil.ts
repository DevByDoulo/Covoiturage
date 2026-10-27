import { DatePipe, DecimalPipe } from '@angular/common';
import { ChangeDetectionStrategy, Component, computed, inject, input, signal } from '@angular/core';
import { ErreurApi, lireErreur } from '../../core/api/erreur-api';
import { Profil } from '../../core/auth/auth.models';
import { Alerte } from '../../shared/ui/alerte';
import { Icone } from '../../shared/ui/icone';
import { ProfilService, initiales, urlFichier } from './profil.service';

const TAILLE_MAX = 5 * 1024 * 1024;

/** Haut de « Mon profil » : photo (modifiable), nom, statut conducteur, note et ancienneté. */
@Component({
  selector: 'app-entete-profil',
  imports: [Icone, Alerte, DatePipe, DecimalPipe],
  template: `
    <section class="carte entete">
      <div class="avatar">
        @if (photo(); as url) {
          <img [src]="url" [alt]="'Photo de ' + profil().prenom" />
        } @else {
          <span class="avatar__initiales" aria-hidden="true">{{ initiales() }}</span>
        }
        <label class="avatar__bouton" [class.avatar__bouton--envoi]="envoi()" title="Changer la photo">
          <input class="sr-only" type="file" accept="image/jpeg,image/png,image/webp" (change)="choisir($event)" [disabled]="envoi()" />
          @if (envoi()) {
            <span class="chargement" aria-hidden="true"></span>
          } @else {
            <app-icone nom="camera" [taille]="17" />
          }
          <span class="sr-only">Changer la photo de profil</span>
        </label>
      </div>

      <h1>{{ profil().prenom }} {{ profil().nom }}</h1>

      @switch (statut()) {
        @case ('verifie') {
          <span class="pastille pastille--succes"><app-icone nom="valide" [taille]="14" /> Conducteur vérifié</span>
        }
        @case ('attente') {
          <span class="pastille pastille--attente"><app-icone nom="horloge" [taille]="14" /> Validation des documents en cours</span>
        }
        @case ('admin') {
          <span class="pastille pastille--succes"><app-icone nom="bouclier" [taille]="14" /> Administrateur</span>
        }
      }

      <p class="note">
        @if (profil().noteMoyenne; as note) {
          <app-icone nom="etoile" [taille]="18" /> <strong>{{ note | number: '1.1-1' : 'fr' }}</strong>
        } @else {
          Nouveau membre
        }
        <span aria-hidden="true">•</span> Membre depuis {{ profil().dateCreation | date: 'MMMM yyyy' }}
      </p>

      @if (erreur(); as e) {
        <app-alerte type="erreur">{{ e.message }}</app-alerte>
      }
    </section>
  `,
  styles: `
    .entete {
      display: flex;
      flex-direction: column;
      align-items: center;
      gap: 10px;
      text-align: center;
      background: linear-gradient(180deg, var(--vert-clair) 0, var(--surface) 110px);
    }
    .avatar {
      position: relative;
      width: 104px;
      height: 104px;
      img,
      .avatar__initiales {
        width: 100%;
        height: 100%;
        border-radius: 50%;
        border: 4px solid var(--surface);
        box-shadow: var(--ombre);
      }
      img {
        object-fit: cover;
      }
    }
    .avatar__initiales {
      display: grid;
      place-items: center;
      background: var(--menthe);
      font-size: 34px;
      font-weight: 800;
      color: var(--vert-fonce);
    }
    .avatar__bouton {
      position: absolute;
      right: -2px;
      bottom: 2px;
      display: grid;
      place-items: center;
      width: 36px;
      height: 36px;
      border: 3px solid var(--surface);
      border-radius: 50%;
      background: var(--vert);
      color: #fff;
      cursor: pointer;
      &:focus-within {
        outline: 3px solid rgba(12, 107, 63, 0.35);
      }
    }
    .avatar__bouton--envoi {
      cursor: progress;
    }
    h1 {
      font-size: 24px;
    }
    .note {
      display: flex;
      align-items: center;
      gap: 6px;
      margin: 0;
      color: var(--texte-2);
      app-icone {
        color: var(--orange);
      }
    }
  `,
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class EnteteProfil {
  private readonly profils = inject(ProfilService);

  readonly profil = input.required<Profil>();

  protected readonly envoi = signal(false);
  protected readonly erreur = signal<ErreurApi | null>(null);
  protected readonly photo = computed(() => urlFichier(this.profil().photoProfil));
  protected readonly initiales = computed(() => initiales(`${this.profil().prenom} ${this.profil().nom}`));
  protected readonly statut = computed(() => {
    const p = this.profil();
    if (p.role === 'ADMIN') return 'admin';
    if (p.conducteurValide) return 'verifie';
    return p.role === 'CONDUCTEUR' ? 'attente' : null;
  });

  protected choisir(evenement: Event): void {
    const champ = evenement.target as HTMLInputElement;
    const fichier = champ.files?.[0];
    champ.value = '';
    if (!fichier) return;
    if (fichier.size > TAILLE_MAX) {
      this.erreur.set({ status: 400, message: 'La photo dépasse 5 Mo. Choisissez une image plus légère.' });
      return;
    }
    this.envoi.set(true);
    this.erreur.set(null);
    this.profils.changerPhoto(fichier).subscribe({
      next: () => this.envoi.set(false),
      error: (e) => {
        this.erreur.set(lireErreur(e));
        this.envoi.set(false);
      },
    });
  }
}
