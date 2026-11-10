import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:yobalema/core/api.dart';
import 'package:yobalema/features/signalements/signalements.dart';

http.Response _json(Object corps, [int status = 200]) =>
    http.Response.bytes(utf8.encode(jsonEncode(corps)), status, headers: {'content-type': 'application/json'});

Map<String, dynamic> _signalement(int id, String statut) => {
      'id': id,
      'signale': {'id': 7, 'prenom': 'Seydou', 'nomInitiale': 'B.'},
      'motif': 'CONDUITE_DANGEREUSE',
      'description': 'Feu rouge grillé',
      'statut': statut,
      'trajet': 'Dakar → Thiès',
      'dateSignalement': '2026-11-10T10:00:00',
      'dateTraitement': statut == 'TRAITE' ? '2026-11-11T09:00:00' : null,
    };

void main() {
  setUpAll(() => initializeDateFormatting('fr_FR'));

  test('seul le motif « Autre » exige une description', () {
    expect(descriptionObligatoire('AUTRE'), isTrue);
    expect(descriptionObligatoire('HARCELEMENT'), isFalse);
    expect(descriptionObligatoire(null), isFalse);
    expect(libellesMotifSignalement.length, 7);
  });

  test('un signalement est ouvert tant qu\'il n\'est ni traité ni classé', () {
    expect(Signalement.depuisJson(_signalement(1, 'EN_ATTENTE')).ouvert, isTrue);
    expect(Signalement.depuisJson(_signalement(2, 'EN_COURS')).ouvert, isTrue);
    expect(Signalement.depuisJson(_signalement(3, 'TRAITE')).ouvert, isFalse);
    expect(Signalement.depuisJson(_signalement(4, 'REJETE')).ouvert, isFalse);
  });

  testWidgets('signaler : description exigée pour « Autre », puis envoi', (tester) async {
    Map<String, dynamic>? envoye;
    final api = Api(
      baseUrl: 'http://test/api',
      client: MockClient((r) async {
        if (r.url.path == '/api/signalements' && r.method == 'POST') {
          envoye = jsonDecode(r.body) as Map<String, dynamic>;
          return _json(_signalement(1, 'EN_ATTENTE'), 201);
        }
        return _json([_signalement(1, 'EN_ATTENTE')]);
      }),
    );
    final routeur = GoRouter(
      initialLocation: '/signaler/7',
      routes: [
        GoRoute(
          path: '/signaler/:id',
          builder: (_, etat) => SignalerPage(
            idUtilisateur: int.parse(etat.pathParameters['id']!),
            idTrajet: 12,
            prenom: 'Seydou',
          ),
        ),
        GoRoute(path: '/signalements', builder: (_, _) => const MesSignalementsPage()),
      ],
    );
    await tester.pumpWidget(Provider<Api>.value(value: api, child: MaterialApp.router(routerConfig: routeur)));
    await tester.pumpAndSettle();
    expect(find.text('Signaler Seydou'), findsOneWidget);

    // Motif « Autre » sans description : refusé avant l'envoi.
    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Autre').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Envoyer le signalement'));
    await tester.pumpAndSettle();
    expect(find.text('Décrivez la situation.'), findsOneWidget);
    expect(envoye, isNull);

    await tester.enterText(find.byType(TextField), '  Elle est partie sans prévenir.  ');
    await tester.tap(find.text('Envoyer le signalement'));
    await tester.pumpAndSettle();
    expect(envoye, {
      'idUtilisateur': 7,
      'idTrajet': 12,
      'motif': 'AUTRE',
      'description': 'Elle est partie sans prévenir.',
    });
    expect(find.textContaining('Signalement envoyé'), findsOneWidget);

    await tester.tap(find.text('Voir mes signalements'));
    await tester.pumpAndSettle();
    expect(find.text('Seydou B.'), findsOneWidget);
    expect(find.text('En attente'), findsOneWidget);
    expect(find.textContaining('Conduite dangereuse'), findsOneWidget);
  });

  testWidgets('mes signalements : liste vide', (tester) async {
    final api = Api(baseUrl: 'http://test/api', client: MockClient((_) async => _json([])));
    final routeur = GoRouter(routes: [GoRoute(path: '/', builder: (_, _) => const MesSignalementsPage())]);
    await tester.pumpWidget(Provider<Api>.value(value: api, child: MaterialApp.router(routerConfig: routeur)));
    await tester.pumpAndSettle();
    expect(find.text('Vous n\'avez fait aucun signalement.'), findsOneWidget);
  });
}
