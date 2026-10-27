import { formaterTelephone, initiales, urlFichier } from './profil.service';

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
