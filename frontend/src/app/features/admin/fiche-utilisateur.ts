import { DatePipe, DecimalPipe } from '@angular/common';
import { ChangeDetectionStrategy, Component, OnInit, computed, inject, input, signal } from '@angular/core';
import { FormControl, ReactiveFormsModule } from '@angular/forms';
import { RouterLink } from '@angular/router';
import { ErreurApi, lireErreur } from '../../core/api/erreur-api';
import { Alerte } from '../../shared/ui/alerte';
import { Icone } from '../../shared/ui/icone';
import { formaterTelephone, initiales } from '../profil/profil.service';
import { LIBELLES_ENERGIE, PieceJustificative } from '../vehicules/vehicules.service';
import { AdminService, FicheUtilisateur, LIBELLES_DOCUMENT, LIBELLES_STATUT, TypeAction } from './admin.service';

type Onglet = 'informations' | 'vehicules' | 'documents';
type Sanction = 'bloquer' | 'bannir';

const LIBELLES_ACTION: Record<TypeAction, string> = {
  DOCUMENT_VALIDE: 'Document validé',
  DOCUMENT_REFUSE: 'Document refusé',
  COMPTE_BLOQUE: 'Compte bloqué',
  COMPTE_BANNI: 'Compte banni',
  COMPTE_REACTIVE: 'Compte débloqué',
};

/** Fiche utilisateur du back-office (maquette « BO - Fiche utilisateur ») : compte, véhicules, documents, historique, blocage. */
@Component({
  selector: 'app-fiche-utilisateur',
  imports: [ReactiveFormsModule, RouterLink, DatePipe, DecimalPipe, Icone, Alerte],
  templateUrl: './fiche-utilisateur.html',
  styleUrl: './fiche-utilisateur.scss',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class FicheUtilisateurPage implements OnInit {
  private readonly admin = inject(AdminService);

  /** Paramètre de route. */
  readonly id = input.required<string>();

  protected readonly libellesStatut = LIBELLES_STATUT;
  protected readonly libellesDocument = LIBELLES_DOCUMENT;
  protected readonly libellesAction = LIBELLES_ACTION;
  protected readonly energies = LIBELLES_ENERGIE;
  protected readonly telephone = (t: string | null) => (t ? formaterTelephone(t) : '—');

  protected readonly fiche = signal<FicheUtilisateur | null>(null);
  protected readonly onglet = signal<Onglet>('informations');
  protected readonly erreur = signal<ErreurApi | null>(null);
  protected readonly succes = signal<string | null>(null);
  protected readonly sanction = signal<Sanction | null>(null);
  protected readonly envoi = signal(false);
  protected readonly motif = new FormControl('', { nonNullable: true });

  protected readonly u = computed(() => this.fiche()?.utilisateur ?? null);
  protected readonly initiales = computed(() => {
    const u = this.u();
    return u ? initiales(`${u.prenom} ${u.nom}`) : '';
  });
  protected readonly suspendu = computed(() => this.u()?.statut === 'BLOQUE' || this.u()?.statut === 'BANNI');
  protected readonly modifiable = computed(() => this.u()?.role !== 'ADMIN');

  ngOnInit(): void {
    this.admin.fiche(Number(this.id())).subscribe({
      next: (f) => this.fiche.set(f),
      error: (e) => this.erreur.set(lireErreur(e)),
    });
  }

  protected ouvrir(s: Sanction): void {
    this.motif.reset();
    this.erreur.set(null);
    this.sanction.set(s);
  }

  protected confirmer(): void {
    const s = this.sanction();
    const u = this.u();
    if (!s || !u) return;
    if (!this.motif.value.trim()) {
      this.erreur.set({ status: 400, message: 'Le motif est obligatoire.', champ: 'motif' });
      return;
    }
    this.envoi.set(true);
    const appel = s === 'bloquer' ? this.admin.bloquer(u.id, this.motif.value.trim()) : this.admin.bannir(u.id, this.motif.value.trim());
    appel.subscribe({
      next: (f) => this.terminer(f, s === 'bloquer' ? 'Compte bloqué. L’utilisateur a été prévenu.' : 'Compte banni. L’utilisateur a été prévenu.'),
      error: (e) => {
        this.erreur.set(lireErreur(e));
        this.envoi.set(false);
      },
    });
  }

  protected reactiver(): void {
    const u = this.u();
    if (!u) return;
    this.envoi.set(true);
    this.erreur.set(null);
    this.admin.reactiver(u.id).subscribe({
      next: (f) => this.terminer(f, 'Compte débloqué. L’utilisateur peut de nouveau se connecter.'),
      error: (e) => {
        this.erreur.set(lireErreur(e));
        this.envoi.set(false);
      },
    });
  }

  protected voir(piece: PieceJustificative): void {
    this.admin.fichier(piece).subscribe((blob) => {
      const url = URL.createObjectURL(blob);
      window.open(url, '_blank', 'noopener');
      setTimeout(() => URL.revokeObjectURL(url), 60_000);
    });
  }

  private terminer(f: FicheUtilisateur, message: string): void {
    this.fiche.set(f);
    this.sanction.set(null);
    this.envoi.set(false);
    this.succes.set(message);
  }
}
