import { HttpClient } from '@angular/common/http';
import { Injectable, computed, inject, signal } from '@angular/core';
import { Router } from '@angular/router';
import { Observable, catchError, finalize, firstValueFrom, map, of, shareReplay, tap } from 'rxjs';
import { environment } from '../../../environments/environment';
import {
  AuthReponse,
  InscriptionRequete,
  Profil,
  Sexe,
  VerificationEnCours,
} from './auth.models';
import { stockage } from './stockage';

const CLE_REFRESH = 'covoitia.refresh';
const CLE_VERIFICATION = 'covoitia.verification';

/**
 * Session de l'utilisateur : jeton d'accès en mémoire uniquement, jeton de rafraîchissement
 * en localStorage pour rester connecté après rechargement. Toutes les routes /api/auth passent ici.
 */
@Injectable({ providedIn: 'root' })
export class SessionService {
  private readonly http = inject(HttpClient);
  private readonly router = inject(Router);
  private readonly api = `${environment.apiUrl}/auth`;

  private readonly jetonAcces = signal<string | null>(null);
  private readonly profil = signal<Profil | null>(null);
  private rafraichissementEnCours: Observable<string | null> | null = null;

  readonly utilisateur = this.profil.asReadonly();
  readonly estConnecte = computed(() => this.profil() !== null);
  readonly estAdmin = computed(() => this.profil()?.role === 'ADMIN');

  /** Vérification OTP en attente (après inscription, connexion d'un compte non vérifié ou Google). */
  readonly verification = signal<VerificationEnCours | null>(lireVerification());

  /** idToken Google conservé en mémoire le temps de demander le numéro de téléphone. */
  idTokenGoogle: string | null = null;

  get accessToken(): string | null {
    return this.jetonAcces();
  }

  // ------------------------------------------------------------------ Démarrage

  /** Au chargement de l'application : tente de rouvrir la session avec le refresh token. */
  restaurer(): Promise<unknown> {
    if (!stockage.lire(CLE_REFRESH)) return Promise.resolve();
    return firstValueFrom(this.rafraichir().pipe(catchError(() => of(null))));
  }

  // ------------------------------------------------------------------ Parcours d'authentification

  connexion(identifiant: string, motDePasse: string): Observable<AuthReponse> {
    return this.http
      .post<AuthReponse>(`${this.api}/connexion`, { identifiant, motDePasse })
      .pipe(tap((r) => this.traiter(r, identifiant)));
  }

  inscription(requete: InscriptionRequete): Observable<AuthReponse> {
    return this.http
      .post<AuthReponse>(`${this.api}/inscription`, requete)
      .pipe(tap((r) => this.traiter(r, requete.telephone)));
  }

  verifierOtp(code: string): Observable<AuthReponse> {
    const identifiant = this.verification()?.identifiant ?? '';
    return this.http
      .post<AuthReponse>(`${this.api}/otp/verifier`, { identifiant, code })
      .pipe(tap((r) => this.traiter(r, identifiant)));
  }

  renvoyerOtp(): Observable<AuthReponse> {
    const identifiant = this.verification()?.identifiant ?? '';
    return this.http
      .post<AuthReponse>(`${this.api}/otp/renvoyer`, { identifiant })
      .pipe(tap((r) => this.traiter(r, identifiant)));
  }

  connexionGoogle(idToken: string, telephone?: string, sexe?: Sexe | null): Observable<AuthReponse> {
    this.idTokenGoogle = idToken;
    return this.http
      .post<AuthReponse>(`${this.api}/google`, { idToken, telephone, sexe })
      .pipe(tap((r) => this.traiter(r, telephone ?? '')));
  }

  motDePasseOublie(identifiant: string): Observable<AuthReponse> {
    return this.http.post<AuthReponse>(`${this.api}/mot-de-passe/oublie`, { identifiant });
  }

  reinitialiserMotDePasse(identifiant: string, code: string, nouveauMotDePasse: string): Observable<void> {
    return this.http
      .post<void>(`${this.api}/mot-de-passe/reinitialiser`, { identifiant, code, nouveauMotDePasse })
      .pipe(tap(() => this.effacerSession()));
  }

  /**
   * Renouvelle le jeton d'accès. Les appels simultanés partagent la même requête
   * (le refresh token est à usage unique côté serveur).
   */
  rafraichir(): Observable<string | null> {
    const refresh = stockage.lire(CLE_REFRESH);
    if (!refresh) return of(null);
    this.rafraichissementEnCours ??= this.http
      .post<AuthReponse>(`${this.api}/refresh`, { refreshToken: refresh })
      .pipe(
        tap((r) => this.ouvrirSession(r)),
        map((r) => r.accessToken ?? null),
        catchError((e) => {
          this.effacerSession();
          throw e;
        }),
        finalize(() => (this.rafraichissementEnCours = null)),
        shareReplay(1),
      );
    return this.rafraichissementEnCours;
  }

  deconnexion(): void {
    const refresh = stockage.lire(CLE_REFRESH);
    if (refresh) {
      this.http.post(`${this.api}/deconnexion`, { refreshToken: refresh }).subscribe({ error: () => {} });
    }
    this.effacerSession();
    this.router.navigateByUrl('/auth/connexion');
  }

  /** Page d'arrivée selon le rôle. */
  pageAccueil(): string {
    return this.estAdmin() ? '/admin' : '/accueil';
  }

  /** Session perdue (refresh refusé) : on revient à l'écran de connexion. */
  sessionExpiree(): void {
    this.effacerSession();
    this.router.navigate(['/auth/connexion'], { queryParams: { expiree: 1 } });
  }

  // ------------------------------------------------------------------ Interne

  private traiter(r: AuthReponse, identifiant: string): void {
    if (r.etape === 'CONNECTE') {
      this.ouvrirSession(r);
      this.definirVerification(null);
      this.idTokenGoogle = null;
    } else if (r.etape === 'OTP_ENVOYE') {
      const maintenant = Date.now();
      this.definirVerification({
        identifiant,
        canal: r.canal ?? 'SMS',
        telephoneMasque: r.telephoneMasque ?? null,
        emailMasque: r.emailMasque ?? null,
        expireA: maintenant + (r.otpValiditeSecondes ?? 300) * 1000,
        renvoiPossibleA: maintenant + (r.renvoiPossibleDansSecondes ?? 60) * 1000,
      });
    }
  }

  private ouvrirSession(r: AuthReponse): void {
    if (!r.accessToken || !r.refreshToken || !r.utilisateur) return;
    this.jetonAcces.set(r.accessToken);
    this.profil.set(r.utilisateur);
    stockage.ecrire(CLE_REFRESH, r.refreshToken);
  }

  private effacerSession(): void {
    this.jetonAcces.set(null);
    this.profil.set(null);
    stockage.supprimer(CLE_REFRESH);
  }

  private definirVerification(v: VerificationEnCours | null): void {
    this.verification.set(v);
    if (v) stockage.ecrire(CLE_VERIFICATION, JSON.stringify(v), true);
    else stockage.supprimer(CLE_VERIFICATION, true);
  }
}

function lireVerification(): VerificationEnCours | null {
  const brut = stockage.lire(CLE_VERIFICATION, true);
  if (!brut) return null;
  try {
    return JSON.parse(brut) as VerificationEnCours;
  } catch {
    return null;
  }
}
