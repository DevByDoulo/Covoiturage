import { FormControl, FormGroup } from '@angular/forms';
import {
  REGLE_NOM_PROPRE,
  appliquerErreurServeur,
  champsIdentiques,
  chiffresTelephone,
  lettresSeulement,
  retourSur,
  telephoneSenegalValidator,
} from './formulaire';
import { forceMotDePasse } from '../../shared/ui/force-mot-de-passe';

describe('formulaire', () => {
  it('normalise les numéros sénégalais', () => {
    expect(chiffresTelephone('77 123 45 67')).toBe('771234567');
    expect(chiffresTelephone('+221 77 123 45 67')).toBe('771234567');
    expect(chiffresTelephone('00221771234567')).toBe('771234567');
  });

  it('valide le format du téléphone', () => {
    expect(telephoneSenegalValidator(new FormControl('77 123 45 67'))).toBeNull();
    expect(telephoneSenegalValidator(new FormControl('33 821 00 00'))).toBeNull();
    expect(telephoneSenegalValidator(new FormControl('12 345 67'))).toEqual({ telephone: true });
  });

  it('détecte des mots de passe différents', () => {
    const g = new FormGroup({ a: new FormControl('Abcdef12'), b: new FormControl('Abcdef13') }, champsIdentiques('a', 'b'));
    expect(g.hasError('differents')).toBe(true);
    g.controls.b.setValue('Abcdef12');
    expect(g.hasError('differents')).toBe(false);
  });

  it("reporte l'erreur serveur sur le champ concerné", () => {
    const g = new FormGroup({ email: new FormControl('a@b.sn') });
    expect(appliquerErreurServeur(g, { status: 409, message: 'Cet email est déjà utilisé', champ: 'email' })).toBe(true);
    expect(g.controls.email.errors).toEqual({ serveur: 'Cet email est déjà utilisé' });
    expect(appliquerErreurServeur(g, { status: 500, message: 'Erreur' })).toBe(false);
  });

  it("n'accepte que des URL de retour internes", () => {
    expect(retourSur('/accueil')).toBe('/accueil');
    expect(retourSur('//evil.com')).toBeNull();
    expect(retourSur('https://evil.com')).toBeNull();
  });

  it('évalue la force du mot de passe', () => {
    expect(forceMotDePasse('')).toBe(0);
    expect(forceMotDePasse('abcdefgh')).toBe(1);
    expect(forceMotDePasse('abcdefg1')).toBe(2);
    expect(forceMotDePasse('Abcdefgh12!x')).toBe(3);
  });

  it('prénom et nom : lettres (accents compris), espaces, tirets et apostrophes seulement', () => {
    for (const ok of ['Awa', 'Éloïse', 'Marie-Claire', "N'Diaye", 'N’Diaye', 'Ba Fall', 'Çelik', ' Awa '])
      expect(REGLE_NOM_PROPRE.test(ok), ok).toBe(true);
    for (const ko of ['Awa2', '123', 'Awa!', '@Diop', '-Awa', '  ', 'Awa_Diop', 'Awa.D', ''])
      expect(REGLE_NOM_PROPRE.test(ko), ko).toBe(false);
  });

  it("retire à la saisie ce qui n'est pas une lettre", () => {
    expect(lettresSeulement('Awa123')).toBe('Awa');
    expect(lettresSeulement('@Diop!#')).toBe('Diop');
    expect(lettresSeulement("Marie-Claire N'Diaye")).toBe("Marie-Claire N'Diaye");
    expect(lettresSeulement('Éloïse_7')).toBe('Éloïse');
  });
});
