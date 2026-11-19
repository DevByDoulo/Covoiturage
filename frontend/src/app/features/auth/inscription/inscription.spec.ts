import { provideHttpClient } from '@angular/common/http';
import { HttpTestingController, provideHttpClientTesting } from '@angular/common/http/testing';
import { ComponentRef } from '@angular/core';
import { TestBed } from '@angular/core/testing';
import { Router, provideRouter } from '@angular/router';
import { environment } from '../../../../environments/environment';
import { Inscription } from './inscription';

describe('Inscription (Google seulement, étape 1)', () => {
  const api = environment.apiUrl;
  let backend: HttpTestingController;

  function creer(retour?: string) {
    sessionStorage.clear();
    TestBed.configureTestingModule({
      providers: [provideRouter([{ path: '**', children: [] }]), provideHttpClient(), provideHttpClientTesting()],
    });
    backend = TestBed.inject(HttpTestingController);
    const fixture = TestBed.createComponent(Inscription);
    if (retour) (fixture.componentRef as ComponentRef<Inscription>).setInput('retour', retour);
    fixture.detectChanges();
    return { fixture, el: fixture.nativeElement as HTMLElement };
  }

  afterEach(() => backend.verify());

  it("ne propose plus le formulaire e-mail + mot de passe, seulement Google et « J'ai déjà un compte »", () => {
    const { el } = creer();
    expect(el.querySelector('#email, #motDePasse, input[formcontrolname]')).toBeNull();
    expect(el.querySelector('app-bouton-google')).not.toBeNull();
    expect(el.querySelector('.etape')?.textContent).toContain('Étape 1 sur 5');
    expect(el.querySelectorAll('.etapes li').length).toBe(5);
  });

  it("garde le retour prévu vers la connexion et le mémorise pour après l'inscription", () => {
    const { el } = creer('/trajets/11');
    const lien = [...el.querySelectorAll('a')].find((a) => a.textContent!.includes("J'ai déjà un compte"))!;
    expect(lien.getAttribute('href')).toBe('/auth/connexion?retour=%2Ftrajets%2F11');
    expect(sessionStorage.getItem('covoitia.retour')).toBe('/trajets/11');
  });

  it('un nouveau compte Google passe aux étapes suivantes (numéro de téléphone)', () => {
    const { fixture } = creer();
    const navigation = vi.spyOn(TestBed.inject(Router), 'navigateByUrl');
    (fixture.componentInstance as unknown as { google(j: string): void }).google('jeton-google');
    backend.expectOne(`${api}/auth/google`).flush({ etape: 'TELEPHONE_REQUIS' });
    expect(navigation).toHaveBeenCalledWith('/auth/telephone');
  });
});
