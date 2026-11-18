import { ITINERAIRES_POPULAIRES, parametresItineraire } from '../public/trajets-populaires';
import { aujourdhui, parametresRecherche } from './parametres-recherche';

describe('paramètres de recherche', () => {
  const dakar = { libelle: 'Dakar', latitude: 14.6937, longitude: -17.4441 };
  const thies = { libelle: 'Thiès', latitude: 14.791, longitude: -16.9359 };

  it("écrit départ, arrivée et date dans l'URL ; 1 passager est la valeur par défaut", () => {
    expect(parametresRecherche(dakar, thies, '2026-11-20', 1)).toEqual({
      de: 'Dakar', dlat: '14.693700', dlng: '-17.444100',
      a: 'Thiès', alat: '14.791000', alng: '-16.935900',
      date: '2026-11-20', places: null,
    });
    expect(parametresRecherche(dakar, thies, '2026-11-20', 3).places).toBe(3);
  });

  it("prend la date du jour si aucune n'est donnée", () => {
    expect(parametresRecherche(dakar, thies, '', 1).date).toBe(aujourdhui());
  });

  it('un trajet populaire lance la recherche du jour pour un passager', () => {
    expect(ITINERAIRES_POPULAIRES.length).toBeGreaterThanOrEqual(5);
    const p = parametresItineraire(ITINERAIRES_POPULAIRES[0], '2026-11-20');
    expect(p).toMatchObject({ de: 'Dakar', a: 'Thiès', date: '2026-11-20', places: null });
  });
});
