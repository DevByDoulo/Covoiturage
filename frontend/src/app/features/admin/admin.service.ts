import { HttpClient, HttpParams } from '@angular/common/http';
import { Injectable, inject, signal } from '@angular/core';
import { Observable, tap } from 'rxjs';
import { environment } from '../../../environments/environment';
import { Role, Sexe, StatutCompte } from '../../core/auth/auth.models';
import { PieceJustificative, TypeDocument, Vehicule } from '../vehicules/vehicules.service';

/** Types alignés sur sn.isep.Convoiturage.admin.AdminDtos (module 07). */
export interface Statistiques {
  utilisateurs: number;
  comptesActifs: number;
  conducteurs: number;
  conducteursValides: number;
  comptesBloques: number;
  documentsEnAttente: number;
}

export interface UtilisateurLigne {
  id: number;
  prenom: string;
  nom: string;
  email: string | null;
  telephone: string | null;
  role: Role;
  statut: StatutCompte;
  conducteurValide: boolean;
  photoProfil: string | null;
  dateCreation: string;
  derniereConnexion: string | null;
}

export type TypeAction = 'DOCUMENT_VALIDE' | 'DOCUMENT_REFUSE' | 'COMPTE_BLOQUE' | 'COMPTE_BANNI' | 'COMPTE_REACTIVE';

export interface ActionAdmin {
  type: TypeAction;
  detail: string | null;
  admin: string;
  date: string;
}

export interface FicheUtilisateur {
  utilisateur: UtilisateurLigne;
  telephoneVerifie: boolean;
  emailVerifie: boolean;
  sexe: Sexe | null;
  bio: string | null;
  noteMoyenne: number | null;
  vehicules: Vehicule[];
  documents: PieceJustificative[];
  historique: ActionAdmin[];
}

export interface DocumentAValider {
  document: PieceJustificative;
  titulaire: UtilisateurLigne;
  telephoneVerifie: boolean;
  emailVerifie: boolean;
  vehicule: Vehicule | null;
  autresDocuments: PieceJustificative[];
}

export interface Page<T> {
  content: T[];
  page: { size: number; number: number; totalElements: number; totalPages: number };
}

export const LIBELLES_DOCUMENT: Record<TypeDocument, string> = {
  PERMIS_CONDUIRE: 'Permis de conduire',
  PIECE_IDENTITE: "Pièce d'identité",
  CARTE_GRISE: 'Carte grise',
};

export const LIBELLES_STATUT: Record<StatutCompte, string> = {
  ACTIF: 'Actif',
  BLOQUE: 'Bloqué',
  BANNI: 'Banni',
  DESACTIVE: 'Désactivé',
  EN_ATTENTE_OTP: 'Non vérifié',
};

@Injectable({ providedIn: 'root' })
export class AdminService {
  private readonly http = inject(HttpClient);
  private readonly api = `${environment.apiUrl}/admin`;

  /** Nombre de documents en attente, affiché en pastille dans le menu ; mis à jour après chaque décision. */
  readonly documentsEnAttente = signal<number | null>(null);

  statistiques(): Observable<Statistiques> {
    return this.http
      .get<Statistiques>(`${this.api}/statistiques`)
      .pipe(tap((s) => this.documentsEnAttente.set(s.documentsEnAttente)));
  }

  utilisateurs(recherche: string, statut: StatutCompte | '', page: number): Observable<Page<UtilisateurLigne>> {
    let params = new HttpParams().set('page', page).set('taille', 20);
    if (recherche.trim()) params = params.set('recherche', recherche.trim());
    if (statut) params = params.set('statut', statut);
    return this.http.get<Page<UtilisateurLigne>>(`${this.api}/utilisateurs`, { params });
  }

  fiche(id: number): Observable<FicheUtilisateur> {
    return this.http.get<FicheUtilisateur>(`${this.api}/utilisateurs/${id}`);
  }

  bloquer(id: number, motif: string): Observable<FicheUtilisateur> {
    return this.http.post<FicheUtilisateur>(`${this.api}/utilisateurs/${id}/bloquer`, { motif });
  }

  bannir(id: number, motif: string): Observable<FicheUtilisateur> {
    return this.http.post<FicheUtilisateur>(`${this.api}/utilisateurs/${id}/bannir`, { motif });
  }

  reactiver(id: number): Observable<FicheUtilisateur> {
    return this.http.post<FicheUtilisateur>(`${this.api}/utilisateurs/${id}/reactiver`, {});
  }

  fileDeValidation(type: TypeDocument | '', recherche: string, plusAnciensDabord: boolean): Observable<Page<DocumentAValider>> {
    let params = new HttpParams().set('plusAnciensDabord', plusAnciensDabord).set('taille', 50);
    if (type) params = params.set('type', type);
    if (recherche.trim()) params = params.set('recherche', recherche.trim());
    return this.http
      .get<Page<DocumentAValider>>(`${this.api}/documents`, { params })
      .pipe(tap((p) => !type && !recherche.trim() && this.documentsEnAttente.set(p.page.totalElements)));
  }

  valider(id: number): Observable<PieceJustificative> {
    return this.http.post<PieceJustificative>(`${this.api}/documents/${id}/valider`, {}).pipe(tap(() => this.decompter()));
  }

  refuser(id: number, motif: string): Observable<PieceJustificative> {
    return this.http
      .post<PieceJustificative>(`${this.api}/documents/${id}/refuser`, { motif })
      .pipe(tap(() => this.decompter()));
  }

  /** Télécharge un fichier protégé (jeton d'accès) et renvoie une adresse locale « blob: » pour l'afficher. */
  fichier(piece: PieceJustificative): Observable<Blob> {
    return this.http.get(environment.apiUrl.replace(/\/api$/, '') + piece.urlFichier, { responseType: 'blob' });
  }

  private decompter(): void {
    this.documentsEnAttente.update((n) => (n === null ? null : Math.max(0, n - 1)));
  }
}
