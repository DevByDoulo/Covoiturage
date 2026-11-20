import { provideHttpClient } from '@angular/common/http';
import { HttpTestingController, provideHttpClientTesting } from '@angular/common/http/testing';
import { ComponentRef, Type } from '@angular/core';
import { TestBed } from '@angular/core/testing';
import { provideRouter } from '@angular/router';
import { environment } from '../../../../environments/environment';
import { Entree } from '../entree/entree';
import { Connexion } from './connexion';

/** Crée le composant avec les entrées que le routeur lui donnerait (données de route). */
function creer<T>(composant: Type<T>, entrees: Record<string, unknown> = {}) {
  sessionStorage.clear();
  TestBed.configureTestingModule({
    providers: [provideRouter([{ path: '**', children: [] }]), provideHttpClient(), provideHttpClientTesting()],
  });
  const fixture = TestBed.createComponent(composant);
  for (const [nom, valeur] of Object.entries(entrees)) (fixture.componentRef as ComponentRef<T>).setInput(nom, valeur);
  fixture.detectChanges();
  return { el: fixture.nativeElement as HTMLElement, backend: TestBed.inject(HttpTestingController) };
}

describe('Connexion (/auth/connexion) : e-mail et mot de passe d\'abord, numéro dans « Autres options »', () => {
  it('montre le formulaire, puis « ou continuer avec » Google, puis « Autres options » vers le numéro', () => {
    const { el, backend } = creer(Connexion, { principal: true });
    const ordre = [...el.querySelectorAll('#identifiant, #motDePasse, .separateur, app-bouton-google, .autres-options')]
      .map((n) => n.id || n.className || n.tagName.toLowerCase());
    expect(ordre).toEqual(['identifiant', 'motDePasse', 'separateur', 'app-bouton-google', 'autres-options']);
    expect(el.querySelector('#telephone')).toBeNull();
    expect(el.querySelector('.autres-options')?.getAttribute('href')).toBe('/auth/connexion-telephone');
    expect(el.querySelector('.autres-options')?.textContent).toContain('numéro + code SMS');
    expect(el.querySelector('.retour')).toBeNull();
    expect([...el.querySelectorAll('a')].some((a) => a.getAttribute('href') === '/auth/inscription')).toBe(true);
    backend.verify();
  });

  it('masque Apple tant que la configuration Apple est vide', () => {
    expect(environment.apple.clientId).toBe('');
    const { el } = creer(Connexion, { principal: true });
    expect(el.querySelector('app-bouton-apple')).toBeNull();
  });

  it('garde les messages reçus par l\'adresse (session expirée, compte désactivé…)', () => {
    const { el } = creer(Connexion, { principal: true, expiree: '1' });
    expect(el.textContent).toContain('Votre session a expiré');
  });

  it('« Autres options » de l\'inscription : formulaire avec retour et création par e-mail, sans Google', () => {
    const { el } = creer(Connexion);
    expect(el.querySelector('.retour')?.getAttribute('href')).toBe('/auth/inscription');
    expect(el.querySelector('app-bouton-google')).toBeNull();
    expect(el.textContent).toContain('Créer un compte avec une adresse e-mail');
  });
});

describe('Écran du numéro : « Autres options » selon le parcours', () => {
  it("à l'inscription, mène aux autres options (e-mail et mot de passe)", () => {
    const { el } = creer(Entree, { inscription: true });
    expect(el.querySelector('.autres-options')?.getAttribute('href')).toBe('/auth/autres-options');
  });
});
