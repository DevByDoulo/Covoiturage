import { HttpClient, provideHttpClient, withInterceptors } from '@angular/common/http';
import { HttpTestingController, provideHttpClientTesting } from '@angular/common/http/testing';
import { TestBed } from '@angular/core/testing';
import { provideRouter } from '@angular/router';
import { environment } from '../../../environments/environment';
import { authInterceptor } from './auth.interceptor';
import { SessionService } from './session.service';

describe('authInterceptor', () => {
  let http: HttpClient;
  let backend: HttpTestingController;
  let session: SessionService;
  const api = environment.apiUrl;
  const profil = { id: 1, prenom: 'Awa', role: 'PASSAGER' };

  beforeEach(() => {
    localStorage.clear();
    TestBed.configureTestingModule({
      providers: [provideRouter([{ path: '**', children: [] }]), provideHttpClient(withInterceptors([authInterceptor])), provideHttpClientTesting()],
    });
    http = TestBed.inject(HttpClient);
    backend = TestBed.inject(HttpTestingController);
    session = TestBed.inject(SessionService);
  });

  afterEach(() => backend.verify());

  function connecter(): void {
    session.connexion('awa@test.sn', 'MotDePasse2026').subscribe();
    backend.expectOne(`${api}/auth/connexion`).flush({
      etape: 'CONNECTE', accessToken: 'jeton-1', refreshToken: 'refresh-1', expiresIn: 1800, utilisateur: profil,
    });
  }

  it("ajoute le jeton d'accès aux appels de l'API", () => {
    connecter();
    http.get(`${api}/moi`).subscribe();
    expect(backend.expectOne(`${api}/moi`).request.headers.get('Authorization')).toBe('Bearer jeton-1');
  });

  it("n'envoie pas le jeton aux autres domaines", () => {
    connecter();
    http.get('https://example.com/data').subscribe();
    expect(backend.expectOne('https://example.com/data').request.headers.has('Authorization')).toBe(false);
  });

  it('renouvelle le jeton sur un 401 puis rejoue la requête', () => {
    connecter();
    let reponse: unknown;
    http.get(`${api}/moi`).subscribe((r) => (reponse = r));
    backend.expectOne(`${api}/moi`).flush(null, { status: 401, statusText: 'Unauthorized' });

    const refresh = backend.expectOne(`${api}/auth/refresh`);
    expect(refresh.request.body).toEqual({ refreshToken: 'refresh-1' });
    refresh.flush({ etape: 'CONNECTE', accessToken: 'jeton-2', refreshToken: 'refresh-2', utilisateur: profil });

    const rejeu = backend.expectOne(`${api}/moi`);
    expect(rejeu.request.headers.get('Authorization')).toBe('Bearer jeton-2');
    rejeu.flush({ ok: true });
    expect(reponse).toEqual({ ok: true });
    expect(localStorage.getItem('covoitia.refresh')).toBe('refresh-2');
  });

  it('ferme la session si le renouvellement échoue', () => {
    connecter();
    http.get(`${api}/moi`).subscribe({ error: () => {} });
    backend.expectOne(`${api}/moi`).flush(null, { status: 401, statusText: 'Unauthorized' });
    backend.expectOne(`${api}/auth/refresh`).flush(null, { status: 401, statusText: 'Unauthorized' });
    expect(session.estConnecte()).toBe(false);
    expect(localStorage.getItem('covoitia.refresh')).toBeNull();
  });

  it('mémorise la vérification OTP en cours', () => {
    session.inscription({ prenom: 'A', nom: 'D', email: 'a@d.sn', telephone: '+221771234567', motDePasse: 'x', sexe: 'FEMME' }).subscribe();
    backend.expectOne(`${api}/auth/inscription`).flush({
      etape: 'OTP_ENVOYE', telephoneMasque: '+22177 ** *** 67', otpValiditeSecondes: 300, renvoiPossibleDansSecondes: 60,
    });
    const v = session.verification();
    expect(v?.identifiant).toBe('+221771234567');
    expect(v!.expireA - Date.now()).toBeGreaterThan(290_000);
  });
});
