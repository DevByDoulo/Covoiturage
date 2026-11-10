import { ChangeDetectionStrategy, Component, computed, inject, input, signal } from '@angular/core';
import { toSignal } from '@angular/core/rxjs-interop';
import { FormControl, FormGroup, ReactiveFormsModule, Validators } from '@angular/forms';
import { RouterLink } from '@angular/router';
import { ErreurApi, lireErreur } from '../../core/api/erreur-api';
import { Alerte } from '../../shared/ui/alerte';
import { LIBELLES_MOTIF, MOTIFS, MotifSignalement, descriptionObligatoire } from './signalements.models';
import { SignalementsService } from './signalements.service';

/**
 * 10 — Formulaire « Signaler » : motif et description, pour une personne rencontrée lors d'un trajet.
 * Paramètres : /signaler/:idUtilisateur?trajet=<id>&nom=<prénom>.
 */
@Component({
  selector: 'app-signaler',
  imports: [ReactiveFormsModule, RouterLink, Alerte],
  template: `
    <div class="page">
      <h1>Signaler {{ nom() || 'cette personne' }}</h1>
      @if (envoye()) {
        <app-alerte type="succes" titre="Signalement envoyé">
          Merci. L'équipe YOBALEMAsn va l'examiner et vous informera de la suite. La personne signalée ne verra pas votre identité.
        </app-alerte>
        <a class="bouton bouton--primaire" routerLink="/signalements">Voir mes signalements</a>
      } @else {
        <p class="intro">
          Un signalement est examiné par l'équipe. Il ne concerne que les personnes avec qui vous avez partagé un trajet.
        </p>
        <form class="carte bloc" [formGroup]="form" (ngSubmit)="envoyer()">
          <div class="champ">
            <label class="libelle" for="motif">Motif</label>
            <div class="saisie">
              <select id="motif" formControlName="motif">
                @for (m of motifs; track m) {
                  <option [value]="m">{{ libelles[m] }}</option>
                }
              </select>
            </div>
          </div>
          <div class="champ" [class.champ--erreur]="erreur()?.champ === 'description'">
            <label class="libelle" for="description">
              Description @if (obligatoire()) { <span class="obligatoire">(obligatoire)</span> } @else { (facultatif) }
            </label>
            <div class="saisie saisie--texte">
              <textarea id="description" formControlName="description" rows="5" maxlength="500"
                placeholder="Que s'est-il passé ?"></textarea>
            </div>
            <p class="aide">{{ form.controls.description.value.length }} / 500 caractères</p>
          </div>
          @if (erreur(); as e) {
            <app-alerte type="erreur">{{ e.message }}</app-alerte>
          }
          <button class="bouton bouton--primaire" type="submit" [disabled]="envoi() || form.invalid">Envoyer le signalement</button>
        </form>
      }
    </div>
  `,
  styles: `
    .page {
      display: grid;
      gap: 16px;
      max-width: 640px;
      margin: 0 auto;
      padding: 16px;
    }
    .intro {
      margin: 0;
      color: var(--texte-2);
    }
    form {
      display: grid;
      gap: 14px;
    }
  `,
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class Signaler {
  private readonly service = inject(SignalementsService);

  /** Paramètres de route et de requête (liés par withComponentInputBinding). */
  readonly idUtilisateur = input.required<string>();
  readonly trajet = input<string>();
  readonly nom = input<string>();

  protected readonly motifs = MOTIFS;
  protected readonly libelles = LIBELLES_MOTIF;
  protected readonly form = new FormGroup({
    motif: new FormControl<MotifSignalement>('COMPORTEMENT', { nonNullable: true, validators: Validators.required }),
    description: new FormControl('', { nonNullable: true, validators: Validators.maxLength(500) }),
  });
  private readonly motifChoisi = toSignal(this.form.controls.motif.valueChanges, {
    initialValue: this.form.controls.motif.value,
  });
  protected readonly obligatoire = computed(() => descriptionObligatoire(this.motifChoisi()));
  protected readonly envoi = signal(false);
  protected readonly envoye = signal(false);
  protected readonly erreur = signal<ErreurApi | null>(null);

  protected envoyer(): void {
    const { motif, description } = this.form.getRawValue();
    const texte = description.trim();
    if (descriptionObligatoire(motif) && !texte) {
      this.erreur.set({ status: 400, message: 'Décrivez la situation.', champ: 'description' });
      return;
    }
    this.envoi.set(true);
    this.erreur.set(null);
    this.service
      .signaler({
        idUtilisateur: Number(this.idUtilisateur()),
        idTrajet: this.trajet() ? Number(this.trajet()) : null,
        motif,
        description: texte || null,
      })
      .subscribe({
        next: () => {
          this.envoi.set(false);
          this.envoye.set(true);
        },
        error: (e) => {
          this.envoi.set(false);
          this.erreur.set(lireErreur(e));
        },
      });
  }
}
