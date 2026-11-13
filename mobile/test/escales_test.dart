import 'package:flutter_test/flutter_test.dart';
import 'package:yobalema/core/escales.dart';
import 'package:yobalema/core/modeles.dart';

void main() {
  Lieu lieu(String nom, [double lat = 14.7]) => Lieu(nom, lat, -17.4);

  group('EscalesSaisies', () {
    test('ajoute jusqu\'à la limite de 5 puis refuse', () {
      final s = EscalesSaisies();
      for (var i = 0; i < maxEscales; i++) {
        expect(s.ajouter(), isNotNull);
      }
      expect(s.plein, isTrue);
      expect(s.ajouter(), isNull);
      expect(s.nombre, maxEscales);
    });

    test('une escale sans adresse rend la saisie incomplète', () {
      final s = EscalesSaisies();
      expect(s.complete, isTrue); // aucune escale : rien à compléter
      s.ajouter();
      expect(s.complete, isFalse);
      s.definir(0, lieu('Thiès'));
      expect(s.complete, isTrue);
    });

    test('déplace une escale et garde son identifiant', () {
      final s = EscalesSaisies();
      for (final n in ['Rufisque', 'Thiès', 'Mbour']) {
        s.ajouter();
        s.definir(s.nombre - 1, lieu(n));
      }
      final idMbour = s.liste[2].id;
      expect(s.deplacer(2, -1), 1);
      expect(s.liste.map((e) => e.lieu!.libelle), ['Rufisque', 'Mbour', 'Thiès']);
      expect(s.liste[1].id, idMbour);
      // Aux extrémités, rien ne bouge.
      expect(s.deplacer(0, -1), 0);
      expect(s.deplacer(2, 1), 2);
      expect(s.liste.map((e) => e.lieu!.libelle), ['Rufisque', 'Mbour', 'Thiès']);
    });

    test('supprime une escale et garde l\'ordre des autres', () {
      final s = EscalesSaisies();
      for (final n in ['A', 'B', 'C']) {
        s.ajouter();
        s.definir(s.nombre - 1, lieu(n));
      }
      s.retirer(1);
      s.retirer(9); // index hors limites : ignoré
      expect(s.liste.map((e) => e.lieu!.libelle), ['A', 'C']);
    });

    test('les identifiants ne sont jamais réutilisés', () {
      final s = EscalesSaisies();
      final premier = s.ajouter()!;
      s.retirer(0);
      expect(s.ajouter()!.id, isNot(premier.id));
    });

    test('format de l\'API : dans l\'ordre, sans les escales vides', () {
      final s = EscalesSaisies();
      s.ajouter();
      s.definir(0, lieu('Thiès', 14.79));
      s.ajouter(); // vide
      s.ajouter();
      s.definir(2, lieu('Mbour', 14.42));
      expect(s.pourApi(), [
        {'lieu': 'Thiès', 'latitude': 14.79, 'longitude': -17.4},
        {'lieu': 'Mbour', 'latitude': 14.42, 'longitude': -17.4},
      ]);
    });

    test('repères numérotés selon la position dans le trajet', () {
      final s = EscalesSaisies();
      s.ajouter(); // vide : numéro 1 sauté
      s.ajouter();
      s.definir(1, lieu('Mbour'));
      final r = s.reperes();
      expect(r, hasLength(1));
      expect(r.first.$2, '2');
    });
  });
}
