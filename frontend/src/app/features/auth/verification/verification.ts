import { ChangeDetectionStrategy, Component, computed, inject, signal, viewChild } from '@angular/core';
import { FormControl, ReactiveFormsModule, Validators } from '@angular/forms';
import { Router } from '@angular/router';
import { ErreurApi, lireErreur } from '../../../core/api/erreur-api';
import { SessionService } from '../../../core/auth/session.service';
import { Alerte } from '../../../shared/ui/alerte';
import { compteARebours, formatMinutes } from '../../../shared/ui/compte-a-rebours';
import { EntetePage } from '../../../shared/ui/entete-page';
import { Icone } from '../../../shared/ui/icone';
import { PaveNumerique } from '../../../shared/ui/pave-numerique';
import { SaisieCode } from '../../../shared/ui/saisie-code';

@Component({
  selector: 'app-verification',
  imports: [ReactiveFormsModule, EntetePage, Icone, Alerte, SaisieCode, PaveNumerique],
  templateUrl: './verification.html',
  styleUrls: ['../auth-commun.scss', './verification.scss'],
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class Verification {
  private readonly session = inject(SessionService);
  private readonly router = inject(Router);

  protected readonly verification = this.session.verification;
  protected readonly code = new FormControl('', { nonNullable: true, validators: [Validators.pattern(/^\d{6}$/)] });
  protected readonly envoi = signal(false);
  protected readonly renvoiEnCours = signal(false);
  protected readonly erreur = signal<ErreurApi | null>(null);
  protected readonly codeRenvoye = signal(false);

  protected readonly validite = compteARebours(computed(() => this.verification()?.expireA ?? null));
  protected readonly attenteRenvoi = compteARebours(computed(() => this.verification()?.renvoiPossibleA ?? null));
  protected readonly validiteTexte = computed(() => formatMinutes(this.validite()));
  protected readonly plusDEssai = computed(() => this.erreur()?.tentativesRestantes === 0);

  private readonly saisie = viewChild(SaisieCode);

  protected verifier(): void {
    const code = this.code.value;
    if (code.length !== 6 || this.envoi()) return;
    this.envoi.set(true);
    this.erreur.set(null);
    this.session.verifierOtp(code).subscribe({
      next: () => this.router.navigateByUrl(this.session.pageAccueil()),
      error: (e) => {
        this.erreur.set(lireErreur(e));
        this.envoi.set(false);
        this.code.setValue('');
        this.saisie()?.focus();
      },
    });
  }

  protected renvoyer(): void {
    this.renvoiEnCours.set(true);
    this.erreur.set(null);
    this.session.renvoyerOtp().subscribe({
      next: () => {
        this.renvoiEnCours.set(false);
        this.codeRenvoye.set(true);
        this.code.setValue('');
      },
      error: (e) => {
        this.erreur.set(lireErreur(e));
        this.renvoiEnCours.set(false);
      },
    });
  }
}
