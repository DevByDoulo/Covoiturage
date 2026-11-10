import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:yobalema/core/api.dart';
import 'package:yobalema/features/paiements/paiements.dart';

http.Response _json(Object corps, [int status = 200]) =>
    http.Response.bytes(utf8.encode(jsonEncode(corps)), status, headers: {'content-type': 'application/json'});

Map<String, dynamic> _ligne(String ref, String role, String statut, num montant) => {
      'referenceTransaction': ref,
      'idReservation': 1,
      'role': role,
      'trajet': 'Dakar → Thiès',
      'dateHeureDepart': '2026-11-20T08:00:00',
      'contrepartie': 'Awa Diop',
      'montant': montant,
      'moyen': 'WAVE',
      'statut': statut,
      'dateInitiation': '2026-11-18T10:00:00',
    };

final _recu = {
  'referenceTransaction': 'PAY-1',
  'referenceOperateur': 'W-99',
  'dateConfirmation': '2026-11-18T10:05:00',
  'passager': 'Moussa Fall',
  'conducteur': 'Awa Diop',
  'trajet': 'Dakar → Thiès',
  'dateHeureDepart': '2026-11-20T08:00:00',
  'nombrePlaces': 2,
  'prixUnitaire': 1500,
  'montant': 3000,
  'commission': 0,
  'montantConducteur': 3000,
  'moyen': 'WAVE',
  'statut': 'REMBOURSE',
  'dateRemboursement': '2026-11-19T09:00:00',
};

void main() {
  setUpAll(() => initializeDateFormatting('fr_FR'));

  test('total encaissé : paiements réussis comme conducteur seulement', () {
    final lignes = [
      _ligne('A', 'CONDUCTEUR', 'REUSSI', 2000),
      _ligne('B', 'CONDUCTEUR', 'REMBOURSE', 1000),
      _ligne('C', 'PASSAGER', 'REUSSI', 500),
      _ligne('D', 'CONDUCTEUR', 'REUSSI', 1500),
    ].map(LignePaiement.depuisJson).toList();
    expect(totalEncaisse(lignes), 3500);
    expect(lignes[1].recuDisponible, isTrue);
    expect(LignePaiement.depuisJson(_ligne('E', 'PASSAGER', 'ECHOUE', 1)).recuDisponible, isFalse);
  });

  test('texte du reçu remboursé', () {
    final texte = Recu.depuisJson(_recu).enTexte();
    expect(texte, contains('N° PAY-1'));
    expect(texte, contains('Remboursé intégralement le 19 novembre 2026 à 09:00'));
    expect(texte, contains('Moyen de paiement : Wave (réf. W-99)'));
    expect(texte, matches(RegExp(r'Places : 2 × 1\s500 FCFA')));
    expect(texte, contains('Statut : Remboursé'));
  });

  testWidgets('historique puis reçu, avec copie', (tester) async {
    final chemins = <String>[];
    final api = Api(
      baseUrl: 'http://test/api',
      client: MockClient((r) async {
        chemins.add(r.url.path);
        if (r.url.path == '/api/moi/paiements') {
          return _json([
            _ligne('PAY-1', 'PASSAGER', 'REUSSI', 3000),
            _ligne('PAY-2', 'CONDUCTEUR', 'REUSSI', 2000),
            _ligne('PAY-3', 'PASSAGER', 'ECHOUE', 1000),
          ]);
        }
        return _json(_recu);
      }),
    );
    String? copie;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (appel) async {
      if (appel.method == 'Clipboard.setData') copie = (appel.arguments as Map)['text'] as String;
      return null;
    });
    final routeur = GoRouter(
      initialLocation: '/paiements',
      routes: [
        GoRoute(path: '/paiements', builder: (_, _) => const MesPaiementsPage()),
        GoRoute(
          path: '/paiements/:reference/recu',
          builder: (_, etat) => RecuPage(reference: etat.pathParameters['reference']!),
        ),
      ],
    );
    await tester.pumpWidget(Provider<Api>.value(value: api, child: MaterialApp.router(routerConfig: routeur)));
    await tester.pumpAndSettle();

    expect(find.textContaining('Encaissé comme conducteur'), findsOneWidget);
    expect(find.textContaining('réf. PAY-3'), findsOneWidget);
    // Pas de reçu pour le paiement non abouti.
    expect(find.text('Reçu'), findsNWidgets(2));

    await tester.tap(find.text('Reçu').first);
    await tester.pumpAndSettle();
    expect(chemins.last, '/api/paiements/PAY-1/recu');
    expect(find.text('Reçu de paiement'), findsOneWidget);
    expect(find.textContaining('Remboursé intégralement'), findsOneWidget);
    expect(find.text('Moussa Fall'), findsOneWidget);

    await tester.scrollUntilVisible(find.text('Copier le reçu'), 200);
    await tester.tap(find.text('Copier le reçu'));
    await tester.pumpAndSettle();
    expect(copie, startsWith('YOBALEMAsn — Reçu de paiement'));
    expect(find.text('Reçu copié'), findsOneWidget);
  });
}
