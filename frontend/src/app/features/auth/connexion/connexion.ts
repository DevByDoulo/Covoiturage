import { ChangeDetectionStrategy, Component, OnInit, computed, inject, input, signal } from '@angular/core';
import { FormBuilder, ReactiveFormsModule, Validators } from '@angular/forms';
import { Router, RouterLink } from '@angular/router';
import { ErreurApi, lireErreur } from '../../../core/api/erreur-api';
import { AuthReponse } from '../../../core/auth/auth.models';
import { SessionService } from '../../../core/auth/session.service';
import { Alerte } from '../../../shared/ui/alerte';
import { ChampMotDePasse } from '../../../shared/ui/champ-mot-de-passe';
import { Icone } from '../../../shared/ui/icone';
import { enErreur, retourSur } from '../formulaire';

/**
 * « Autres options » (/auth/autres-options) : connexion par e-mail (ou numéro) et mot de passe, et lien vers la
 * création d'un compte avec une adresse e-mail. L'écran de départ (numéro, Google) est /auth/connexion.
 */
@Component({
  selector: 'app-connexion',
  imports: [ReactiveFormsModule, RouterLink, Icone, Alerte, ChampMotDePasse],
  templateUrl: './connexion.html',
  styleUrls: ['../auth-epure.scss', './connexion.scss'],
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class Connexion implements OnInit {
  private readonly session = inject(SessionService);
  private readonly router = inject(Router);

  /** Paramètres d'URL (liés automatiquement par le routeur). */
  readonly retour = input<string>();
  readonly reinitialise = input<string>();

  protected readonly form = inject(FormBuilder).nonNullable.group({
    identifiant: ['', Validators.required],
    motDePasse: ['', Validators.required],
    /** Décochée : la session se termine à la fermeture de l'onglet. */
    resterConnecte: [false],
  });
  protected readonly envoi = signal(false);
  protected readonly erreur = signal<ErreurApi | null>(null);
  protected readonly bloque = computed(() => this.erreur()?.status === 429);
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
    this.envoi.set(true);
    this.erreur.set(null);
    this.session.connexion(identifiant.trim(), motDePasse, resterConnecte).subscribe({
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
