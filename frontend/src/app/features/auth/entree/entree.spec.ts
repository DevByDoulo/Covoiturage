import { provideHttpClient } from '@angular/common/http';
import { HttpTestingController, provideHttpClientTesting } from '@angular/common/http/testing';
import { TestBed } from '@angular/core/testing';
import { Router, provideRouter } from '@angular/router';
import { environment } from '../../../../environments/environment';
import { SessionService } from '../../../core/auth/session.service';
import { Entree } from './entree';

describe('Écran de départ (numéro, Google, autres options)', () => {
  const api = environment.apiUrl;
  let backend: HttpTestingController;
  let router: Router;

  function creer() {
    TestBed.configureTestingModule({
      providers: [provideRouter([{ path: '**', children: [] }]), provideHttpClient(), provideHttpClientTesting()],
    });
    backend = TestBed.inject(HttpTestingController);
    router = TestBed.inject(Router);
    const fixture = TestBed.createComponent(Entree);
    fixture.detectChanges();
    const el = fixture.nativeElement as HTMLElement;
    const saisir = (valeur: string) => {
      const input = el.querySelector<HTMLInputElement>('#telephone')!;
      input.value = valeur;
      input.dispatchEvent(new Event('input'));
      fixture.detectChanges();
    };
    const continuer = () => {
      el.querySelector('form')!.dispatchEvent(new Event('submit', { cancelable: true }));
      fixture.detectChanges();
    };
    return { fixture, el, saisir, continuer };
  }

  beforeEach(() => sessionStorage.clear());
  afterEach(() => backend.verify());

  it("montre le numéro en premier, puis « ou », Google et « Autres options »", () => {
    const { el } = creer();
    const ordre = [...el.querySelectorAll('#telephone, .separateur, app-bouton-google, .autres-options')].map((n) =>
      n.id || n.className || n.tagName.toLowerCase(),
    );
    expect(ordre).toEqual(['telephone', 'separateur', 'app-bouton-google', 'autres-options']);
    expect(el.querySelector('.indicatif')?.textContent).toContain('+221');
    expect(el.querySelector('button[type=submit]')?.textContent).toContain('Continuer');
    expect(el.querySelector('.autres-options')?.getAttribute('href')).toBe('/auth/autres-options');
  });

  it("masque le bouton Apple tant que la configuration Apple est vide", () => {
    expect(environment.apple.clientId).toBe('');
    const { el } = creer();
    expect(el.querySelector('app-bouton-apple')).toBeNull();
    expect(el.textContent).not.toContain('pas encore activée');
  });

  it('affiche le bouton Apple quand le Services ID est renseigné', () => {
    const avant = { ...environment.apple };
    Object.assign(environment.apple, { clientId: 'sn.yobalema.web', redirectUri: 'https://yobalema.sn/auth' });
    try {
      const { el } = creer();
      expect(el.querySelector('app-bouton-apple')).not.toBeNull();
    } finally {
      Object.assign(environment.apple, avant);
    }
  });

  it("n'envoie rien sans un numéro sénégalais valable", () => {
    const { el, saisir, continuer } = creer();
    continuer();
    expect(el.querySelector('.message-erreur')?.textContent).toContain('Saisissez votre numéro');
    saisir('12 34');
    continuer();
    expect(el.querySelector('.message-erreur')?.textContent).toContain('9 chiffres');
  });

  it('envoie le code par SMS puis ouvre la saisie du code', () => {
    const { saisir, continuer } = creer();
    const navigation = vi.spyOn(router, 'navigateByUrl');
    saisir('77 123 45 67');
    continuer();
    const req = backend.expectOne(`${api}/auth/telephone/code`);
    expect(req.request.body).toEqual({ telephone: '+221771234567' });
    req.flush({ etape: 'OTP_ENVOYE', canal: 'SMS', telephoneMasque: '+221 77 *** ** 67', otpValiditeSecondes: 300 });
    expect(navigation).toHaveBeenCalledWith('/auth/verification');
    expect(TestBed.inject(SessionService).verification()).toMatchObject({ identifiant: '+221771234567', mode: 'telephone' });
  });

  it('affiche sous le champ un numéro refusé par le serveur', () => {
    const { el, saisir, continuer, fixture } = creer();
    saisir('771234567');
    continuer();
    backend.expectOne(`${api}/auth/telephone/code`).flush(
      { detail: 'Seuls les numéros sénégalais (+221) sont acceptés', champ: 'telephone' },
      { status: 400, statusText: 'Bad Request' },
    );
    fixture.detectChanges();
    expect(el.querySelector('#erreur-telephone')?.textContent).toContain('sénégalais');
  });
});

describe('SessionService : parcours par téléphone', () => {
  const api = environment.apiUrl;
  let backend: HttpTestingController;
  let session: SessionService;

  beforeEach(() => {
    sessionStorage.clear();
    TestBed.configureTestingModule({
      providers: [provideRouter([]), provideHttpClient(), provideHttpClientTesting()],
    });
    backend = TestBed.inject(HttpTestingController);
    session = TestBed.inject(SessionService);
    session.codeTelephone('+221771234567').subscribe();
    backend.expectOne(`${api}/auth/telephone/code`).flush({ etape: 'OTP_ENVOYE', canal: 'SMS' });
  });

  afterEach(() => backend.verify());

  it('numéro inconnu : le code donne un jeton, puis le compte est créé avec ce jeton', () => {
    session.verifierOtp('123456').subscribe();
    const verif = backend.expectOne(`${api}/auth/telephone/verifier`);
    expect(verif.request.body).toEqual({ telephone: '+221771234567', code: '123456' });
    verif.flush({ etape: 'PROFIL_REQUIS', jetonInscription: 'jeton-15-min' });
    expect(session.verification()).toBeNull();
    expect(session.jetonInscription).toBe('jeton-15-min');

    session.terminerInscriptionTelephone({ prenom: 'Awa', nom: 'Diop', sexe: 'FEMME' }).subscribe();
    const fin = backend.expectOne(`${api}/auth/telephone/terminer`);
    expect(fin.request.body).toEqual({ jeton: 'jeton-15-min', prenom: 'Awa', nom: 'Diop', sexe: 'FEMME' });
    fin.flush({ etape: 'CONNECTE', accessToken: 'a', refreshToken: 'r', utilisateur: { id: 1, role: 'PASSAGER' } });
    expect(session.estConnecte()).toBe(true);
    expect(session.jetonInscription).toBeNull();
  });

  it('numéro déjà connu : le code connecte directement', () => {
    session.verifierOtp('123456').subscribe();
    backend.expectOne(`${api}/auth/telephone/verifier`)
      .flush({ etape: 'CONNECTE', accessToken: 'a', refreshToken: 'r', utilisateur: { id: 2, role: 'PASSAGER' } });
    expect(session.estConnecte()).toBe(true);
    expect(session.jetonInscription).toBeNull();
  });

  it('renvoie le code par le même chemin (SMS au numéro)', () => {
    session.renvoyerOtp().subscribe();
    expect(backend.expectOne(`${api}/auth/telephone/code`).request.body).toEqual({ telephone: '+221771234567' });
  });
});
