import { ChangeDetectionStrategy, Component, computed, inject, signal, viewChild } from '@angular/core';
import { toSignal } from '@angular/core/rxjs-interop';
import { FormBuilder, ReactiveFormsModule, Validators } from '@angular/forms';
import { Router } from '@angular/router';
import { ErreurApi, lireErreur } from '../../../core/api/erreur-api';
import { CanalOtp } from '../../../core/auth/auth.models';
import { SessionService } from '../../../core/auth/session.service';
import { Alerte } from '../../../shared/ui/alerte';
import { ChampMotDePasse } from '../../../shared/ui/champ-mot-de-passe';
import { compteARebours } from '../../../shared/ui/compte-a-rebours';
import { EntetePage } from '../../../shared/ui/entete-page';
import { ForceMotDePasse } from '../../../shared/ui/force-mot-de-passe';
import { Icone } from '../../../shared/ui/icone';
import { SaisieCode } from '../../../shared/ui/saisie-code';
import { REGLE_MOT_DE_PASSE, champsIdentiques, enErreur } from '../formulaire';

type Etape = 1 | 2 | 3;

/**
 * Trois étapes successives, une seule visible à la fois : 1) téléphone ou email où envoyer le code ;
 * 2) code reçu, vérifié par le serveur ; 3) nouveau mot de passe (autorisé par le jeton remis à l'étape 2).
 */
@Component({
  selector: 'app-mot-de-passe-oublie',
  imports: [ReactiveFormsModule, EntetePage, Icone, Alerte, ChampMotDePasse, SaisieCode, ForceMotDePasse],
  templateUrl: './mot-de-passe-oublie.html',
  styleUrls: ['../auth-commun.scss', './mot-de-passe-oublie.scss'],
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class MotDePasseOublie {
  private readonly session = inject(SessionService);
  private readonly router = inject(Router);
  private readonly fb = inject(FormBuilder);

  protected readonly contact = this.fb.nonNullable.control('', Validators.required);
  protected readonly code = this.fb.nonNullable.control('', Validators.pattern(/^\d{6}$/));
  protected readonly form = this.fb.nonNullable.group(
    {
      motDePasse: ['', [Validators.required, Validators.pattern(REGLE_MOT_DE_PASSE)]],
      confirmation: ['', Validators.required],
    },
    { validators: champsIdentiques('motDePasse', 'confirmation') },
  );

  protected readonly etape = signal<Etape>(1);
  /** Identifiant pour lequel le code a été demandé, puis jeton remis une fois le code accepté. */
  protected readonly identifiantEnvoye = signal<string | null>(null);
  private readonly jeton = signal<string | null>(null);
  /** Adresse ou numéro masqué renvoyé par le serveur, et canal utilisé (email ou SMS). */
  protected readonly destination = signal<string | null>(null);
  protected readonly canal = signal<CanalOtp | null>(null);
  private readonly renvoiPossibleA = signal<number | null>(null);
  protected readonly attenteRenvoi = compteARebours(this.renvoiPossibleA);

  protected readonly envoiCode = signal(false);
  protected readonly verificationCode = signal(false);
  protected readonly envoiReinit = signal(false);
  protected readonly codeRenvoye = signal(false);
  protected readonly erreurEnvoi = signal<ErreurApi | null>(null);
  protected readonly erreurCode = signal<ErreurApi | null>(null);
  protected readonly erreurReinit = signal<ErreurApi | null>(null);
  protected readonly plusDEssai = computed(() => this.erreurCode()?.tentativesRestantes === 0);

  private readonly valeurContact = toSignal(this.contact.valueChanges, { initialValue: '' });
  /** Affiche l'indicatif +221 tant que la saisie ressemble à un numéro. */
  protected readonly ressembleATelephone = computed(() => !/[a-z@]/i.test(this.valeurContact()));
  private readonly valeurCode = toSignal(this.code.valueChanges, { initialValue: '' });
  protected readonly codeComplet = computed(() => this.valeurCode().length === 6);
  protected readonly motDePasse = toSignal(this.form.controls.motDePasse.valueChanges, { initialValue: '' });
  protected readonly enErreur = (nom: string) => enErreur(this.form, nom);

  private readonly saisieCode = viewChild(SaisieCode);

  /** Étape 1 (ou « Renvoyer » à l'étape 2) : envoie le code, puis affiche l'étape 2. */
  protected envoyerCode(): void {
    if (this.contact.invalid) {
      this.contact.markAsTouched();
      return;
    }
    const identifiant = this.contact.value.trim();
    const renvoi = this.etape() === 2;
    this.envoiCode.set(true);
    this.erreurEnvoi.set(null);
    this.erreurCode.set(null);
    this.codeRenvoye.set(false);
    this.session.motDePasseOublie(identifiant).subscribe({
      next: (r) => {
        this.destination.set(r.emailMasque ?? r.telephoneMasque ?? null);
        this.canal.set(r.canal ?? null);
        this.renvoiPossibleA.set(Date.now() + (r.renvoiPossibleDansSecondes ?? 60) * 1000);
        this.codeRenvoye.set(renvoi);
        this.allerAuCode(identifiant);
      },
      error: (e) => {
        const err = lireErreur(e);
        // Délai de renvoi non écoulé : le code déjà envoyé reste valable, on passe quand même à l'étape 2.
        // Les autres refus (trop de codes demandés, trop de demandes depuis cette connexion) restent à l'étape 1.
        if (err.motif === 'DELAI_RENVOI' && err.reessayerDansSecondes) {
          this.renvoiPossibleA.set(Date.now() + err.reessayerDansSecondes * 1000);
          this.allerAuCode(identifiant);
        }
        this.erreurEnvoi.set(err);
        this.envoiCode.set(false);
      },
    });
  }

  /** Étape 2 : le serveur vérifie le code (5 essais) ; s'il est bon, on passe au nouveau mot de passe. */
  protected verifierCode(): void {
    const identifiant = this.identifiantEnvoye();
    if (!identifiant || !this.codeComplet() || this.verificationCode()) return;
    this.verificationCode.set(true);
    this.erreurCode.set(null);
    this.erreurEnvoi.set(null);
    this.codeRenvoye.set(false);
    this.session.verifierCodeReinitialisation(identifiant, this.code.value).subscribe({
      next: (r) => {
        this.jeton.set(r.jeton);
        this.verificationCode.set(false);
        this.etape.set(3);
        setTimeout(() => document.getElementById('nouveau')?.focus());
      },
      error: (e) => {
        this.erreurCode.set(lireErreur(e));
        this.verificationCode.set(false);
        this.code.setValue('');
        this.saisieCode()?.focus();
      },
    });
  }

  /** Retour à l'étape 1 pour corriger le téléphone ou l'email, ou recommencer (la saisie est conservée). */
  protected recommencer(): void {
    this.etape.set(1);
    this.identifiantEnvoye.set(null);
    this.jeton.set(null);
    this.destination.set(null);
    this.canal.set(null);
    this.codeRenvoye.set(false);
    this.erreurEnvoi.set(null);
    this.erreurCode.set(null);
    this.erreurReinit.set(null);
    this.code.reset();
    this.form.reset();
  }

  protected confirmationDifferente(): boolean {
    const c = this.form.controls.confirmation;
    return this.form.hasError('differents') && (c.touched || c.dirty);
  }

  /** Étape 3 : enregistre le nouveau mot de passe. */
  protected reinitialiser(): void {
    const jeton = this.jeton();
    if (!jeton) return;
    if (this.form.invalid) {
      this.form.markAllAsTouched();
      return;
    }
    this.envoiReinit.set(true);
    this.erreurReinit.set(null);
    this.session.reinitialiserMotDePasse(jeton, this.form.controls.motDePasse.value).subscribe({
      next: () => this.router.navigate(['/auth/connexion'], { queryParams: { reinitialise: 1 } }),
      error: (e) => {
        this.erreurReinit.set(lireErreur(e));
        this.envoiReinit.set(false);
      },
    });
  }

  private allerAuCode(identifiant: string): void {
    this.identifiantEnvoye.set(identifiant);
    this.envoiCode.set(false);
    this.etape.set(2);
    // Le champ du code n'existe qu'une fois l'étape 2 affichée.
    setTimeout(() => this.saisieCode()?.focus());
  }
}
