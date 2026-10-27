import { HttpClient } from '@angular/common/http';
import { Injectable, inject } from '@angular/core';
import { Observable, tap } from 'rxjs';
import { environment } from '../../../environments/environment';
import { AuthReponse, Preferences, Profil, Sexe } from '../../core/auth/auth.models';
import { SessionService } from '../../core/auth/session.service';

/** Proche prévenu en cas d'alerte pendant un trajet (3 au plus). */
export interface ContactUrgence {
  id: number;
  nom: string;
  telephone: string;
  lien: string | null;
}

export interface ModificationProfil {
  prenom: string;
  nom: string;
  bio: string | null;
  sexe: Sexe | null;
}

/** Appels de l'écran « Mon profil » (01 Gestion des utilisateurs). Chaque profil renvoyé met à jour la session. */
@Injectable({ providedIn: 'root' })
export class ProfilService {
  private readonly http = inject(HttpClient);
  private readonly session = inject(SessionService);
  private readonly api = `${environment.apiUrl}/moi`;

  modifier(req: ModificationProfil): Observable<Profil> {
    return this.http.put<Profil>(this.api, req).pipe(tap((p) => this.session.mettreAJourProfil(p)));
  }

  modifierPreferences(p: Preferences): Observable<Profil> {
    return this.http.put<Profil>(`${this.api}/preferences`, p).pipe(tap((r) => this.session.mettreAJourProfil(r)));
  }

  changerPhoto(fichier: File): Observable<Profil> {
    const donnees = new FormData();
    donnees.append('fichier', fichier);
    return this.http.post<Profil>(`${this.api}/photo`, donnees).pipe(tap((p) => this.session.mettreAJourProfil(p)));
  }

  contactsUrgence(): Observable<ContactUrgence[]> {
    return this.http.get<ContactUrgence[]>(`${this.api}/contacts-urgence`);
  }

  ajouterContactUrgence(c: Omit<ContactUrgence, 'id'>): Observable<ContactUrgence> {
    return this.http.post<ContactUrgence>(`${this.api}/contacts-urgence`, c);
  }

  supprimerContactUrgence(id: number): Observable<void> {
    return this.http.delete<void>(`${this.api}/contacts-urgence/${id}`);
  }

  /** Les autres appareils sont déconnectés ; celui-ci reçoit de nouveaux jetons. */
  changerMotDePasse(motDePasseActuel: string | null, nouveauMotDePasse: string): Observable<AuthReponse> {
    return this.http
      .put<AuthReponse>(`${this.api}/mot-de-passe`, { motDePasseActuel, nouveauMotDePasse })
      .pipe(tap((r) => this.session.remplacerSession(r)));
  }

  desactiver(motDePasse: string | null): Observable<void> {
    return this.http
      .post<void>(`${this.api}/desactivation`, { motDePasse })
      .pipe(tap(() => this.session.oublierSession()));
  }
}

/** Adresse complète d'un fichier servi par le backend (« /api/fichiers/photos/… »). */
export function urlFichier(chemin: string | null): string | null {
  return chemin ? environment.apiUrl.replace(/\/api$/, '') + chemin : null;
}

/** +221771234512 → « +221 77 123 45 12 ». */
export function formaterTelephone(t: string): string {
  const m = /^\+221(\d{2})(\d{3})(\d{2})(\d{2})$/.exec(t);
  return m ? `+221 ${m[1]} ${m[2]} ${m[3]} ${m[4]}` : t;
}

/** « Ousmane Diop » → « OD ». */
export function initiales(nom: string): string {
  return nom
    .split(/\s+/)
    .filter(Boolean)
    .slice(0, 2)
    .map((m) => m[0]!.toUpperCase())
    .join('');
}
