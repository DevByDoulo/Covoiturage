import { ChangeDetectionStrategy, Component, computed, inject, input, OnInit, signal } from '@angular/core';
import { FormBuilder, ReactiveFormsModule, Validators } from '@angular/forms';
import { Router } from '@angular/router';
import { ErreurApi, lireErreur } from '../../core/api/erreur-api';
import { Alerte } from '../../shared/ui/alerte';
import { EntetePage } from '../../shared/ui/entete-page';
import { Icone } from '../../shared/ui/icone';
import { urlFichier } from '../profil/profil.service';
import { LIBELLES_ENERGIE, TypeEnergie, Vehicule, VehiculeRequete, VehiculesService } from './vehicules.service';

const IDENTITE = ['immatriculation', 'marque', 'modele', 'annee', 'puissanceFiscale', 'nombrePlaces', 'typeEnergie'] as const;

/**
 * Ajout (/vehicules/nouveau) ou modification (/vehicules/:id) d'un véhicule. Une fois la carte grise validée,
 * seules la consommation et l'usure restent modifiables (le reste figure sur la carte grise).
 */
@Component({
  selector: 'app-formulaire-vehicule',
  imports: [ReactiveFormsModule, EntetePage, Alerte, Icone],
  templateUrl: './formulaire-vehicule.html',
  styleUrl: './formulaire-vehicule.scss',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class FormulaireVehicule implements OnInit {
  private readonly api = inject(VehiculesService);
  private readonly router = inject(Router);
  private readonly fb = inject(FormBuilder);

  /** Paramètre de route : « nouveau » ou l'identifiant du véhicule. */
  readonly id = input<string>();

  protected readonly energies = Object.entries(LIBELLES_ENERGIE) as [TypeEnergie, string][];
  protected readonly places = [2, 3, 4, 5, 6, 7, 8, 9];
  protected readonly vehicule = signal<Vehicule | null>(null);
  protected readonly modification = computed(() => this.id() !== undefined && this.id() !== 'nouveau');
  protected readonly valide = computed(() => this.vehicule()?.statutValidation === 'VALIDE');
  protected readonly photo = computed(() => urlFichier(this.vehicule()?.photo ?? null));
  protected readonly envoi = signal(false);
  protected readonly envoiPhoto = signal(false);
  protected readonly erreur = signal<ErreurApi | null>(null);

  protected readonly form = this.fb.group({
    immatriculation: ['', [Validators.required, Validators.pattern(/^[A-Za-z0-9 -]{4,20}$/)]],
    marque: ['', [Validators.required, Validators.maxLength(60)]],
    modele: ['', [Validators.required, Validators.maxLength(60)]],
    annee: [null as number | null, [Validators.required, Validators.min(1980), Validators.max(new Date().getFullYear() + 1)]],
    puissanceFiscale: [null as number | null, [Validators.required, Validators.min(1), Validators.max(60)]],
    nombrePlaces: [5, Validators.required],
    typeEnergie: ['ESSENCE' as TypeEnergie, Validators.required],
    consommationTheorique: [null as number | null, [Validators.min(1), Validators.max(40)]],
    consommationReelle: [null as number | null, [Validators.min(1), Validators.max(40)]],
    amortissementParKm: [null as number | null, [Validators.min(0), Validators.max(1000)]],
  });

  ngOnInit(): void {
    if (!this.modification()) return;
    this.api.mesVehicules().subscribe({
      next: (liste) => {
        const v = liste.find((x) => String(x.id) === this.id());
        if (!v) {
          this.router.navigateByUrl('/vehicules');
          return;
        }
        this.vehicule.set(v);
        this.form.patchValue(v);
        if (v.statutValidation === 'VALIDE') IDENTITE.forEach((c) => this.form.controls[c].disable());
      },
      error: (e) => this.erreur.set(lireErreur(e)),
    });
  }

  protected enErreur(nom: keyof typeof this.form.controls): boolean {
    const c = this.form.controls[nom];
    return c.invalid && (c.touched || c.dirty);
  }

  protected enregistrer(): void {
    if (this.form.invalid) {
      this.form.markAllAsTouched();
      return;
    }
    const requete = this.form.getRawValue() as VehiculeRequete;
    const v = this.vehicule();
    this.envoi.set(true);
    this.erreur.set(null);
    (v ? this.api.modifier(v.id, requete) : this.api.declarer(requete)).subscribe({
      next: () => this.router.navigateByUrl('/vehicules'),
      error: (e) => {
        this.erreur.set(lireErreur(e));
        this.envoi.set(false);
      },
    });
  }

  protected choisirPhoto(evenement: Event): void {
    const champ = evenement.target as HTMLInputElement;
    const fichier = champ.files?.[0];
    const v = this.vehicule();
    champ.value = '';
    if (!fichier || !v) return;
    this.envoiPhoto.set(true);
    this.erreur.set(null);
    this.api.changerPhoto(v.id, fichier).subscribe({
      next: (maj) => {
        this.vehicule.set(maj);
        this.envoiPhoto.set(false);
      },
      error: (e) => {
        this.erreur.set(lireErreur(e));
        this.envoiPhoto.set(false);
      },
    });
  }

  protected retirer(): void {
    const v = this.vehicule();
    if (!v || !confirm(`Retirer ${v.marque} ${v.modele} (${v.immatriculation}) de vos véhicules ?`)) return;
    this.api.retirer(v.id).subscribe({
      next: () => this.router.navigateByUrl('/vehicules'),
      error: (e) => this.erreur.set(lireErreur(e)),
    });
  }
}
