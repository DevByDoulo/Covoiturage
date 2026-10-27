import { decoderPolyline } from './polyline';
import { DureePipe, FcfaPipe } from '../format/formats';

describe('decoderPolyline', () => {
  it("décode l'exemple de la documentation Google", () => {
    const points = decoderPolyline('_p~iF~ps|U_ulLnnqC_mqNvxq`@');
    expect(points).toHaveLength(3);
    expect(points[0].latitude).toBeCloseTo(38.5, 5);
    expect(points[0].longitude).toBeCloseTo(-120.2, 5);
    expect(points[2].latitude).toBeCloseTo(43.252, 5);
    expect(points[2].longitude).toBeCloseTo(-126.453, 5);
  });

  it('renvoie une liste vide sans tracé', () => {
    expect(decoderPolyline(null)).toEqual([]);
    expect(decoderPolyline('')).toEqual([]);
  });
});

describe('formats', () => {
  it('affiche les montants en FCFA', () => {
    expect(new FcfaPipe().transform(1650).replace(/\s/g, ' ')).toBe('1 650 FCFA');
    expect(new FcfaPipe().transform(null)).toBe('—');
  });

  it('affiche les durées', () => {
    const duree = new DureePipe();
    expect(duree.transform(40)).toBe('40 min');
    expect(duree.transform(75)).toBe('1 h 15');
    expect(duree.transform(120)).toBe('2 h');
  });
});
