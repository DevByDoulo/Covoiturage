import { provideHttpClient } from '@angular/common/http';
import { HttpTestingController, provideHttpClientTesting } from '@angular/common/http/testing';
import { EnvironmentInjector, runInInjectionContext } from '@angular/core';
import { TestBed } from '@angular/core/testing';
import { ActivatedRouteSnapshot, Route, Router, RouterStateSnapshot, UrlSegment, UrlTree, convertToParamMap, provideRouter } from '@angular/router';
import { environment } from '../../../environments/environment';
import { connecteGuard, idTrajetMatch, invitesGuard, visiteurMatch } from './auth.guards';
import { SessionService } from './session.service';

describe('guards de navigation (accueil public)', () => {
  const api = environment.apiUrl;
  let session: SessionService;
  let backend: HttpTestingController;
  let router: Router;

  beforeEach(() => {
    localStorage.clear();
    sessionStorage.clear();
    TestBed.configureTestingModule({
      providers: [provideRouter([{ path: '**', children: [] }]), provideHttpClient(), provideHttpClientTesting()],
    });
    session = TestBed.inject(SessionService);
    backend = TestBed.inject(HttpTestingController);
    router = TestBed.inject(Router);
  });

  afterEach(() => backend.verify());

  function connecter(role = 'PASSAGER'): void {
    session.connexion('awa@test.sn', 'MotDePasse2026').subscribe();
    backend.expectOne(`${api}/auth/connexion`).flush({
      etape: 'CONNECTE', accessToken: 'jeton', refreshToken: 'refresh', utilisateur: { id: 1, prenom: 'Awa', role },
    });
  }

  const executer = <T>(f: () => T): T => runInInjectionContext(TestBed.inject(EnvironmentInjector), f);
  const segments = (url: string) => url.split('/').filter(Boolean).map((p) => new UrlSegment(p, {}));
  const etat = (url: string) => ({ url }) as RouterStateSnapshot;
  const route = (retour?: string) =>
    ({ queryParamMap: convertToParamMap(retour ? { retour } : {}) }) as ActivatedRouteSnapshot;

  it("visiteurMatch : la version publique n'est retenue que sans session", () => {
    expect(executer(() => visiteurMatch({} as Route, []))).toBe(true);
    connecter();
    expect(executer(() => visiteurMatch({} as Route, []))).toBe(false);
  });

  it('idTrajetMatch : seuls les identifiants numériques sont des trajets', () => {
    expect(executer(() => idTrajetMatch({} as Route, segments('/trajets/42')))).toBe(true);
    expect(executer(() => idTrajetMatch({} as Route, segments('/trajets/publier')))).toBe(false);
    expect(executer(() => idTrajetMatch({} as Route, segments('/trajets/mes-trajets')))).toBe(false);
  });

  it('connecteGuard : un visiteur part vers la connexion avec retour sur la page demandée', () => {
    const r = executer(() => connecteGuard(route(), etat('/trajets/publier'))) as UrlTree;
    expect(router.serializeUrl(r)).toBe('/auth/connexion?retour=%2Ftrajets%2Fpublier');
  });

  it('connecteGuard : le retour garde les critères de recherche', () => {
    const url = '/rechercher?de=Dakar&dlat=14.69&date=2026-11-20';
    const r = executer(() => connecteGuard(route(), etat(url))) as UrlTree;
    expect(r.queryParams['retour']).toBe(url);
  });

  it("invitesGuard : connecté, on rejoint le retour prévu (interne seulement), sinon l'accueil", () => {
    expect(executer(() => invitesGuard(route('/trajets/7'), etat('/auth/connexion')))).toBe(true);
    connecter();
    const versRetour = executer(() => invitesGuard(route('/trajets/7'), etat('/auth/connexion'))) as UrlTree;
    expect(router.serializeUrl(versRetour)).toBe('/trajets/7');
    const externe = executer(() => invitesGuard(route('//evil.com'), etat('/auth/connexion'))) as UrlTree;
    expect(router.serializeUrl(externe)).toBe('/accueil');
  });
});

describe('SessionService : retour après connexion', () => {
  let session: SessionService;

  beforeEach(() => {
    sessionStorage.clear();
    TestBed.configureTestingModule({
      providers: [provideRouter([]), provideHttpClient(), provideHttpClientTesting()],
    });
    session = TestBed.inject(SessionService);
  });

  it("rend le retour mémorisé une seule fois, puis l'accueil du rôle", () => {
    session.memoriserRetour('/trajets/12');
    expect(session.pageApresConnexion()).toBe('/trajets/12');
    expect(session.pageApresConnexion()).toBe('/accueil');
  });

  it('ignore les adresses externes et efface le retour quand on en donne un vide', () => {
    session.memoriserRetour('https://evil.com');
    expect(session.pageApresConnexion()).toBe('/accueil');
    session.memoriserRetour('/rechercher?de=Dakar');
    session.memoriserRetour(undefined);
    expect(session.pageApresConnexion()).toBe('/accueil');
  });
});
