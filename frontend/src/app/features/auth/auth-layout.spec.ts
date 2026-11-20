import { Component } from '@angular/core';
import { TestBed } from '@angular/core/testing';
import { provideRouter } from '@angular/router';
import { RouterTestingHarness } from '@angular/router/testing';
import { AuthLayout } from './auth-layout';

describe("Cadre photo des écrans d'authentification (AuthLayout)", () => {
  function creer() {
    TestBed.configureTestingModule({ providers: [provideRouter([])] });
    const fixture = TestBed.createComponent(AuthLayout);
    fixture.detectChanges();
    return fixture;
  }

  it('couvre la page avec une photo WebP chargée en priorité, aux dimensions fixes', () => {
    const el = creer().nativeElement as HTMLElement;
    const img = el.querySelector<HTMLImageElement>('picture img')!;
    expect(img.getAttribute('src')).toBe('fond-connexion.webp');
    expect(img.getAttribute('fetchpriority')).toBe('high');
    expect(img.getAttribute('alt')).toBe('');
    expect(img.getAttribute('width')).toBe('1376');
    expect(img.getAttribute('height')).toBe('768');
    const mobile = el.querySelector('picture source')!;
    expect(mobile.getAttribute('srcset')).toBe('fond-connexion-mobile.webp');
    expect(mobile.getAttribute('type')).toBe('image/webp');
    expect(mobile.getAttribute('media')).toContain('orientation: portrait');
  });

  it("garde le dégradé vert de repli quand la photo n'existe pas", () => {
    const fixture = creer();
    const el = fixture.nativeElement as HTMLElement;
    el.querySelector('picture img')!.dispatchEvent(new Event('error'));
    fixture.detectChanges();
    expect(el.querySelector('picture')).toBeNull();
    expect(el.querySelector('.auth-photo')).not.toBeNull();
    expect(el.querySelector('.auth-photo__voile')).not.toBeNull();
  });

  it("met le formulaire dans un panneau, avec logo, accroche et liens légaux", () => {
    const el = creer().nativeElement as HTMLElement;
    const panneau = el.querySelector('main.auth-panneau')!;
    expect(panneau.querySelector('router-outlet')).not.toBeNull();
    expect(panneau.textContent).toContain("Conditions d'utilisation");
    expect(el.querySelector('.auth-photo__logo')!.getAttribute('aria-label')).toContain('YOBALEMAsn');
    expect(el.querySelector('.auth-photo__accroche')!.textContent).toContain('juste prix');
  });

  describe("carte d'inscription", () => {
    @Component({ template: '<p>écran</p>' })
    class Ecran {}

    async function ouvrir(url: string) {
      TestBed.configureTestingModule({
        providers: [
          provideRouter([
            {
              path: '',
              component: AuthLayout,
              children: [
                { path: 'inscription', data: { carte: true }, component: Ecran },
                { path: 'connexion', data: {}, component: Ecran },
                { path: 'verification', data: {}, component: Ecran },
              ],
            },
          ]),
        ],
      });
      const harness = await RouterTestingHarness.create();
      await harness.navigateByUrl(url);
      harness.detectChanges();
      return harness.routeNativeElement as HTMLElement;
    }

    it("met l'inscription dans une carte, avec le texte d'accueil et « Déjà membre ? »", async () => {
      const el = await ouvrir('/inscription');
      expect(el.querySelector('.auth-photo--carte')).not.toBeNull();
      expect(el.querySelector('.auth-photo__hero')!.textContent).toContain('REJOIGNEZ GRATUITEMENT');
      expect(el.querySelector('.auth-photo__accroche')).toBeNull();
      expect(el.querySelector('.auth-photo__deja a')!.getAttribute('href')).toBe('/auth/connexion');
    });

    it('garde le formulaire sur la photo pour la connexion', async () => {
      const el = await ouvrir('/connexion');
      expect(el.querySelector('.auth-photo--carte')).toBeNull();
      expect(el.querySelector('.auth-photo__accroche')).not.toBeNull();
      expect(el.querySelector('.auth-photo__deja')).toBeNull();
    });

    it("applique la carte au code de vérification d'une inscription seulement", async () => {
      expect((await ouvrir('/verification?inscription=5')).querySelector('.auth-photo--carte')).not.toBeNull();
      TestBed.resetTestingModule();
      expect((await ouvrir('/verification')).querySelector('.auth-photo--carte')).toBeNull();
    });
  });
});
