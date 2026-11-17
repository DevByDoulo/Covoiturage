import { provideHttpClient } from '@angular/common/http';
import { HttpTestingController, provideHttpClientTesting } from '@angular/common/http/testing';
import { TestBed } from '@angular/core/testing';
import { provideRouter } from '@angular/router';
import { environment } from '../../../environments/environment';
import { SessionService } from '../../core/auth/session.service';
import { ProfilService, formaterTelephone, initiales, urlFichier } from './profil.service';

describe('Mon profil : affichage', () => {
  it('formate un numéro sénégalais par groupes', () => {
    expect(formaterTelephone('+221771234512')).toBe('+221 77 123 45 12');
    expect(formaterTelephone('+33612345678')).toBe('+33612345678');
  });

  it('calcule les initiales (deux au plus)', () => {
    expect(initiales('Ousmane Diop')).toBe('OD');
    expect(initiales('mariama  ba  sow')).toBe('MB');
  });

  it("construit l'adresse complète d'une photo", () => {
    expect(urlFichier('/api/fichiers/photos/a.png')).toBe('http://localhost:8080/api/fichiers/photos/a.png');
    expect(urlFichier(null)).toBeNull();
  });
});

describe('Mon profil : suppression du compte', () => {
  const api = environment.apiUrl;
  let backend: HttpTestingController;
  let session: SessionService;
  let profils: ProfilService;

  beforeEach(() => {
    localStorage.clear();
    sessionStorage.clear();
    TestBed.configureTestingModule({
      providers: [provideRouter([{ path: '**', children: [] }]), provideHttpClient(), provideHttpClientTesting()],
    });
    backend = TestBed.inject(HttpTestingController);
    session = TestBed.inject(SessionService);
    profils = TestBed.inject(ProfilService);
  });

  afterEach(() => backend.verify());

  it('envoie la confirmation puis ferme la session', () => {
    session.connexion('awa@test.sn', 'MotDePasse2026').subscribe();
    backend.expectOne(`${api}/auth/connexion`).flush({
      etape: 'CONNECTE', accessToken: 'jeton', refreshToken: 'refresh', utilisateur: { id: 1, prenom: 'Awa', role: 'PASSAGER' },
    });
    expect(session.utilisateur()).not.toBeNull();

    profils.supprimerCompte('MotDePasse2026', null).subscribe();
    const requete = backend.expectOne(`${api}/moi/suppression`);
    expect(requete.request.method).toBe('POST');
    expect(requete.request.body).toEqual({ motDePasse: 'MotDePasse2026', code: null });
    requete.flush({ dateSuppressionDefinitive: '2026-12-13T10:00:00' });
    expect(session.utilisateur()).toBeNull();
  });

  it('demande le code de confirmation des comptes Google', () => {
    profils.envoyerCodeSuppression().subscribe();
    const requete = backend.expectOne(`${api}/moi/suppression/code`);
    expect(requete.request.method).toBe('POST');
    requete.flush({ etape: 'OTP_ENVOYE', canal: 'EMAIL' });
  });

  it("annonce l'annulation d'une suppression à la reconnexion", () => {
    session.connexion('awa@test.sn', 'MotDePasse2026').subscribe();
    backend.expectOne(`${api}/auth/connexion`).flush({
      etape: 'CONNECTE', accessToken: 'jeton', refreshToken: 'refresh', suppressionAnnulee: true,
      utilisateur: { id: 1, prenom: 'Awa', role: 'PASSAGER' },
    });
    expect(session.suppressionAnnulee()).toBe(true);
  });
});
