import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:yobalema/core/guide.dart';
import 'package:yobalema/core/itineraire.dart';

/// Décale un point de [m] mètres vers le nord / vers l'est (à la latitude de Dakar).
Coord nord(Coord p, double m) => (latitude: p.latitude + m / 111195, longitude: p.longitude);
Coord est(Coord p, double m) =>
    (latitude: p.latitude, longitude: p.longitude + m / (111195 * math.cos(p.latitude * math.pi / 180)));

Map<String, dynamic> etape(String type, String? modifier, String nom, double distance, Coord lieu, [int? sortie]) => {
      'name': nom,
      'distance': distance,
      'maneuver': {
        'type': type,
        'modifier': ?modifier,
        'exit': ?sortie,
        'location': [lieu.longitude, lieu.latitude],
      },
    };

void main() {
  const a = (latitude: 14.69, longitude: -17.44);

  group('consignes en français', () {
    test('traduit les manœuvres OSRM', () {
      expect(instructionFr(etape('turn', 'left', 'Rue 14', 0, a)), 'Tournez à gauche sur Rue 14');
      expect(instructionFr(etape('turn', 'slight right', '', 0, a)), 'Serrez à droite');
      expect(instructionFr(etape('roundabout', 'right', 'Avenue Lamine Gueye', 0, a, 2)),
          'Au rond-point, prenez la deuxième sortie sur Avenue Lamine Gueye');
      expect(instructionFr(etape('arrive', null, '', 0, a)), 'Vous êtes arrivé au point de rendez-vous');
    });

    test('distances parlées et écrites', () {
      expect(distanceParlee(287), '300 mètres');
      expect(distanceParlee(42), '40 mètres');
      expect(distanceParlee(1240), '1,2 kilomètre');
      expect(distanceParlee(3964), '4 kilomètres');
      expect(distanceAffichee(2712), '2,7 km');
    });

    test("lit une réponse OSRM et regroupe la sortie de rond-point", () {
      final it = lireReponseOsrm({
        'code': 'Ok',
        'routes': [
          {
            'distance': 160.0,
            'duration': 40.0,
            'geometry': '_p~iF~ps|U_ulLnnqC',
            'legs': [
              {
                'steps': [
                  etape('depart', null, '', 100, a),
                  etape('roundabout', 'right', '', 10, nord(a, 100), 1),
                  etape('exit roundabout', 'right', '', 50, nord(a, 110), 1),
                  etape('arrive', null, '', 0, nord(a, 160)),
                ],
              },
            ],
          },
        ],
      });
      expect(it.etapes.map((e) => e.instruction),
          ['Partez', 'Au rond-point, prenez la première sortie', 'Vous êtes arrivé au point de rendez-vous']);
      expect(it.etapes[1].distanceM, 60);
      expect(it.trace, hasLength(2));
    });
  });

  group('guidage pas à pas', () {
    // Itinéraire en L : 400 m vers le nord, puis 200 m vers l'est.
    final virage = nord(a, 400);
    final fin = est(virage, 200);
    Itineraire itineraireL() => Itineraire(600, 120, [a, virage, fin], etapesAnnoncees([
          etape('depart', null, 'Rue 10', 400, a),
          etape('turn', 'right', 'Rue 14', 200, virage),
          etape('arrive', null, '', 0, fin),
        ]));

    test('annonce à l’avance, au virage, puis l’arrivée une seule fois', () {
      final guide = Guide(itineraireL(), ModeDeplacement.voiture);
      expect(guide.annonceDepart(), 'Itinéraire calculé : 600 mètres, environ 2 minutes. Partez sur Rue 10.');
      expect(guide.avancer(a).annonces, isEmpty);
      expect(guide.avancer(nord(a, 150)).annonces, ['Dans 250 mètres, tournez à droite sur Rue 14.']);
      expect(guide.avancer(nord(a, 200)).annonces, isEmpty);
      expect(guide.avancer(nord(a, 360)).annonces, ['Tournez à droite sur Rue 14.']);
      final apres = guide.avancer(est(virage, 40));
      expect(apres.prochaine?.arrivee, isTrue);
      final arrivee = guide.avancer(est(virage, 190));
      expect(arrivee.annonces, ['Vous êtes arrivé au point de rendez-vous.']);
      expect(arrivee.arrive, isTrue);
      expect(guide.avancer(fin).annonces, isEmpty);
    });

    test('enchaîne les virages rapprochés sans les répéter', () {
      final v1 = nord(a, 200), v2 = est(v1, 10), v3 = nord(v2, 10), arrivee = est(v3, 100);
      final guide = Guide(
          Itineraire(320, 240, [a, v1, v2, v3, arrivee], etapesAnnoncees([
            etape('depart', null, '', 200, a),
            etape('turn', 'right', '', 10, v1),
            etape('turn', 'left', '', 10, v2),
            etape('turn', 'right', '', 100, v3),
            etape('arrive', null, '', 0, arrivee),
          ])),
          ModeDeplacement.pied);
      final dites = <String>[];
      for (final p in [nord(a, 120), nord(a, 180), v1, v2, v3, est(v3, 30), est(v3, 85), arrivee, est(arrivee, 5)]) {
        dites.addAll(guide.avancer(p).annonces);
      }
      expect(dites, [
        'Dans 80 mètres, tournez à droite.',
        'Tournez à droite, puis tournez à gauche.',
        'Tournez à droite.',
        'Le point de rendez-vous est à 100 mètres.',
        'Vous êtes arrivé au point de rendez-vous.',
      ]);
    });

    test('demande un recalcul après plusieurs positions loin du tracé', () {
      final guide = Guide(itineraireL(), ModeDeplacement.pied);
      final ailleurs = est(nord(a, 100), 150);
      expect(guide.avancer(ailleurs).horsRoute, isFalse);
      expect(guide.avancer(ailleurs).horsRoute, isFalse);
      expect(guide.avancer(ailleurs).horsRoute, isTrue);
      expect(guide.avancer(nord(a, 100)).horsRoute, isFalse);
    });
  });
}
