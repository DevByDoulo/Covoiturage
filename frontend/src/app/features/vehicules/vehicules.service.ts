import { HttpClient } from '@angular/common/http';
import { Injectable, inject } from '@angular/core';
import { Observable, switchMap } from 'rxjs';
import { environment } from '../../../environments/environment';
import { SessionService } from '../../core/auth/session.service';

/** Types alignés sur sn.isep.Convoiturage.vehicule (02 Gestion des véhicules). */
export type TypeEnergie = 'ESSENCE' | 'DIESEL' | 'HYBRIDE' | 'ELECTRIQUE';
export type StatutValidation = 'EN_ATTENTE' | 'VALIDE' | 'REFUSE';
export type TypeDocument = 'PERMIS_CONDUIRE' | 'PIECE_IDENTITE' | 'CARTE_GRISE';

export interface VehiculeRequete {
  immatriculation: string;
  marque: string;
  modele: string;
  annee: number;
  puissanceFiscale: number;
  nombrePlaces: number;
  typeEnergie: TypeEnergie;
  consommationTheorique: number | null;
  consommationReelle: number | null;
  amortissementParKm: number | null;
}

export interface Vehicule extends VehiculeRequete {
  id: number;
  statutValidation: StatutValidation;
  photo: string | null;
  dateCreation: string;
}

export interface PieceJustificative {
  id: number;
  typeDocument: TypeDocument;
  idVehicule: number | null;
  immatriculation: string | null;
  nomOriginal: string | null;
  typeMime: string;
  statutValidation: StatutValidation;
  commentaireAdmin: string | null;
  dateSoumission: string;
  dateValidation: string | null;
  urlFichier: string;
}

export const LIBELLES_ENERGIE: Record<TypeEnergie, string> = {
  ESSENCE: 'Essence',
  DIESEL: 'Diesel',
  HYBRIDE: 'Hybride',
  ELECTRIQUE: 'Électrique',
};

@Injectable({ providedIn: 'root' })
export class VehiculesService {
  private readonly http = inject(HttpClient);
  private readonly session = inject(SessionService);
  private readonly api = `${environment.apiUrl}/moi`;

  mesVehicules(): Observable<Vehicule[]> {
    return this.http.get<Vehicule[]>(`${this.api}/vehicules`);
  }

  /**
   * Le premier véhicule fait passer le compte en rôle CONDUCTEUR : on rafraîchit la session pour que le jeton
   * et le profil portent le nouveau rôle.
   */
  declarer(v: VehiculeRequete): Observable<Vehicule> {
    return this.http
      .post<Vehicule>(`${this.api}/vehicules`, v)
      .pipe(switchMap((cree) => this.session.rafraichir().pipe(switchMap(() => [cree]))));
  }

  modifier(id: number, v: VehiculeRequete): Observable<Vehicule> {
    return this.http.put<Vehicule>(`${this.api}/vehicules/${id}`, v);
  }

  changerPhoto(id: number, fichier: File): Observable<Vehicule> {
    const donnees = new FormData();
    donnees.append('fichier', fichier);
    return this.http.post<Vehicule>(`${this.api}/vehicules/${id}/photo`, donnees);
  }

  retirer(id: number): Observable<void> {
    return this.http.delete<void>(`${this.api}/vehicules/${id}`);
  }

  mesDocuments(): Observable<PieceJustificative[]> {
    return this.http.get<PieceJustificative[]>(`${this.api}/documents`);
  }

  soumettre(type: TypeDocument, fichier: File, idVehicule: number | null): Observable<PieceJustificative> {
    const donnees = new FormData();
    donnees.append('type', type);
    if (idVehicule !== null) donnees.append('idVehicule', String(idVehicule));
    donnees.append('fichier', fichier);
    return this.http.post<PieceJustificative>(`${this.api}/documents`, donnees);
  }

  /** Le fichier exige le jeton d'accès : on le télécharge puis on l'ouvre dans un nouvel onglet. */
  ouvrirFichier(piece: PieceJustificative): void {
    const url = environment.apiUrl.replace(/\/api$/, '') + piece.urlFichier;
    this.http.get(url, { responseType: 'blob' }).subscribe((blob) => {
      const lien = URL.createObjectURL(blob);
      window.open(lien, '_blank', 'noopener');
      setTimeout(() => URL.revokeObjectURL(lien), 60_000);
    });
  }
}

/** Dernière pièce envoyée pour un type (et un véhicule, pour la carte grise). Les pièces arrivent de la plus récente à la plus ancienne. */
export function dernierePiece(
  pieces: PieceJustificative[],
  type: TypeDocument,
  idVehicule: number | null = null,
): PieceJustificative | null {
  return pieces.find((p) => p.typeDocument === type && p.idVehicule === idVehicule) ?? null;
}
