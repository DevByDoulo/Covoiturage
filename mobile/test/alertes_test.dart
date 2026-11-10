import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:yobalema/core/api.dart';
import 'package:yobalema/core/modeles.dart';
import 'package:yobalema/features/alertes/alertes.dart';

http.Response _json(Object corps, [int status = 200]) =>
    http.Response.bytes(utf8.encode(jsonEncode(corps)), status, headers: {'content-type': 'application/json'});

Map<String, dynamic> _alerte(int id, String date) => {
      'id': id,
      'depart': {'lieu': 'Dakar', 'latitude': 14.69, 'longitude': -17.44},
      'arrivee': {'lieu': 'Thiès', 'latitude': 14.79, 'longitude': -16.93},
      'date': date,
      'rayonKm': 5,
      'prixMax': null,
    };

void main() {
  test('crée, détecte les doublons et supprime une alerte', () async {
    final corps = <String, dynamic>{};
    final api = Api(
      baseUrl: 'http://test/api',
      client: MockClient((r) async {
        if (r.method == 'POST') {
          corps.addAll(jsonDecode(r.body) as Map<String, dynamic>);
          return _json(_alerte(7, '2026-11-20'), 201);
        }
        if (r.method == 'DELETE') return http.Response('', 204);
        return _json([_alerte(3, '2026-11-25')]);
      }),
    );
    final service = AlertesService(api);
    await service.charger();
    expect(service.alertes, hasLength(1));

    final dakar = Point('Dakar', 14.69, -17.44);
    final thies = Point('Thiès', 14.79, -16.93);
    await service.creer(depart: dakar, arrivee: thies, date: DateTime(2026, 11, 20));
    expect(corps['date'], '2026-11-20');
    expect(corps.containsKey('prixMax'), isFalse);
    expect(service.alertes!.map((a) => a.id), [7, 3]);
    expect(service.existe(dakar, thies, DateTime(2026, 11, 20)), isTrue);
    expect(service.existe(dakar, thies, DateTime(2026, 11, 21)), isFalse);

    await service.supprimer(7);
    expect(service.alertes!.map((a) => a.id), [3]);
  });
}
