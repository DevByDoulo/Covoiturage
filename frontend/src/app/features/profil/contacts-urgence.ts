import { ChangeDetectionStrategy, Component, inject, signal } from '@angular/core';
import { FormBuilder, ReactiveFormsModule, Validators } from '@angular/forms';
import { ErreurApi, lireErreur } from '../../core/api/erreur-api';
import { Alerte } from '../../shared/ui/alerte';
import { Icone } from '../../shared/ui/icone';
import { ContactUrgence, ProfilService, formaterTelephone, initiales } from './profil.service';

const MAX_CONTACTS = 3;

/** Contacts d'urgence (3 au plus) : liste, appel direct, ajout et suppression. */
@Component({
  selector: 'app-contacts-urgence',
  imports: [ReactiveFormsModule, Icone, Alerte],
  template: `
    <section class="carte bloc">
      <h2><app-icone nom="bouclier" /> Contacts d'urgence</h2>
      <p class="bloc__sous-titre">Prévenus automatiquement si vous déclenchez une alerte pendant un trajet.</p>

      @for (c of contacts(); track c.id) {
        <div class="contact">
          <span class="contact__initiales" aria-hidden="true">{{ initiales(c.nom) }}</span>
          <div class="contact__texte">
            <strong>{{ c.nom }}</strong>
            @if (c.lien) {
              <span class="pastille pastille--attente">{{ c.lien }}</span>
            }
            <small>{{ formater(c.telephone) }}</small>
          </div>
          <a class="bouton-rond" [href]="'tel:' + c.telephone" [attr.aria-label]="'Appeler ' + c.nom">
            <app-icone nom="telephone" [taille]="17" />
          </a>
          <button class="bouton-rond" type="button" (click)="supprimer(c)" [attr.aria-label]="'Retirer ' + c.nom">
            <app-icone nom="poubelle" [taille]="17" />
          </button>
        </div>
      } @empty {
        @if (charge()) {
          <p class="vide">Aucun contact pour l'instant.</p>
        }
      }

      @if (ajout()) {
        <form class="formulaire ajout" [formGroup]="form" (ngSubmit)="ajouter()" novalidate>
          <div class="champ" [class.champ--erreur]="form.controls.nom.invalid && form.controls.nom.touched">
            <label class="libelle" for="contact-nom">Nom</label>
            <div class="saisie"><input id="contact-nom" formControlName="nom" placeholder="Ousmane Diop" /></div>
          </div>
          <div class="champ" [class.champ--erreur]="erreur()?.champ === 'telephone'">
            <label class="libelle" for="contact-tel">Téléphone</label>
            <div class="saisie">
              <span class="indicatif">+221</span>
              <input id="contact-tel" formControlName="telephone" inputmode="tel" placeholder="77 123 45 67" />
            </div>
          </div>
          <div class="champ">
            <label class="libelle" for="contact-lien">Lien (facultatif)</label>
            <div class="saisie">
              <input id="contact-lien" formControlName="lien" list="liens" placeholder="Frère, mère, amie…" />
              <datalist id="liens">
                @for (l of liens; track l) {
                  <option [value]="l"></option>
                }
              </datalist>
            </div>
          </div>
          @if (erreur(); as e) {
            <app-alerte type="erreur">{{ e.message }}</app-alerte>
          }
          <div class="actions">
            <button class="bouton bouton--secondaire" type="button" (click)="ajout.set(false)">Annuler</button>
            <button class="bouton bouton--primaire" type="submit" [disabled]="envoi()">Ajouter</button>
          </div>
        </form>
      } @else {
        @if (erreur(); as e) {
          <app-alerte type="erreur">{{ e.message }}</app-alerte>
        }
        @if (contacts().length < max) {
          <button class="bouton bouton--secondaire" type="button" (click)="ouvrir()">
            <app-icone nom="plus" [taille]="18" /> Ajouter un contact
          </button>
        }
      }
    </section>
  `,
  styles: `
    .contact {
      display: flex;
      align-items: center;
      gap: 10px;
      padding: 12px 14px;
      border-radius: var(--rayon);
      background: var(--surface-2);
    }
    .contact__initiales {
      display: grid;
      place-items: center;
      flex: none;
      width: 42px;
      height: 42px;
      border-radius: 50%;
      background: var(--surface);
      font-weight: 700;
      color: var(--texte-2);
    }
    .contact__texte {
      display: flex;
      flex: 1;
      flex-wrap: wrap;
      align-items: center;
      gap: 2px 8px;
      min-width: 0;
      small {
        flex-basis: 100%;
        color: var(--texte-3);
      }
    }
    .vide {
      margin: 0;
      color: var(--texte-3);
    }
    .ajout {
      padding: 14px;
      border-radius: var(--rayon);
      background: var(--surface-2);
    }
    .actions {
      display: grid;
      grid-template-columns: 1fr 1fr;
      gap: 10px;
    }
  `,
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class ContactsUrgence {
  private readonly profils = inject(ProfilService);
  private readonly fb = inject(FormBuilder);

  protected readonly max = MAX_CONTACTS;
  protected readonly liens = ['Père', 'Mère', 'Frère', 'Sœur', 'Conjoint(e)', 'Ami(e)', 'Collègue'];
  protected readonly contacts = signal<ContactUrgence[]>([]);
  protected readonly charge = signal(false);
  protected readonly ajout = signal(false);
  protected readonly envoi = signal(false);
  protected readonly erreur = signal<ErreurApi | null>(null);
  protected readonly form = this.fb.nonNullable.group({
    nom: ['', [Validators.required, Validators.maxLength(120)]],
    telephone: ['', Validators.required],
    lien: ['', Validators.maxLength(40)],
  });
  protected readonly initiales = initiales;
  protected readonly formater = formaterTelephone;

  constructor() {
    this.profils.contactsUrgence().subscribe({
      next: (c) => {
        this.contacts.set(c);
        this.charge.set(true);
      },
      error: (e) => this.erreur.set(lireErreur(e)),
    });
  }

  protected ouvrir(): void {
    this.form.reset();
    this.erreur.set(null);
    this.ajout.set(true);
  }

  protected ajouter(): void {
    if (this.form.invalid) {
      this.form.markAllAsTouched();
      return;
    }
    const { nom, telephone, lien } = this.form.getRawValue();
    this.envoi.set(true);
    this.erreur.set(null);
    this.profils.ajouterContactUrgence({ nom, telephone, lien: lien || null }).subscribe({
      next: (c) => {
        this.contacts.update((liste) => [...liste, c]);
        this.envoi.set(false);
        this.ajout.set(false);
      },
      error: (e) => {
        this.erreur.set(lireErreur(e));
        this.envoi.set(false);
      },
    });
  }

  protected supprimer(c: ContactUrgence): void {
    if (!confirm(`Retirer ${c.nom} de vos contacts d'urgence ?`)) return;
    this.erreur.set(null);
    this.profils.supprimerContactUrgence(c.id).subscribe({
      next: () => this.contacts.update((liste) => liste.filter((x) => x.id !== c.id)),
      error: (e) => this.erreur.set(lireErreur(e)),
    });
  }
}
