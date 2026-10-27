import { DatePipe } from '@angular/common';
import { ChangeDetectionStrategy, Component, DestroyRef, computed, inject, signal } from '@angular/core';
import { FormControl, ReactiveFormsModule } from '@angular/forms';
import { DomSanitizer, SafeResourceUrl } from '@angular/platform-browser';
import { RouterLink } from '@angular/router';
import { ErreurApi, lireErreur } from '../../core/api/erreur-api';
import { Alerte } from '../../shared/ui/alerte';
import { Icone, NomIcone } from '../../shared/ui/icone';
import { formaterTelephone, initiales } from '../profil/profil.service';
import { LIBELLES_ENERGIE, TypeDocument } from '../vehicules/vehicules.service';
import { AdminService, DocumentAValider, LIBELLES_DOCUMENT } from './admin.service';

const ICONES: Record<TypeDocument, NomIcone> = {
  PERMIS_CONDUIRE: 'carte-identite',
  PIECE_IDENTITE: 'utilisateur',
  CARTE_GRISE: 'voiture',
};

/**
 * Validation manuelle des documents (RG-U12), d'après la maquette « Validation des documents » : file d'attente à
 * gauche, document et informations à vérifier à droite, motif obligatoire pour un refus.
 */
@Component({
  selector: 'app-validation-documents',
  imports: [ReactiveFormsModule, RouterLink, DatePipe, Icone, Alerte],
  templateUrl: './validation-documents.html',
  styleUrl: './validation-documents.scss',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class ValidationDocuments {
  private readonly admin = inject(AdminService);
  private readonly sanitizer = inject(DomSanitizer);

  protected readonly libelles = LIBELLES_DOCUMENT;
  protected readonly icones = ICONES;
  protected readonly energies = LIBELLES_ENERGIE;
  protected readonly types = Object.entries(LIBELLES_DOCUMENT) as [TypeDocument, string][];
  protected readonly initiales = initiales;
  protected readonly telephone = (t: string | null) => (t ? formaterTelephone(t) : '—');

  protected readonly type = new FormControl<TypeDocument | ''>('', { nonNullable: true });
  protected readonly ordre = new FormControl<'anciens' | 'recents'>('anciens', { nonNullable: true });
  protected readonly recherche = new FormControl('', { nonNullable: true });
  protected readonly motif = new FormControl('', { nonNullable: true });

  protected readonly file = signal<DocumentAValider[]>([]);
  protected readonly total = signal(0);
  protected readonly charge = signal(false);
  protected readonly selection = signal<DocumentAValider | null>(null);
  protected readonly idChoisi = computed(() => this.selection()?.document.id ?? null);
  protected readonly decision = signal<'valider' | 'refuser' | null>(null);
  protected readonly erreur = signal<ErreurApi | null>(null);
  protected readonly confirmation = signal<string | null>(null);

  /** Aperçu du fichier : image ou PDF, téléchargé avec le jeton d'accès. */
  private urlLocale: string | null = null;
  protected readonly apercu = signal<{ url: string; pdf: boolean; securise: SafeResourceUrl } | null>(null);
  protected readonly zoom = signal(1);
  protected readonly rotation = signal(0);
  protected readonly transformation = computed(() => `scale(${this.zoom()}) rotate(${this.rotation()}deg)`);

  constructor() {
    this.charger();
    this.type.valueChanges.subscribe(() => this.charger());
    this.ordre.valueChanges.subscribe(() => this.charger());
    inject(DestroyRef).onDestroy(() => this.liberer());
  }

  protected charger(): void {
    this.erreur.set(null);
    this.admin.fileDeValidation(this.type.value, this.recherche.value, this.ordre.value === 'anciens').subscribe({
      next: (p) => {
        this.file.set(p.content);
        this.total.set(p.page.totalElements);
        this.charge.set(true);
        const courant = this.selection();
        this.choisir(p.content.find((d) => d.document.id === courant?.document.id) ?? p.content[0] ?? null);
      },
      error: (e) => this.erreur.set(lireErreur(e)),
    });
  }

  protected choisir(d: DocumentAValider | null): void {
    if (d && d.document.id === this.selection()?.document.id && this.apercu()) return;
    this.selection.set(d);
    this.motif.reset();
    this.zoom.set(1);
    this.rotation.set(0);
    this.liberer();
    if (!d) return;
    this.admin.fichier(d.document).subscribe({
      next: (blob) => {
        if (this.selection()?.document.id !== d.document.id) return;
        this.urlLocale = URL.createObjectURL(blob);
        this.apercu.set({
          url: this.urlLocale,
          pdf: d.document.typeMime === 'application/pdf',
          securise: this.sanitizer.bypassSecurityTrustResourceUrl(this.urlLocale),
        });
      },
      error: (e) => this.erreur.set(lireErreur(e)),
    });
  }

  protected zoomer(pas: number): void {
    this.zoom.update((z) => Math.min(3, Math.max(0.5, Math.round((z + pas) * 10) / 10)));
  }

  protected tourner(): void {
    this.rotation.update((r) => (r + 90) % 360);
  }

  protected valider(): void {
    const d = this.selection();
    if (!d) return;
    this.decider('valider', this.admin.valider(d.document.id), `${this.libelles[d.document.typeDocument]} de ${d.titulaire.prenom} validé(e).`);
  }

  protected refuser(): void {
    const d = this.selection();
    if (!d) return;
    if (!this.motif.value.trim()) {
      this.erreur.set({ status: 400, message: 'Indiquez le motif du refus : il sera communiqué au conducteur.', champ: 'motif' });
      return;
    }
    this.decider(
      'refuser',
      this.admin.refuser(d.document.id, this.motif.value.trim()),
      `${this.libelles[d.document.typeDocument]} de ${d.titulaire.prenom} refusé(e).`,
    );
  }

  /** Après une décision, la pièce quitte la file et la suivante s'affiche. */
  private decider(type: 'valider' | 'refuser', appel: ReturnType<AdminService['valider']>, message: string): void {
    const d = this.selection()!;
    this.decision.set(type);
    this.erreur.set(null);
    appel.subscribe({
      next: () => {
        const liste = this.file();
        const index = liste.findIndex((x) => x.document.id === d.document.id);
        const reste = liste.filter((x) => x.document.id !== d.document.id);
        this.file.set(reste);
        this.total.update((t) => Math.max(0, t - 1));
        this.decision.set(null);
        this.confirmation.set(message);
        this.choisir(reste[Math.min(index, reste.length - 1)] ?? null);
        // Les autres pièces du même titulaire ont changé de statut : on rafraîchit la file.
        if (reste.some((x) => x.titulaire.id === d.titulaire.id)) this.charger();
      },
      error: (e) => {
        this.erreur.set(lireErreur(e));
        this.decision.set(null);
      },
    });
  }

  private liberer(): void {
    if (this.urlLocale) URL.revokeObjectURL(this.urlLocale);
    this.urlLocale = null;
    this.apercu.set(null);
  }
}
