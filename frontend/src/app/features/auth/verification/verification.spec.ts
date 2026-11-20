import { provideHttpClient } from '@angular/common/http';
import { HttpTestingController, provideHttpClientTesting } from '@angular/common/http/testing';
import { ComponentRef } from '@angular/core';
import { TestBed } from '@angular/core/testing';
import { provideRouter } from '@angular/router';
import { environment } from '../../../../environments/environment';
import { SessionService } from '../../../core/auth/session.service';
import { Verification } from './verification';

describe('Code de vérification : « Retour »', () => {
  const api = environment.apiUrl;

  function ouvrir(demande: (s: SessionService) => void, entrees: Record<string, unknown> = {}) {
    sessionStorage.clear();
    TestBed.configureTestingModule({ providers: [provideRouter([]), provideHttpClient(), provideHttpClientTesting()] });
    const session = TestBed.inject(SessionService);
    const backend = TestBed.inject(HttpTestingController);
    demande(session);
    backend.expectOne(`${api}/auth/telephone/code`).flush({ etape: 'OTP_ENVOYE', canal: 'SMS' });
    const fixture = TestBed.createComponent(Verification);
    for (const [nom, valeur] of Object.entries(entrees)) (fixture.componentRef as ComponentRef<Verification>).setInput(nom, valeur);
    fixture.detectChanges();
    return { el: fixture.nativeElement as HTMLElement, session, backend };
  }

  const retour = (el: HTMLElement) => el.querySelector('.retour')?.getAttribute('href');

  it("après l'inscription par numéro : retour à /auth/inscription-telephone", () => {
    const { el, backend } = ouvrir((s) => s.codeTelephone('+221771234567', false, true).subscribe());
    expect(retour(el)).toBe('/auth/inscription-telephone');
    backend.verify();
  });

  it('après la connexion par numéro : retour à /auth/connexion-telephone', () => {
    const { el, backend } = ouvrir((s) => s.codeTelephone('+221771234567').subscribe());
    expect(retour(el)).toBe('/auth/connexion-telephone');
    backend.verify();
  });

  it("garde l'origine « inscription » quand le code est renvoyé", () => {
    const { el, session, backend } = ouvrir((s) => s.codeTelephone('+221771234567', false, true).subscribe());
    session.renvoyerOtp().subscribe();
    backend.expectOne(`${api}/auth/telephone/code`).flush({ etape: 'OTP_ENVOYE', canal: 'SMS' });
    expect(session.verification()?.inscription).toBe(true);
    expect(el.querySelector('.retour')).not.toBeNull();
    backend.verify();
  });

  it("code d'une inscription par e-mail ou Google (paramètre inscription) : retour à /auth/inscription", () => {
    const { el, backend } = ouvrir((s) => s.codeTelephone('+221771234567').subscribe(), { inscription: '6' });
    expect(retour(el)).toBe('/auth/inscription');
    backend.verify();
  });
});
