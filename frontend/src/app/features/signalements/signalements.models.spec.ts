import { LIBELLES_MOTIF, MOTIFS, descriptionObligatoire, estOuvert } from './signalements.models';

describe('Signalements : règles côté interface', () => {
  it('propose un libellé pour chaque motif', () => {
    expect(MOTIFS.length).toBe(7);
    for (const m of MOTIFS) expect(LIBELLES_MOTIF[m]).toBeTruthy();
  });

  it('exige une description seulement pour le motif « Autre »', () => {
    expect(descriptionObligatoire('AUTRE')).toBe(true);
    expect(descriptionObligatoire('HARCELEMENT')).toBe(false);
    expect(descriptionObligatoire(null)).toBe(false);
  });

  it('considère ouverts les signalements en attente ou en cours', () => {
    expect(estOuvert('EN_ATTENTE')).toBe(true);
    expect(estOuvert('EN_COURS')).toBe(true);
    expect(estOuvert('TRAITE')).toBe(false);
    expect(estOuvert('REJETE')).toBe(false);
  });
});
