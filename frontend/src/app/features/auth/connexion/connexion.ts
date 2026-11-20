import { ChangeDetectionStrategy, Component, OnInit, computed, inject, input, signal } from '@angular/core';
import { FormBuilder, ReactiveFormsModule, Validators } from '@angular/forms';
import { Router, RouterLink } from '@angular/router';
import { Observable } from 'rxjs';
import { ErreurApi, lireErreur } from '../../../core/api/erreur-api';
import { AuthReponse } from '../../../core/auth/auth.models';
import { SessionService } from '../../../core/auth/session.service';
import { Alerte } from '../../../shared/ui/alerte';
import { BoutonApple, ReponseApple } from '../../../shared/ui/bouton-apple';
import { BoutonGoogle } from '../../../shared/ui/bouton-google';
import { ChampMotDePasse } from '../../../shared/ui/champ-mot-de-passe';
import { Icone } from '../../../shared/ui/icone';
import { appleConfigure } from '../entree/entree';
import { enErreur, retourSur } from '../formulaire';

/**
 * Connexion par e-mail (ou numéro) et mot de passe, sur deux adresses :
 * - /auth/connexion (donnée de route `principal`) : écran de connexion. Le formulaire vient en premier, puis
 *   « ou continuer avec » Google (et Apple s'il est configuré), puis « Autres options » : numéro + code SMS
 *   (/auth/connexion-telephone), et le lien vers l'inscription.
 * - /auth/autres-options (ancienne adresse, plus liée depuis l'inscription) : même formulaire avec « Retour » et la
 *   création d'un compte avec une adresse e-mail.
 */
@Component({
  selector: 'app-connexion',
  imports: [ReactiveFormsModule, RouterLink, Icone, Alerte, ChampMotDePasse, BoutonGoogle, BoutonApple],
  templateUrl: './connexion.html',
  styleUrl: './connexion.scss',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class Connexion implements OnInit {
  private readonly session = inject(SessionService);
  private readonly router = inject(Router);

  /** Paramètres d'URL (liés automatiquement par le routeur). */
  readonly retour = input<string>();
  readonly reinitialise = input<string>();
  readonly expiree = input<string>();
  readonly desactive = input<string>();
  readonly suppression = input<string>();
  /** Donnée de route : écran de connexion principal (/auth/connexion). */
  readonly principal = input<boolean>();

  protected readonly form = inject(FormBuilder).nonNullable.group({
    identifiant: ['', Validators.required],
    motDePasse: ['', Validators.required],
    /** Décochée : la session se termine à la fermeture de l'onglet. */
    resterConnecte: [false],
  });
  protected readonly envoi = signal(false);
  protected readonly erreur = signal<ErreurApi | null>(null);
  protected readonly bloque = computed(() => this.erreur()?.status === 429);
  protected readonly googleIndisponible = signal(false);
  protected readonly apple = appleConfigure();
  protected readonly messageApple = signal<string | null>(null);
  protected readonly messagesApple = {
    indisponible: "La connexion Apple n'est pas disponible pour le moment.",
    echec: 'La connexion avec Apple a échoué. Réessayez.',
  };
  protected readonly enErreur = (nom: string) => enErreur(this.form, nom);
  /** Retour prévu, repris dans les liens vers les autres écrans. */
  protected readonly retourValide = computed(() => retourSur(this.retour()));

  ngOnInit(): void {
    // Mémorisé pour traverser le code de vérification ; une visite sans retour efface l'ancien.
    this.session.memoriserRetour(this.retour());
  }

  protected soumettre(): void {
    if (this.form.invalid) {
      this.form.markAllAsTouched();
      return;
    }
    const { identifiant, motDePasse, resterConnecte } = this.form.getRawValue();
    this.suivre(this.session.connexion(identifiant.trim(), motDePasse, resterConnecte));
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
      next: (r) => this.suite(r),
      error: (e) => {
        this.erreur.set(lireErreur(e));
        this.envoi.set(false);
      },
    });
  }

  private suite(r: AuthReponse): void {
    if (r.etape === 'OTP_ENVOYE') this.router.navigateByUrl('/auth/verification');
    else if (r.etape === 'TELEPHONE_REQUIS') this.router.navigateByUrl('/auth/telephone');
    else this.router.navigateByUrl(this.session.pageApresConnexion());
  }
}
