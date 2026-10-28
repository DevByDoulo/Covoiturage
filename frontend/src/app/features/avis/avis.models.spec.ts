import { Reputation, pourcentage } from './avis.models';

function reputation(repartition: number[]): Reputation {
  return {
    idUtilisateur: 1,
    noteMoyenne: null,
    nombreAvis: repartition.reduce((t, n) => t + n, 0),
    repartition,
    avis: [],
  };
}

describe('Avis : répartition des notes', () => {
  it('donne la part de chaque note en pourcentage arrondi', () => {
    const r = reputation([0, 1, 0, 1, 2]); // 4 avis : un à 2★, un à 4★, deux à 5★
    expect(pourcentage(r, 5)).toBe(50);
    expect(pourcentage(r, 4)).toBe(25);
    expect(pourcentage(r, 1)).toBe(0);
  });

  it('renvoie 0 sans aucun avis', () => {
    expect(pourcentage(reputation([0, 0, 0, 0, 0]), 5)).toBe(0);
  });
});
