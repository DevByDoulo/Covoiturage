import {
  ChangeDetectionStrategy,
  Component,
  ElementRef,
  Injector,
  OnInit,
  afterNextRender,
  inject,
  signal,
  viewChild,
} from '@angular/core';
import { takeUntilDestroyed, toSignal } from '@angular/core/rxjs-interop';
import { FormBuilder, ReactiveFormsModule, Validators } from '@angular/forms';
import { Router, RouterLink } from '@angular/router';
import { ErreurApi, lireErreur } from '../../../core/api/erreur-api';
import { Sexe } from '../../../core/auth/auth.models';
import { SessionService } from '../../../core/auth/session.service';
import { Alerte } from '../../../shared/ui/alerte';
import { DrapeauSenegal } from '../../../shared/ui/drapeau-senegal';
import { Icone } from '../../../shared/ui/icone';
import { chiffresTelephone, enErreur, telephoneSenegalValidator } from '../formulaire';
import { prenomDuJeton } from '../google-jeton';

/** Étapes de cet écran (la 1re, Google, est sur /auth/inscription ; la 5e, le code, sur /auth/verification). */
export type EtapeGoogle = 2 | 3 | 4;

/**
 * Suite de l'inscription avec Google, une question par écran comme Uber : numéro de téléphone (obligatoire, vérifié
 * par SMS), sexe, acceptation des conditions ; puis envoi du code et passage à l'écran de vérification.
 * Sert aussi à un compte Google déjà créé mais jamais terminé (connexion Google → TELEPHONE_REQUIS).
 */
@Component({
  selector: 'app-google-telephone',
  imports: [ReactiveFormsModule, RouterLink, Icone, Alerte, DrapeauSenegal],
  templateUrl: './google-telephone.html',
  styleUrls: ['../auth-epure.scss', './google-telephone.scss'],
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class GoogleTelephone implements OnInit {
  private readonly session = inject(SessionService);
  private readonly router = inject(Router);
  private readonly injector = inject(Injector);
  private readonly titre = viewChild<ElementRef<HTMLElement>>('titre');

  protected readonly form = inject(FormBuilder).nonNullable.group({
    telephone: ['', [Validators.required, telephoneSenegalValidator]],
    sexe: inject(FormBuilder).control<Sexe | null>(null, Validators.required),
    cgu: [false, Validators.requiredTrue],
  });
  protected readonly sexe = toSignal(this.form.controls.sexe.valueChanges, { initialValue: null });
  protected readonly etape = signal<EtapeGoogle>(2);
  protected readonly prenom = prenomDuJeton(this.session.idTokenGoogle);
  protected readonly envoi = signal(false);
  protected readonly erreur = signal<ErreurApi | null>(null);
  protected readonly enErreur = (nom: string) => enErreur(this.form, nom);
  /**
   * Refus du numéro par le serveur (déjà utilisé…). Gardé à part : en revenant à l'étape du numéro, le champ est
   * recréé et sa validité recalculée, ce qui effacerait une erreur posée sur le contrôle. Effacé dès que le numéro change.
   */
  protected readonly erreurTelephone = signal<string | null>(null);

  constructor() {
    this.form.controls.telephone.valueChanges.pipe(takeUntilDestroyed()).subscribe(() => this.erreurTelephone.set(null));
  }

  /** Message sous le champ du numéro, ou null. */
  protected messageTelephone(): string | null {
    return this.erreurTelephone() ?? (this.enErreur('telephone') ? 'Numéro sénégalais à 9 chiffres' : null);
  }

  ngOnInit(): void {
    // L'idToken Google n'est gardé qu'en mémoire : après un rechargement, il faut recommencer.
    if (!this.session.idTokenGoogle) this.router.navigateByUrl('/auth/inscription');
  }

  /** Bouton « Continuer » : passe à l'étape suivante si la réponse est valable, ou envoie le code à la dernière. */
  protected continuer(): void {
    const controle = { 2: this.form.controls.telephone, 3: this.form.controls.sexe, 4: this.form.controls.cgu }[this.etape()];
    if (controle.invalid || (this.etape() === 2 && this.erreurTelephone())) {
      controle.markAsTouched();
      return;
    }
    if (this.etape() === 4) this.envoyer();
    else this.allerA((this.etape() + 1) as EtapeGoogle);
  }

  protected precedent(): void {
    if (this.etape() === 2) this.router.navigateByUrl('/auth/inscription');
    else this.allerA((this.etape() - 1) as EtapeGoogle);
  }

  protected choisirSexe(s: Sexe): void {
    this.form.controls.sexe.setValue(s);
  }

  /** Change d'étape et place le focus sur le nouveau titre (annoncé par les lecteurs d'écran). */
  private allerA(etape: EtapeGoogle): void {
    this.erreur.set(null);
    this.etape.set(etape);
    afterNextRender(() => this.titre()?.nativeElement.focus(), { injector: this.injector });
  }

  private envoyer(): void {
    const idToken = this.session.idTokenGoogle;
    if (!idToken) return;
    const { telephone, sexe } = this.form.getRawValue();
    this.envoi.set(true);
    this.erreur.set(null);
    this.session.connexionGoogle(idToken, '+221' + chiffresTelephone(telephone), sexe).subscribe({
      next: (r) =>
        r.etape === 'CONNECTE'
          ? this.router.navigateByUrl(this.session.pageApresConnexion())
          : this.router.navigate(['/auth/verification'], { queryParams: { inscription: 1 } }),
      error: (e) => {
        const err = lireErreur(e);
        this.envoi.set(false);
        // Numéro refusé (déjà utilisé…) : retour à l'étape du numéro, erreur sous le champ.
        const messageNumero = err.champ === 'telephone' ? err.message : err.erreurs?.['telephone'];
        if (messageNumero) {
          this.allerA(2);
          this.erreurTelephone.set(messageNumero);
        } else {
          this.erreur.set(err);
        }
      },
    });
  }
}
