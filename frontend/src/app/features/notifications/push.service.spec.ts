import { provideHttpClient } from '@angular/common/http';
import { HttpTestingController, TestRequest, provideHttpClientTesting } from '@angular/common/http/testing';
import { TestBed } from '@angular/core/testing';
import { Router, provideRouter } from '@angular/router';
import { environment } from '../../../environments/environment';
import { SessionService } from '../../core/auth/session.service';
import { MessageServiceWorker, PLATEFORME_PUSH, PlateformePushWeb, PushService } from './push.service';

/** Navigateur et Firebase simulés. */
class FaussePlateforme implements PlateformePushWeb {
  supporte = true;
  configure = true;
  autorisation: NotificationPermission = 'default';
  reponse: NotificationPermission = 'granted';
  suppressions = 0;
  ecouteur: ((m: MessageServiceWorker) => void) | null = null;

  supportee = () => this.supporte;
  configuree = () => this.configure;
  permission = () => this.autorisation;
  demanderPermission = async () => (this.autorisation = this.reponse);
  jeton = async () => 'jeton-web';
  supprimerJeton = async () => {
    this.suppressions++;
  };
  ecouter = (traiter: (m: MessageServiceWorker) => void) => {
    this.ecouteur = traiter;
  };
}

describe('PushService : notifications push du navigateur', () => {
  const api = environment.apiUrl;
  let backend: HttpTestingController;
  let plateforme: FaussePlateforme;
  let push: PushService;

  beforeEach(() => {
    plateforme = new FaussePlateforme();
    TestBed.configureTestingModule({
      providers: [
        provideRouter([{ path: '**', children: [] }]),
        provideHttpClient(),
        provideHttpClientTesting(),
        { provide: PLATEFORME_PUSH, useValue: plateforme },
      ],
    });
    backend = TestBed.inject(HttpTestingController);
    push = TestBed.inject(PushService);
  });

  afterEach(() => backend.verify());

  /** Les appels partent après des promesses (permission, jeton) : on laisse tourner la file avant de chercher. */
  async function requete(url: string, methode = 'POST'): Promise<TestRequest> {
    for (let i = 0; i < 20; i++) {
      const trouvees = backend.match((r) => r.url === url && r.method === methode);
      if (trouvees.length) return trouvees[0];
      await Promise.resolve();
    }
    return backend.expectOne(url);
  }

  async function activerAvecJeton(): Promise<void> {
    plateforme.autorisation = 'granted';
    const fin = push.demarrer();
    (await requete(`${api}/moi/appareils`)).flush(null, { status: 204, statusText: 'No Content' });
    await fin;
  }

  it('permission déjà accordée : le jeton est enregistré à l\'ouverture de l\'espace connecté', async () => {
    plateforme.autorisation = 'granted';
    const fin = push.demarrer();
    const req = await requete(`${api}/moi/appareils`);
    expect(req.request.body).toEqual({ jeton: 'jeton-web', plateforme: 'WEB' });
    req.flush(null, { status: 204, statusText: 'No Content' });
    await fin;
    expect(push.etat()).toBe('actif');
  });

  it("jamais demandée : rien sans clic, puis « Activer » ouvre la fenêtre et enregistre", async () => {
    await push.demarrer();
    expect(push.etat()).toBe('inactif');
    backend.expectNone(`${api}/moi/appareils`);

    const fin = push.activer();
    (await requete(`${api}/moi/appareils`)).flush(null, { status: 204, statusText: 'No Content' });
    expect(await fin).toBe(true);
    expect(push.etat()).toBe('actif');
  });

  it('permission refusée, Firebase non configuré ou navigateur trop ancien : rien n\'est envoyé', async () => {
    plateforme.reponse = 'denied';
    expect(await push.activer()).toBe(false);
    expect(push.etat()).toBe('bloque');

    plateforme.configure = false;
    await push.demarrer();
    expect(push.etat()).toBe('non-configure');

    plateforme.supporte = false;
    await push.demarrer();
    expect(push.etat()).toBe('indisponible');
  });

  it('déconnexion : le jeton est retiré côté serveur et dans le navigateur', async () => {
    await activerAvecJeton();
    TestBed.inject(SessionService).deconnexion();
    backend.expectOne((r) => r.method === 'DELETE' && r.url === `${api}/moi/appareils/jeton-web`).flush(null);
    expect(plateforme.suppressions).toBe(1);
    expect(push.etat()).toBe('inactif');
  });

  it('clic sur une notification : la cloche est mise à jour et l\'écran du lien s\'ouvre', async () => {
    await activerAvecJeton();
    const naviguer = vi.spyOn(TestBed.inject(Router), 'navigateByUrl');
    plateforme.ecouteur?.({ type: 'yobalema-ouvrir', lien: '/trajets/12' });
    backend.expectOne(`${api}/moi/notifications/non-lues`).flush({ nombre: 3 });
    expect(naviguer).toHaveBeenCalledWith('/trajets/12');
  });

  it('préférence du compte lue puis modifiée', () => {
    push.preferences().subscribe((p) => expect(p.pushActive).toBe(true));
    backend.expectOne(`${api}/moi/notifications/preferences`).flush({ pushActive: true });
    push.modifierPreferences(false).subscribe((p) => expect(p.pushActive).toBe(false));
    const req = backend.expectOne((r) => r.method === 'PUT' && r.url === `${api}/moi/notifications/preferences`);
    expect(req.request.body).toEqual({ pushActive: false });
    req.flush({ pushActive: false });
  });
});
