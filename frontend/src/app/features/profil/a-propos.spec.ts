import { provideHttpClient } from '@angular/common/http';
import { HttpTestingController, provideHttpClientTesting } from '@angular/common/http/testing';
import { ComponentRef } from '@angular/core';
import { TestBed } from '@angular/core/testing';
import { provideRouter } from '@angular/router';
import { Profil } from '../../core/auth/auth.models';
import { APropos } from './a-propos';

describe('Mon profil : prénom et nom en lettres seulement', () => {
  function ouvrir(prenom = 'Awa', nom = 'Diop') {
    sessionStorage.clear();
    TestBed.configureTestingModule({ providers: [provideRouter([]), provideHttpClient(), provideHttpClientTesting()] });
    const fixture = TestBed.createComponent(APropos);
    (fixture.componentRef as ComponentRef<APropos>).setInput('profil', { prenom, nom, bio: null, sexe: null } as unknown as Profil);
    fixture.detectChanges();
    const el = fixture.nativeElement as HTMLElement;
    el.querySelector<HTMLButtonElement>('button[aria-label="Modifier mes informations"]')!.click();
    fixture.detectChanges();
    const saisir = (id: string, valeur: string) => {
      const input = el.querySelector<HTMLInputElement>(`#${id}`)!;
      input.value = valeur;
      input.dispatchEvent(new Event('input'));
      fixture.detectChanges();
    };
    const enregistrer = () => {
      el.querySelector('form')!.dispatchEvent(new Event('submit', { cancelable: true }));
      fixture.detectChanges();
    };
    return { el, saisir, enregistrer, backend: TestBed.inject(HttpTestingController) };
  }

  it('retire les chiffres et symboles à la frappe, garde les noms composés', () => {
    const { el, saisir, backend } = ouvrir();
    saisir('prenom', 'Awa123');
    saisir('nom', '@Diop!');
    expect(el.querySelector<HTMLInputElement>('#prenom')!.value).toBe('Awa');
    expect(el.querySelector<HTMLInputElement>('#nom')!.value).toBe('Diop');
    saisir('prenom', 'Marie-Claire');
    saisir('nom', "N'Diaye");
    expect(el.querySelector<HTMLInputElement>('#prenom')!.value).toBe('Marie-Claire');
    expect(el.querySelector<HTMLInputElement>('#nom')!.value).toBe("N'Diaye");
    backend.verify();
  });

  it("refuse l'enregistrement d'un ancien nom contenant un chiffre, avec un message", () => {
    const { el, enregistrer, backend } = ouvrir('Awa2', 'Diop');
    enregistrer();
    expect(el.querySelector('.message-erreur')?.textContent).toContain('Lettres uniquement');
    backend.expectNone(() => true);
    backend.verify();
  });
});
