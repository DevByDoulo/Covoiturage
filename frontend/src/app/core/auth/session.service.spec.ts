import { provideHttpClient } from '@angular/common/http';
import { HttpTestingController, provideHttpClientTesting } from '@angular/common/http/testing';
import { TestBed } from '@angular/core/testing';
import { provideRouter } from '@angular/router';
import { environment } from '../../../environments/environment';
import { SessionService } from './session.service';

/** « Rester connecté » : où est gardé le jeton de rafraîchissement. */
describe('SessionService : rester connecté', () => {
  const api = environment.apiUrl;
  const CLE = 'covoitia.refresh';
  const profil = { id: 1, prenom: 'Awa', role: 'PASSAGER' };
  let backend: HttpTestingController;
  let session: SessionService;

  function demarrer(): void {
    TestBed.configureTestingModule({
      providers: [provideRouter([{ path: '**', children: [] }]), provideHttpClient(), provideHttpClientTesting()],
    });
    backend = TestBed.inject(HttpTestingController);
    session = TestBed.inject(SessionService);
  }

  function connecter(resterConnecte: boolean, refresh = 'refresh-1'): void {
    session.connexion('awa@test.sn', 'MotDePasse2026', resterConnecte).subscribe();
    backend.expectOne(`${api}/auth/connexion`).flush({
      etape: 'CONNECTE', accessToken: 'jeton-1', refreshToken: refresh, utilisateur: profil,
    });
  }

  beforeEach(() => {
    localStorage.clear();
    sessionStorage.clear();
  });

  afterEach(() => backend.verify());

  it("par défaut, la session ne dure que le temps de l'onglet", () => {
    demarrer();
    connecter(false);
    expect(sessionStorage.getItem(CLE)).toBe('refresh-1');
    expect(localStorage.getItem(CLE)).toBeNull();
  });

  it('« Rester connecté » garde la session après fermeture du navigateur', () => {
    demarrer();
    connecter(true);
    expect(localStorage.getItem(CLE)).toBe('refresh-1');
    expect(sessionStorage.getItem(CLE)).toBeNull();
  });

  it('une nouvelle connexion sans la case efface la session gardée auparavant', () => {
    localStorage.setItem(CLE, 'ancien');
    demarrer();
    connecter(false, 'refresh-2');
    expect(localStorage.getItem(CLE)).toBeNull();
    expect(sessionStorage.getItem(CLE)).toBe('refresh-2');
  });

  it('le renouvellement du jeton reste au même endroit', () => {
    demarrer();
    connecter(true);
    session.rafraichir().subscribe();
    backend.expectOne(`${api}/auth/refresh`).flush({
      etape: 'CONNECTE', accessToken: 'jeton-2', refreshToken: 'refresh-2', utilisateur: profil,
    });
    expect(localStorage.getItem(CLE)).toBe('refresh-2');
    expect(sessionStorage.getItem(CLE)).toBeNull();
  });

  it('sans jeton gardé, rien à restaurer (fenêtre privée, nouvel onglet)', async () => {
    demarrer();
    await session.restaurer();
    expect(session.estConnecte()).toBe(false);
  });

  it('la déconnexion efface les deux emplacements', () => {
    demarrer();
    connecter(true);
    session.deconnexion();
    backend.expectOne(`${api}/auth/deconnexion`).flush(null);
    expect(localStorage.getItem(CLE)).toBeNull();
    expect(sessionStorage.getItem(CLE)).toBeNull();
  });
});
