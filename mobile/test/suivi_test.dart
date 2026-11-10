import 'dart:convert';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:yobalema/core/api.dart';
import 'package:yobalema/core/localisation.dart';
import 'package:yobalema/features/suivi/partage.dart';
import 'package:yobalema/features/suivi/suivi_conducteur.dart';

/// Position à [m] mètres au nord d'un point de Dakar.
PositionSuivie nord(double m) => (latitude: 14.69 + m / 111195, longitude: -17.44, precisionM: 10, cap: null, vitesse: null);

void main() {
  group('partage de position : rythme des envois', () {
    late List<Map<String, dynamic>> envois;
    late PartagePosition partage;
    late DateTime maintenant;

    void preparer(FakeAsync fa) {
      envois = [];
      maintenant = DateTime(2026, 11, 10, 8);
      final api = Api(
        baseUrl: 'http://api.test/api',
        client: MockClient((r) async {
          envois.add(jsonDecode(r.body) as Map<String, dynamic>);
          return http.Response('{}', 200, headers: {'content-type': 'application/json'});
        }),
      );
      partage = PartagePosition(api, PositionActuelle(), horloge: () => maintenant)..idTrajet = 3;
    }

    void attendre(FakeAsync fa, Duration d) {
      maintenant = maintenant.add(d);
      fa.elapse(d);
    }

    test('première position tout de suite, puis au plus toutes les 5 s ; la position en attente part seule', () {
      fakeAsync((fa) {
        preparer(fa);
        partage.recevoir(3, nord(0));
        fa.flushMicrotasks();
        expect(envois, hasLength(1));
        attendre(fa, const Duration(seconds: 2));
        partage.recevoir(3, nord(100));
        fa.flushMicrotasks();
        expect(envois, hasLength(1)); // trop tôt : en attente
        attendre(fa, const Duration(seconds: 3));
        fa.flushMicrotasks();
        expect(envois, hasLength(2)); // envoyée sans nouvelle position du GPS
        expect(envois[1]['latitude'], closeTo(nord(100).latitude, 1e-6));
      });
    });

    test("un petit déplacement n'est envoyé qu'après 20 s", () {
      fakeAsync((fa) {
        preparer(fa);
        partage.recevoir(3, nord(0));
        attendre(fa, const Duration(seconds: 6));
        partage.recevoir(3, nord(5));
        fa.flushMicrotasks();
        expect(envois, hasLength(1));
        attendre(fa, const Duration(seconds: 15));
        partage.recevoir(3, nord(6));
        fa.flushMicrotasks();
        expect(envois, hasLength(2));
      });
    });
  });

  group('annonces du suivi', () {
    test('premier signal, paliers franchis une fois, puis arrivée', () {
      final a = AnnoncesSuivi('Awa');
      expect(a.pour(2700), 'Awa est en route. Awa est à 2,7 kilomètres du point de rendez-vous.');
      expect(a.pour(2400), isNull);
      expect(a.pour(1900), 'Awa est à 1,9 kilomètre du point de rendez-vous.');
      expect(a.pour(700), 'Awa est à 700 mètres du point de rendez-vous.'); // palier de 1 km
      expect(a.pour(650), isNull);
      expect(a.pour(450), 'Awa est à 450 mètres du point de rendez-vous.'); // palier de 500 m
      expect(a.pour(180), 'Awa est à 200 mètres du point de rendez-vous.');
      expect(a.pour(40), 'Awa est au point de rendez-vous.');
      expect(a.pour(30), isNull);
    });
  });
}
