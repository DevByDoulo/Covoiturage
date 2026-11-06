import { Guide } from './guide';
import { EtapeOsrm, Itineraire, distanceAuTraceM, distanceParlee, etapesAnnoncees, instructionFr } from './itineraire';

/** Décale un point de [m] mètres vers le nord (1° de latitude ≈ 111,2 km). */
const nord = (p: { latitude: number; longitude: number }, m: number) => ({ ...p, latitude: p.latitude + m / 111_195 });
/** Décale un point de [m] mètres vers l'est (à la latitude de Dakar). */
const est = (p: { latitude: number; longitude: number }, m: number) => ({
  ...p,
  longitude: p.longitude + m / (111_195 * Math.cos((p.latitude * Math.PI) / 180)),
});

const etape = (type: string, modifier: string | undefined, name: string, distance: number, lng: number, lat: number, exit?: number): EtapeOsrm => ({
  name,
  distance,
  maneuver: { type, modifier, exit, location: [lng, lat] },
});

describe('Itinéraire : consignes en français', () => {
  it('traduit les manœuvres OSRM', () => {
    expect(instructionFr(etape('turn', 'left', 'Rue 14', 0, 0, 0))).toBe('Tournez à gauche sur Rue 14');
    expect(instructionFr(etape('turn', 'slight right', '', 0, 0, 0))).toBe('Serrez à droite');
    expect(instructionFr(etape('roundabout', 'right', 'Avenue Lamine Gueye', 0, 0, 0, 2))).toBe(
      'Au rond-point, prenez la deuxième sortie sur Avenue Lamine Gueye',
    );
    expect(instructionFr(etape('arrive', undefined, '', 0, 0, 0))).toBe('Vous êtes arrivé au point de rendez-vous');
    expect(instructionFr(etape('new name', 'straight', 'Corniche', 0, 0, 0))).toBe('Continuez sur Corniche');
  });

  it("n'annonce pas les sorties de rond-point, mais garde leur longueur", () => {
    const etapes = etapesAnnoncees([
      etape('depart', undefined, '', 100, 0, 0),
      etape('roundabout', 'right', '', 10, 0, 0.001, 1),
      etape('exit roundabout', 'right', '', 50, 0, 0.0011, 1),
      etape('arrive', undefined, '', 0, 0, 0.002),
    ]);
    expect(etapes.map((e) => e.instruction)).toEqual([
      'Partez',
      'Au rond-point, prenez la première sortie',
      'Vous êtes arrivé au point de rendez-vous',
    ]);
    expect(etapes[1].distanceM).toBe(60);
  });

  it('dit les distances comme on les prononce', () => {
    expect(distanceParlee(287)).toBe('300 mètres');
    expect(distanceParlee(42)).toBe('40 mètres');
    expect(distanceParlee(1240)).toBe('1,2 kilomètre');
    expect(distanceParlee(3964)).toBe('4 kilomètres');
  });
});

describe('Guide : guidage pas à pas', () => {
  // Itinéraire en L : 400 m vers le nord, puis 200 m vers l'est jusqu'au point de rendez-vous.
  const a = { latitude: 14.69, longitude: -17.44 };
  const virage = nord(a, 400);
  const fin = est(virage, 200);
  const itineraire: Itineraire = {
    distanceM: 600,
    dureeS: 120,
    trace: [a, virage, fin],
    etapes: etapesAnnoncees([
      etape('depart', undefined, 'Rue 10', 400, a.longitude, a.latitude),
      etape('turn', 'right', 'Rue 14', 200, virage.longitude, virage.latitude),
      etape('arrive', undefined, '', 0, fin.longitude, fin.latitude),
    ]),
  };

  it('annonce le virage à l’avance puis au moment de tourner, puis l’arrivée', () => {
    const guide = new Guide(itineraire, 'voiture');
    expect(guide.annonceDepart()).toBe('Itinéraire calculé : 600 mètres, environ 2 minutes. Partez sur Rue 10.');

    expect(guide.avancer(a).annonces).toEqual([]); // 400 m du virage : trop tôt
    expect(guide.avancer(nord(a, 150)).annonces).toEqual(['Dans 250 mètres, tournez à droite sur Rue 14.']);
    expect(guide.avancer(nord(a, 200)).annonces).toEqual([]); // déjà annoncé
    expect(guide.avancer(nord(a, 360)).annonces).toEqual(['Tournez à droite sur Rue 14.']);

    const apresVirage = guide.avancer(est(virage, 40));
    expect(apresVirage.prochaine?.arrivee).toBe(true);
    expect(apresVirage.distanceRestanteM).toBeCloseTo(160, -1);

    const arrivee = guide.avancer(est(virage, 190));
    expect(arrivee.annonces).toEqual(['Vous êtes arrivé au point de rendez-vous.']);
    expect(arrivee.arrive).toBe(true);
    expect(guide.avancer(fin).annonces).toEqual([]); // plus rien après l'arrivée
  });

  it('enchaîne les virages rapprochés sans les répéter, et annonce l’arrivée une seule fois', () => {
    // 200 m vers le nord, puis trois virages à 10 m d'intervalle, puis 100 m jusqu'à l'arrivée.
    const v1 = nord(a, 200);
    const v2 = est(v1, 10);
    const v3 = nord(v2, 10);
    const arrivee = est(v3, 100);
    const guide = new Guide(
      {
        distanceM: 320,
        dureeS: 240,
        trace: [a, v1, v2, v3, arrivee],
        etapes: etapesAnnoncees([
          etape('depart', undefined, '', 200, a.longitude, a.latitude),
          etape('turn', 'right', '', 10, v1.longitude, v1.latitude),
          etape('turn', 'left', '', 10, v2.longitude, v2.latitude),
          etape('turn', 'right', '', 100, v3.longitude, v3.latitude),
          etape('arrive', undefined, '', 0, arrivee.longitude, arrivee.latitude),
        ]),
      },
      'pied',
    );
    const dites: string[] = [];
    for (const p of [nord(a, 120), nord(a, 180), v1, v2, v3, est(v3, 30), est(v3, 85), arrivee, est(arrivee, 5)]) {
      dites.push(...guide.avancer(p).annonces);
    }
    expect(dites).toEqual([
      'Dans 80 mètres, tournez à droite.',
      'Tournez à droite, puis tournez à gauche.',
      'Tournez à droite.',
      'Le point de rendez-vous est à 100 mètres.',
      'Vous êtes arrivé au point de rendez-vous.',
    ]);
  });

  it('demande un recalcul après plusieurs positions loin du tracé', () => {
    const guide = new Guide(itineraire, 'pied');
    const ailleurs = est(nord(a, 100), 150); // 150 m à l'est du tracé
    expect(distanceAuTraceM(ailleurs, itineraire.trace)).toBeGreaterThan(140);
    expect(guide.avancer(ailleurs).horsRoute).toBe(false);
    expect(guide.avancer(ailleurs).horsRoute).toBe(false);
    expect(guide.avancer(ailleurs).horsRoute).toBe(true);
    expect(guide.avancer(nord(a, 100)).horsRoute).toBe(false); // revenu sur le tracé
  });
});
