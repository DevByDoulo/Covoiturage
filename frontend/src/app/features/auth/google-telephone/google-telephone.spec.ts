import { provideHttpClient } from '@angular/common/http';
import { HttpTestingController, provideHttpClientTesting } from '@angular/common/http/testing';
import { TestBed } from '@angular/core/testing';
import { Router, provideRouter } from '@angular/router';
import { environment } from '../../../../environments/environment';
import { SessionService } from '../../../core/auth/session.service';
import { prenomDuJeton } from '../google-jeton';
import { GoogleTelephone } from './google-telephone';

/** idToken factice (non signé) dont la charge utile contient le prénom donné. */
function jeton(prenom?: string): string {
  const charge = btoa(String.fromCharCode(...new TextEncoder().encode(JSON.stringify({ sub: '1', given_name: prenom }))))
    .replace(/\+/g, '-').replace(/\//g, '_').replace(/=+$/, '');
  return `entete.${charge}.signature`;
}

describe('prenomDuJeton', () => {
  it("lit le prénom de l'idToken Google, accents compris", () => {
    expect(prenomDuJeton(jeton('Aïssatou'))).toBe('Aïssatou');
  });

  it('rend null pour un jeton absent, illisible ou sans prénom', () => {
    expect(prenomDuJeton(null)).toBeNull();
    expect(prenomDuJeton('pas-un-jeton')).toBeNull();
    expect(prenomDuJeton('a.%%%.c')).toBeNull();
    expect(prenomDuJeton(jeton())).toBeNull();
  });
});

describe('Inscription Google en étapes (GoogleTelephone)', () => {
  const api = environment.apiUrl;
  let backend: HttpTestingController;
  let session: SessionService;
  let router: Router;

  function creer(compte?: SessionService['compteExterne']) {
    TestBed.configureTestingModule({
      providers: [provideRouter([{ path: '**', children: [] }]), provideHttpClient(), provideHttpClientTesting()],
    });
    backend = TestBed.inject(HttpTestingController);
    session = TestBed.inject(SessionService);
    router = TestBed.inject(Router);
    session.compteExterne = compte ?? { fournisseur: 'google', idToken: jeton('Awa') };
    const fixture = TestBed.createComponent(GoogleTelephone);
    fixture.detectChanges();
    const el = fixture.nativeElement as HTMLElement;
    const continuer = () => {
      el.querySelector('form')!.dispatchEvent(new Event('submit', { cancelable: true }));
      fixture.detectChanges();
    };
    const saisir = (valeur: string) => {
      const input = el.querySelector<HTMLInputElement>('#telephone')!;
      input.value = valeur;
      input.dispatchEvent(new Event('input'));
      fixture.detectChanges();
    };
    const bouton = (texte: string) => [...el.querySelectorAll('button')].find((b) => b.textContent!.includes(texte))!;
    const etape = () => el.querySelector('.etape')?.textContent?.trim();
    return { fixture, el, continuer, saisir, bouton, etape };
  }

  beforeEach(() => sessionStorage.clear());
  afterEach(() => backend.verify());

  it("salue la personne et demande d'abord le numéro (étape 2 sur 5)", () => {
    const { el, etape } = creer();
    expect(etape()).toBe('Étape 2 sur 5');
    expect(el.querySelector('h1')?.textContent).toContain('Bienvenue Awa');
    expect(el.querySelector('h1')?.textContent).toContain('numéro de téléphone');
  });

  it("n'avance pas sans un numéro sénégalais valable", () => {
    const { el, continuer, saisir, etape } = creer();
    continuer();
    expect(etape()).toBe('Étape 2 sur 5');
    saisir('12 34');
    continuer();
    expect(etape()).toBe('Étape 2 sur 5');
    expect(el.querySelector('.message-erreur')?.textContent).toContain('9 chiffres');
  });

  it('une question par écran : numéro, sexe, conditions ; « Retour » revient en arrière', () => {
    const { el, continuer, saisir, bouton, etape, fixture } = creer();
    saisir('77 123 45 67');
    continuer();
    expect(etape()).toBe('Étape 3 sur 5');
    continuer();
    expect(etape()).toBe('Étape 3 sur 5');
    expect(el.querySelector('.message-erreur')?.textContent).toContain('Choisissez');
    bouton('Une femme').click();
    continuer();
    expect(etape()).toBe('Étape 4 sur 5');
    bouton('Retour').click();
    fixture.detectChanges();
    expect(etape()).toBe('Étape 3 sur 5');
  });

  it("envoie le numéro et le sexe après acceptation des conditions, puis passe au code", () => {
    const { el, continuer, saisir, bouton } = creer();
    const navigation = vi.spyOn(router, 'navigate');
    saisir('77 123 45 67');
    continuer();
    bouton('Un homme').click();
    continuer();
    continuer();
    expect(el.querySelector('.message-erreur')?.textContent).toContain('Cochez');
    backend.expectNone(`${api}/auth/google`);

    el.querySelector<HTMLInputElement>('input[type=checkbox]')!.click();
    continuer();
    const req = backend.expectOne(`${api}/auth/google`);
    expect(req.request.body).toEqual({ idToken: session.compteExterne!.idToken, telephone: '+221771234567', sexe: 'HOMME' });
    req.flush({ etape: 'OTP_ENVOYE', telephoneMasque: '+22177 ** *** 67', otpValiditeSecondes: 300, renvoiPossibleDansSecondes: 60 });
    expect(navigation).toHaveBeenCalledWith(['/auth/verification'], { queryParams: { inscription: 5 } });
  });

  it("numéro déjà utilisé : retour à l'étape du numéro avec l'erreur sous le champ", () => {
    const { el, continuer, saisir, bouton, fixture, etape } = creer();
    saisir('77 123 45 67');
    continuer();
    bouton('Une femme').click();
    continuer();
    el.querySelector<HTMLInputElement>('input[type=checkbox]')!.click();
    continuer();
    backend.expectOne(`${api}/auth/google`).flush(
      { status: 409, detail: 'Ce numéro est déjà associé à un compte', champ: 'telephone' },
      { status: 409, statusText: 'Conflict' },
    );
    fixture.detectChanges();
    expect(etape()).toBe('Étape 2 sur 5');
    expect(el.querySelector('#erreur-telephone')?.textContent).toContain('déjà associé');
    // Même numéro : on ne repart pas ; un autre numéro efface l'erreur et permet d'avancer.
    continuer();
    expect(etape()).toBe('Étape 2 sur 5');
    saisir('77 765 43 21');
    expect(el.querySelector('#erreur-telephone')).toBeNull();
    continuer();
    expect(etape()).toBe('Étape 3 sur 5');
  });

  it('Apple : salue avec le prénom transmis par Apple et renvoie prénom et nom avec le numéro', () => {
    const { el, continuer, saisir, bouton } = creer({ fournisseur: 'apple', idToken: 'jeton-apple', prenom: 'Fatou', nom: 'Sow' });
    expect(el.querySelector('h1')?.textContent).toContain('Bienvenue Fatou');
    saisir('77 123 45 67');
    continuer();
    bouton('Une femme').click();
    continuer();
    el.querySelector<HTMLInputElement>('input[type=checkbox]')!.click();
    continuer();
    const req = backend.expectOne(`${api}/auth/apple`);
    expect(req.request.body).toEqual({ idToken: 'jeton-apple', prenom: 'Fatou', nom: 'Sow', telephone: '+221771234567', sexe: 'FEMME' });
    req.flush({ etape: 'OTP_ENVOYE', canal: 'EMAIL', emailMasque: 'f***@privaterelay.appleid.com', otpValiditeSecondes: 300, renvoiPossibleDansSecondes: 60 });
  });

  it("sans inscription Google ou Apple en cours, renvoie à l'inscription", () => {
    TestBed.configureTestingModule({
      providers: [provideRouter([{ path: '**', children: [] }]), provideHttpClient(), provideHttpClientTesting()],
    });
    backend = TestBed.inject(HttpTestingController);
    const navigation = vi.spyOn(TestBed.inject(Router), 'navigateByUrl');
    TestBed.createComponent(GoogleTelephone).detectChanges();
    expect(navigation).toHaveBeenCalledWith('/auth/inscription');
  });
});
