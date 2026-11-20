import { ChangeDetectionStrategy, Component, OnInit, computed, inject, input, signal } from '@angular/core';
import { takeUntilDestroyed } from '@angular/core/rxjs-interop';
import { FormBuilder, ReactiveFormsModule, Validators } from '@angular/forms';
import { Router, RouterLink } from '@angular/router';
import { Observable } from 'rxjs';
import { environment } from '../../../../environments/environment';
import { ErreurApi, lireErreur } from '../../../core/api/erreur-api';
import { AuthReponse } from '../../../core/auth/auth.models';
import { SessionService } from '../../../core/auth/session.service';
import { Alerte } from '../../../shared/ui/alerte';
import { BoutonApple, ReponseApple } from '../../../shared/ui/bouton-apple';
import { BoutonGoogle } from '../../../shared/ui/bouton-google';
import { DrapeauSenegal } from '../../../shared/ui/drapeau-senegal';
import { Icone } from '../../../shared/ui/icone';
import { chiffresTelephone, enErreur, retourSur, telephoneSenegalValidator } from '../formulaire';

/** « Se connecter avec Apple » n'apparaît que si le Services ID Apple est renseigné (`environment.apple`). */
export function appleConfigure(): boolean {
  return !!environment.apple.clientId && !!environment.apple.redirectUri;
}

/**
 * Écran du numéro, « Autres options » de la connexion (/auth/connexion-telephone) comme de l'inscription
 * (/auth/inscription-telephone) : numéro de téléphone (+221) et « Continuer », puis « ou », Google (et Apple s'il est
 * configuré), puis retour à l'e-mail et au mot de passe (/auth/connexion ou /auth/inscription). Aucune méthode n'est imposée.
 * Numéro : code par SMS, puis connexion du compte existant ou, pour un nouveau numéro, quelques informations.
 */
@Component({
  selector: 'app-entree',
  imports: [ReactiveFormsModule, RouterLink, Icone, Alerte, BoutonGoogle, BoutonApple, DrapeauSenegal],
  templateUrl: './entree.html',
  styleUrl: './entree.scss',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class Entree implements OnInit {
  private readonly session = inject(SessionService);
  private readonly router = inject(Router);

  /** Paramètres d'URL (liés par le routeur). */
  readonly retour = input<string>();
  readonly expiree = input<string>();
  readonly desactive = input<string>();
  readonly suppression = input<string>();
  /** Donnée de route : arrivée par « S'inscrire » (titre adapté, même parcours). */
  readonly inscription = input<boolean>();

  protected readonly form = inject(FormBuilder).nonNullable.group({
    telephone: ['', [Validators.required, telephoneSenegalValidator]],
    /** Décochée : la session se termine à la fermeture de l'onglet. */
    resterConnecte: [false],
  });
  protected readonly envoi = signal(false);
  protected readonly erreur = signal<ErreurApi | null>(null);
  protected readonly erreurTelephone = signal<string | null>(null);
  protected readonly googleIndisponible = signal(false);
  protected readonly apple = appleConfigure();
  protected readonly messageApple = signal<string | null>(null);
  protected readonly messagesApple = {
    indisponible: "La connexion Apple n'est pas disponible pour le moment.",
    echec: 'La connexion avec Apple a échoué. Réessayez.',
  };
  protected readonly retourValide = computed(() => retourSur(this.retour()));

  constructor() {
    this.form.controls.telephone.valueChanges.pipe(takeUntilDestroyed()).subscribe(() => this.erreurTelephone.set(null));
  }

  ngOnInit(): void {
    // Mémorisé pour traverser le code de vérification ; une visite sans retour efface l'ancien.
    this.session.memoriserRetour(this.retour());
  }

  /** Message sous le champ du numéro, ou null. */
  protected messageTelephone(): string | null {
    if (this.erreurTelephone()) return this.erreurTelephone();
    if (!enErreur(this.form, 'telephone')) return null;
    return this.form.controls.telephone.hasError('required') ? 'Saisissez votre numéro' : 'Numéro sénégalais à 9 chiffres';
  }

  protected continuer(): void {
    const champ = this.form.controls.telephone;
    if (champ.invalid) {
      champ.markAsTouched();
      return;
    }
    this.envoi.set(true);
    this.erreur.set(null);
    const telephone = '+221' + chiffresTelephone(champ.value);
    this.session.codeTelephone(telephone, this.form.controls.resterConnecte.value).subscribe({
      next: () => this.router.navigateByUrl('/auth/verification'),
      error: (e) => {
        const err = lireErreur(e);
        this.envoi.set(false);
        const messageNumero = err.champ === 'telephone' ? err.message : err.erreurs?.['telephone'];
        if (messageNumero) this.erreurTelephone.set(messageNumero);
        else this.erreur.set(err);
      },
    });
  }

  protected google(idToken: string): void {
    this.suivre(this.session.connexionGoogle(idToken, undefined, undefined, this.form.controls.resterConnecte.value));
  }

  protected connexionApple(r: ReponseApple): void {
    this.suivre(this.session.connexionApple(r, undefined, undefined, this.form.controls.resterConnecte.value));
  }

  private suivre(appel: Observable<AuthReponse>): void {
    this.envoi.set(true);
    this.erreur.set(null);
    appel.subscribe({
      next: (r) => {
        if (r.etape === 'TELEPHONE_REQUIS') this.router.navigateByUrl('/auth/telephone');
        else if (r.etape === 'OTP_ENVOYE') this.router.navigate(['/auth/verification'], { queryParams: { inscription: 5 } });
        else this.router.navigateByUrl(this.session.pageApresConnexion());
      },
      error: (e) => {
        this.erreur.set(lireErreur(e));
        this.envoi.set(false);
      },
    });
  }
}
