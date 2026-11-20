import { provideHttpClient } from '@angular/common/http';
import { HttpTestingController, provideHttpClientTesting } from '@angular/common/http/testing';
import { ComponentRef } from '@angular/core';
import { TestBed } from '@angular/core/testing';
import { Router, provideRouter } from '@angular/router';
import { environment } from '../../../../environments/environment';
import { Inscription, Parcours } from './inscription';

describe('Création du compte en étapes (Inscription)', () => {
  const api = environment.apiUrl;
  let backend: HttpTestingController;
  let router: Router;

  function creer(parcours: Parcours, jeton: string | null = 'jeton-inscription') {
    sessionStorage.clear();
    if (jeton) sessionStorage.setItem('covoitia.inscription', jeton);
    TestBed.configureTestingModule({
      providers: [provideRouter([{ path: '**', children: [] }]), provideHttpClient(), provideHttpClientTesting()],
    });
    backend = TestBed.inject(HttpTestingController);
    router = TestBed.inject(Router);
    const navigation = vi.spyOn(router, 'navigateByUrl');
    const navigationAvecParametres = vi.spyOn(router, 'navigate');
    const fixture = TestBed.createComponent(Inscription);
    (fixture.componentRef as ComponentRef<Inscription>).setInput('parcours', parcours);
    fixture.detectChanges();
    const el = fixture.nativeElement as HTMLElement;
    const saisir = (id: string, valeur: string) => {
      const input = el.querySelector<HTMLInputElement>(`#${id}`)!;
      input.value = valeur;
      input.dispatchEvent(new Event('input'));
      fixture.detectChanges();
    };
    const continuer = () => {
      el.querySelector('form')!.dispatchEvent(new Event('submit', { cancelable: true }));
      fixture.detectChanges();
    };
    const cliquer = (texte: string) => {
      [...el.querySelectorAll('button')].find((b) => b.textContent!.includes(texte))!.click();
      fixture.detectChanges();
    };
    const etape = () => el.querySelector('.etape')?.textContent?.trim();
    const titre = () => el.querySelector('h1')?.textContent?.trim();
    return { fixture, el, saisir, continuer, cliquer, etape, titre, navigation, navigationAvecParametres };
  }

  afterEach(() => backend.verify());

  it('parcours téléphone sans jeton : retour au numéro', () => {
    const { navigation } = creer('telephone', null);
    expect(navigation).toHaveBeenCalledWith('/auth/inscription-telephone');
  });

  it('parcours e-mail : la 1re étape propose Google puis « Autres options » vers le numéro', () => {
    const { el, titre, etape } = creer('email');
    expect(etape()).toBe('Étape 1 sur 6');
    expect(titre()).toContain('adresse e-mail');
    const ordre = [...el.querySelectorAll('#email, #motDePasse, .separateur, app-bouton-google, .autres-options')].map(
      (n) => n.id || n.className || n.tagName.toLowerCase(),
    );
    expect(ordre).toEqual(['email', 'motDePasse', 'separateur', 'app-bouton-google', 'autres-options']);
    expect(el.querySelector('.autres-options')?.getAttribute('href')).toBe('/auth/inscription-telephone');
    expect(el.querySelector('.autres-options')?.textContent).toContain('numéro + code SMS');
  });

  it('parcours e-mail : la confirmation doit être identique au mot de passe', () => {
    const { el, saisir, continuer, etape } = creer('email');
    saisir('email', 'awa@test.sn');
    saisir('motDePasse', 'Teranga2026');
    continuer();
    // Confirmation vide : on reste sur l'étape, avec le message.
    expect(etape()).toBe('Étape 1 sur 6');
    expect(el.querySelector('#erreur-confirmation')?.textContent).toContain('ne correspondent pas');
    saisir('confirmation', 'Teranga2027');
    continuer();
    expect(etape()).toBe('Étape 1 sur 6');
    expect(el.querySelector('#erreur-confirmation')).not.toBeNull();
    saisir('confirmation', 'Teranga2026');
    expect(el.querySelector('#erreur-confirmation')).toBeNull();
    continuer();
    expect(etape()).toBe('Étape 2 sur 6');
  });

  it('prénom et nom : les caractères qui ne sont pas des lettres sont retirés à la saisie', () => {
    const { el, saisir, continuer, etape } = creer('telephone');
    saisir('prenom', 'Awa123');
    saisir('nom', '@Diop!');
    expect(el.querySelector<HTMLInputElement>('#prenom')!.value).toBe('Awa');
    expect(el.querySelector<HTMLInputElement>('#nom')!.value).toBe('Diop');
    saisir('prenom', "Marie-Claire");
    saisir('nom', "N'Diaye");
    expect(el.querySelector<HTMLInputElement>('#prenom')!.value).toBe('Marie-Claire');
    expect(el.querySelector<HTMLInputElement>('#nom')!.value).toBe("N'Diaye");
    continuer();
    expect(etape()).toBe('Étape 4 sur 6');
  });

  it('prénom : une valeur sans lettre (espaces, tirets) est refusée avec un message', () => {
    const { el, saisir, continuer, etape } = creer('telephone');
    saisir('prenom', '---');
    saisir('nom', 'Diop');
    continuer();
    expect(etape()).toBe('Étape 3 sur 6');
    expect(el.querySelector('.message-erreur')?.textContent).toContain('Lettres uniquement');
  });

  it('parcours téléphone : un mot de passe saisi doit être confirmé ; « Passer » reste possible', () => {
    const { el, saisir, continuer, cliquer, etape, titre } = creer('telephone');
    saisir('prenom', 'Awa');
    saisir('nom', 'Diop');
    continuer();
    cliquer('Une femme');
    continuer();
    expect(titre()).toContain('mot de passe');
    // Champs vides : le mot de passe est facultatif, on peut continuer sans confirmation.
    saisir('motDePasse', 'Teranga2026');
    continuer();
    expect(titre()).toContain('mot de passe');
    expect(el.querySelector('#erreur-confirmation')).not.toBeNull();
    saisir('confirmation', 'Teranga2026');
    continuer();
    expect(etape()).toBe('Étape 6 sur 6');
  });

  it("parcours e-mail : Google et « Autres options » disparaissent après la 1re étape", () => {
    const { el, saisir, continuer } = creer('email');
    saisir('email', 'awa@exemple.sn');
    saisir('motDePasse', 'Motdepasse1');
    saisir('confirmation', 'Motdepasse1');
    continuer();
    expect(el.querySelector('app-connexion-sociale')).toBeNull();
    expect(el.querySelector('.autres-options')).toBeNull();
  });

  it("parcours téléphone : pas de Google ni d'« Autres options » (le numéro est déjà vérifié)", () => {
    const { el } = creer('telephone');
    expect(el.querySelector('app-connexion-sociale')).toBeNull();
    expect(el.querySelector('.autres-options')).toBeNull();
  });

  it('parcours téléphone : nom, sexe, mot de passe passé, conditions, puis compte créé et connecté', () => {
    const { el, saisir, continuer, cliquer, etape, titre } = creer('telephone');
    expect(etape()).toBe('Étape 3 sur 6');
    continuer();
    expect(etape()).toBe('Étape 3 sur 6');
    saisir('prenom', 'Awa');
    saisir('nom', 'Diop');
    continuer();
    expect(titre()).toBe('Vous êtes…');
    cliquer('Une femme');
    continuer();
    expect(titre()).toContain('mot de passe');
    saisir('motDePasse', 'court');
    continuer();
    expect(titre()).toContain('mot de passe');
    cliquer('Passer');
    expect(etape()).toBe('Étape 6 sur 6');
    // Conditions non acceptées : rien n'est envoyé.
    continuer();
    expect(etape()).toBe('Étape 6 sur 6');
    expect(el.querySelector('.message-erreur')?.textContent).toContain('Cochez la case');
  });

  it('parcours téléphone : envoie le jeton et les informations (sans mot de passe si passé)', () => {
    const { el, saisir, continuer, cliquer, navigation, fixture } = creer('telephone');
    saisir('prenom', ' Awa ');
    saisir('nom', 'Diop');
    continuer();
    cliquer('Une femme');
    continuer();
    cliquer('Passer');
    el.querySelector<HTMLInputElement>('input[type=checkbox]')!.click();
    fixture.detectChanges();
    continuer();
    const req = backend.expectOne(`${api}/auth/telephone/terminer`);
    expect(req.request.body).toEqual({ jeton: 'jeton-inscription', prenom: 'Awa', nom: 'Diop', sexe: 'FEMME' });
    req.flush({ etape: 'CONNECTE', accessToken: 'a', refreshToken: 'r', utilisateur: { id: 1, role: 'PASSAGER' } });
    expect(navigation).toHaveBeenCalledWith('/accueil');
  });

  it("parcours e-mail : un e-mail déjà utilisé ramène à sa première étape avec le message", () => {
    const { el, saisir, continuer, cliquer, etape, navigationAvecParametres, fixture } = creer('email', null);
    expect(etape()).toBe('Étape 1 sur 6');
    saisir('email', 'awa@test.sn');
    continuer();
    expect(etape()).toBe('Étape 1 sur 6');
    saisir('motDePasse', 'Teranga2026');
    saisir('confirmation', 'Teranga2026');
    continuer();
    saisir('prenom', 'Awa');
    saisir('nom', 'Diop');
    continuer();
    saisir('telephone', '77 123 45 67');
    continuer();
    cliquer('Une femme');
    continuer();
    el.querySelector<HTMLInputElement>('input[type=checkbox]')!.click();
    fixture.detectChanges();
    continuer();
    const req = backend.expectOne(`${api}/auth/inscription`);
    expect(req.request.body).toMatchObject({ email: 'awa@test.sn', telephone: '+221771234567', motDePasse: 'Teranga2026' });
    req.flush({ detail: 'Cet email est déjà utilisé', champ: 'email' }, { status: 409, statusText: 'Conflict' });
    fixture.detectChanges();
    expect(etape()).toBe('Étape 1 sur 6');
    expect(el.querySelector('.message-erreur')?.textContent).toContain('déjà utilisé');
    expect(navigationAvecParametres).not.toHaveBeenCalled();
  });
});
