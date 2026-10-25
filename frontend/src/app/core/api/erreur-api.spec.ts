import { HttpErrorResponse } from '@angular/common/http';
import { lireErreur } from './erreur-api';

describe('lireErreur', () => {
  it('lit un ProblemDetail du backend', () => {
    const e = lireErreur(
      new HttpErrorResponse({
        status: 400,
        error: { detail: 'Code incorrect. Il vous reste 2 tentatives.', tentativesRestantes: 2 },
      }),
    );
    expect(e).toEqual(
      expect.objectContaining({ status: 400, message: 'Code incorrect. Il vous reste 2 tentatives.', tentativesRestantes: 2 }),
    );
  });

  it('signale un serveur injoignable', () => {
    expect(lireErreur(new HttpErrorResponse({ status: 0 })).message).toContain('Impossible de joindre le serveur');
  });

  it('fournit un message par défaut', () => {
    expect(lireErreur(new HttpErrorResponse({ status: 429 })).message).toContain('Trop de tentatives');
  });
});
