import {
  ChangeDetectionStrategy,
  Component,
  ElementRef,
  Injector,
  OnInit,
  afterNextRender,
  computed,
  inject,
  input,
  signal,
  viewChild,
} from '@angular/core';
import { takeUntilDestroyed, toSignal } from '@angular/core/rxjs-interop';
import { AbstractControl, FormBuilder, ReactiveFormsModule, ValidationErrors, Validators } from '@angular/forms';
import { Router, RouterLink } from '@angular/router';
import { ErreurApi, lireErreur } from '../../../core/api/erreur-api';
import { Sexe } from '../../../core/auth/auth.models';
import { SessionService } from '../../../core/auth/session.service';
import { Alerte } from '../../../shared/ui/alerte';
import { ChampMotDePasse } from '../../../shared/ui/champ-mot-de-passe';
import { DrapeauSenegal } from '../../../shared/ui/drapeau-senegal';
import { Icone } from '../../../shared/ui/icone';
import { ConnexionSociale } from '../connexion-sociale';
import {
  REGLE_MOT_DE_PASSE,
  REGLE_NOM_PROPRE,
  chiffresTelephone,
  enErreur,
  lettresSeulement,
  retourSur,
  telephoneSenegalValidator,
} from '../formulaire';

export type Parcours = 'telephone' | 'email';
export type EtapeInscription = 'identifiants' | 'nom' | 'telephone' | 'sexe' | 'motDePasse' | 'cgu';

/**
 * Étapes de chaque parcours, une question par écran comme Uber. `avant` : étapes faites sur d'autres écrans (numéro
 * et code pour le téléphone), pour afficher « Étape n sur 6 ». Le parcours e-mail se termine par le code (6e étape).
 */
const PARCOURS: Record<Parcours, { etapes: EtapeInscription[]; avant: number; total: number }> = {
  telephone: { etapes: ['nom', 'sexe', 'motDePasse', 'cgu'], avant: 2, total: 6 },
  email: { etapes: ['identifiants', 'nom', 'telephone', 'sexe', 'cgu'], avant: 0, total: 6 },
};

/** Champs vérifiés avant de quitter chaque étape. */
type ChampForm = 'email' | 'motDePasse' | 'confirmation' | 'prenom' | 'nom' | 'telephone' | 'sexe' | 'cgu';
const CHAMPS_DE_L_ETAPE: Record<EtapeInscription, readonly ChampForm[]> = {
  identifiants: ['email', 'motDePasse', 'confirmation'],
  nom: ['prenom', 'nom'],
  telephone: ['telephone'],
  sexe: ['sexe'],
  motDePasse: ['motDePasse', 'confirmation'],
  cgu: ['cgu'],
};

/** Champ du formulaire → étape où il est saisi (pour y revenir quand le serveur le refuse). */
const ETAPE_DU_CHAMP: Record<string, EtapeInscription> = {
  email: 'identifiants',
  prenom: 'nom',
  nom: 'nom',
  telephone: 'telephone',
  sexe: 'sexe',
};

/** Confirmation du mot de passe : identique à la saisie (deux champs vides sont identiques : mot de passe facultatif). */
function memeMotDePasse(c: AbstractControl): ValidationErrors | null {
  return c.value === (c.parent?.get('motDePasse')?.value ?? '') ? null : { differents: true };
}

/**
 * Création du compte en plusieurs étapes, donnée de route `parcours` :
 * - `telephone` (/auth/profil) : numéro déjà vérifié par code ; prénom et nom, sexe, mot de passe facultatif, conditions ;
 *   le compte est créé et connecté.
 * - `email` (/auth/inscription, l'écran d'inscription principal) : e-mail et mot de passe, puis Google / Apple et
 *   « Autres options » (numéro + code SMS, /auth/inscription-telephone) sous la première étape ; prénom et nom, numéro,
 *   sexe, conditions, puis code de vérification.
 */
@Component({
  selector: 'app-inscription',
  imports: [ReactiveFormsModule, RouterLink, Icone, Alerte, DrapeauSenegal, ChampMotDePasse, ConnexionSociale],
  templateUrl: './inscription.html',
  styleUrl: './inscription.scss',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class Inscription implements OnInit {
  private readonly session = inject(SessionService);
  private readonly router = inject(Router);
  private readonly injector = inject(Injector);
  private readonly titre = viewChild<ElementRef<HTMLElement>>('titre');

  /** Donnée de route. */
  readonly parcours = input<Parcours>('telephone');
  /** Paramètre d'URL (lié par le routeur) : page où revenir après la connexion. */
  readonly retour = input<string>();
  protected readonly retourValide = computed(() => retourSur(this.retour()));

  protected readonly form = inject(FormBuilder).nonNullable.group({
    email: ['', [Validators.required, Validators.email]],
    motDePasse: ['', Validators.pattern(REGLE_MOT_DE_PASSE)],
    confirmation: ['', memeMotDePasse],
    prenom: ['', [Validators.required, Validators.maxLength(80), Validators.pattern(REGLE_NOM_PROPRE)]],
    nom: ['', [Validators.required, Validators.maxLength(80), Validators.pattern(REGLE_NOM_PROPRE)]],
    telephone: ['', [Validators.required, telephoneSenegalValidator]],
    sexe: inject(FormBuilder).control<Sexe | null>(null, Validators.required),
    cgu: [false, Validators.requiredTrue],
  });
  protected readonly sexe = toSignal(this.form.controls.sexe.valueChanges, { initialValue: null });
  protected readonly index = signal(0);
  protected readonly config = computed(() => PARCOURS[this.parcours()]);
  protected readonly etape = computed(() => this.config().etapes[this.index()]);
  protected readonly numero = computed(() => this.config().avant + this.index() + 1);
  protected readonly derniere = computed(() => this.index() === this.config().etapes.length - 1);
  protected readonly envoi = signal(false);
  protected readonly erreur = signal<ErreurApi | null>(null);
  /** Refus du serveur par champ, gardés à part (le champ est recréé quand on change d'étape) ; effacés à la saisie. */
  protected readonly erreursServeur = signal<Record<string, string>>({});
  protected readonly enErreur = (nom: string) => enErreur(this.form, nom);

  /** Prénom et nom : retire à la frappe (et au collage) ce qui n'est pas une lettre. */
  protected filtrerNom(champ: 'prenom' | 'nom', evenement: Event): void {
    const saisie = evenement.target as HTMLInputElement;
    const propre = lettresSeulement(saisie.value);
    if (propre === saisie.value) return;
    saisie.value = propre;
    this.form.controls[champ].setValue(propre);
  }

  protected messageNom(): string {
    const lettres = this.form.controls.prenom.hasError('pattern') || this.form.controls.nom.hasError('pattern');
    return lettres
      ? "Lettres uniquement (les espaces, tirets et apostrophes sont admis)"
      : 'Indiquez votre prénom et votre nom';
  }

  constructor() {
    // La confirmation est revérifiée quand le mot de passe change.
    this.form.controls.motDePasse.valueChanges
      .pipe(takeUntilDestroyed())
      .subscribe(() => this.form.controls.confirmation.updateValueAndValidity({ emitEvent: false }));
    for (const nom of ['email', 'telephone', 'prenom', 'nom'] as const) {
      this.form.controls[nom].valueChanges.pipe(takeUntilDestroyed()).subscribe(() => {
        if (this.erreursServeur()[nom]) this.erreursServeur.update(({ [nom]: _, ...reste }) => reste);
      });
    }
  }

  ngOnInit(): void {
    if (this.parcours() === 'email') {
      // Mémorisé pour traverser le code de vérification ; une visite sans retour efface l'ancien.
      this.session.memoriserRetour(this.retour());
      this.form.controls.motDePasse.addValidators(Validators.required);
      this.form.controls.motDePasse.updateValueAndValidity();
    } else if (!this.session.jetonInscription) {
      // Jeton perdu (autre onglet, rechargement après 15 minutes…) : il faut recommencer avec le numéro.
      this.router.navigateByUrl('/auth/inscription-telephone');
    }
  }

  protected erreurServeur(champ: string): string | null {
    return this.erreursServeur()[champ] ?? null;
  }

  protected continuer(): void {
    const champs = CHAMPS_DE_L_ETAPE[this.etape()];
    const controles = champs.map((nom) => this.form.controls[nom]);
    if (controles.some((c) => c.invalid) || champs.some((nom) => this.erreurServeur(nom))) {
      controles.forEach((c) => c.markAsTouched());
      return;
    }
    if (this.derniere()) this.envoyer();
    else this.allerA(this.index() + 1);
  }

  /** Mot de passe facultatif (parcours téléphone) : « Passer » l'ignore. */
  protected passer(): void {
    this.form.controls.motDePasse.setValue('');
    this.form.controls.confirmation.setValue('');
    this.allerA(this.index() + 1);
  }

  protected precedent(): void {
    if (this.index() > 0) this.allerA(this.index() - 1);
    else this.router.navigateByUrl(this.parcours() === 'email' ? '/auth/connexion' : '/auth/inscription-telephone');
  }

  protected choisirSexe(s: Sexe): void {
    this.form.controls.sexe.setValue(s);
  }

  /** Change d'étape et place le focus sur le nouveau titre (annoncé par les lecteurs d'écran). */
  private allerA(index: number): void {
    this.erreur.set(null);
    this.index.set(index);
    afterNextRender(() => this.titre()?.nativeElement.focus(), { injector: this.injector });
  }

  private envoyer(): void {
    const v = this.form.getRawValue();
    this.envoi.set(true);
    this.erreur.set(null);
    if (this.parcours() === 'telephone') {
      this.session
        .terminerInscriptionTelephone({
          prenom: v.prenom.trim(),
          nom: v.nom.trim(),
          sexe: v.sexe,
          ...(v.motDePasse ? { motDePasse: v.motDePasse } : {}),
        })
        .subscribe({
          next: () => this.router.navigateByUrl(this.session.pageApresConnexion()),
          error: (e) => this.echec(lireErreur(e)),
        });
    } else {
      this.session
        .inscription({
          prenom: v.prenom.trim(),
          nom: v.nom.trim(),
          email: v.email.trim(),
          telephone: '+221' + chiffresTelephone(v.telephone),
          motDePasse: v.motDePasse,
          sexe: v.sexe,
        })
        .subscribe({
          next: () => this.router.navigate(['/auth/verification'], { queryParams: { inscription: 6 } }),
          error: (e) => this.echec(lireErreur(e)),
        });
    }
  }

  /** Champ refusé (email ou numéro déjà utilisé…) : retour à son étape, message sous le champ. */
  private echec(err: ErreurApi): void {
    this.envoi.set(false);
    const parChamp: Record<string, string> = { ...(err.erreurs ?? {}), ...(err.champ ? { [err.champ]: err.message } : {}) };
    const champ = Object.keys(parChamp).find((c) => ETAPE_DU_CHAMP[c]);
    const etape = champ ? ETAPE_DU_CHAMP[champ] : undefined;
    const index = etape ? this.config().etapes.indexOf(etape) : -1;
    if (champ && index >= 0) {
      this.allerA(index);
      this.erreursServeur.set(parChamp);
    } else {
      this.erreur.set(err);
    }
  }
}
