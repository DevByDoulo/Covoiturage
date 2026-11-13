import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';
import 'package:yobalema/core/api.dart';
import 'package:yobalema/core/modeles.dart';
import 'package:yobalema/core/session.dart';
import 'package:yobalema/features/profil/suppression_compte.dart';

http.Response _json(Object? corps, [int status = 200]) =>
    http.Response.bytes(utf8.encode(jsonEncode(corps)), status, headers: {'content-type': 'application/json'});

Map<String, dynamic> _profil({bool motDePasseDefini = true}) => {
      'id': 7,
      'prenom': 'Awa',
      'nom': 'Diop',
      'email': 'awa@x.sn',
      'telephone': '+221771234567',
      'role': 'PASSAGER',
      'conducteurValide': false,
      'motDePasseDefini': motDePasseDefini,
    };

Session _session(MockClient client, {bool motDePasseDefini = true}) {
  FlutterSecureStorage.setMockInitialValues({});
  return Session(Api(baseUrl: 'http://test/api', client: client))
    ..utilisateur = Profil.depuisJson(_profil(motDePasseDefini: motDePasseDefini));
}

Future<void> _ouvrir(WidgetTester tester, Session session) async {
  tester.view.physicalSize = const Size(1236, 4500);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(ChangeNotifierProvider.value(
      value: session, child: const MaterialApp(home: SuppressionComptePage())));
  await tester.pumpAndSettle();
}

/// Le bouton rouge (FilledButton.icon est un sous-type : on cherche par ancêtre du libellé).
Finder _bouton() => find.ancestor(
    of: find.text('Supprimer mon compte'), matching: find.byWidgetPredicate((w) => w is FilledButton));

void main() {
  test('supprimerCompte : POST /moi/suppression, puis la session est fermée', () async {
    Map<String, dynamic>? corps;
    final session = _session(MockClient((r) async {
      expect(r.method, 'POST');
      expect(r.url.path, '/api/moi/suppression');
      corps = jsonDecode(r.body) as Map<String, dynamic>;
      return _json({'dateSuppressionDefinitive': '2026-12-13T10:00:00'});
    }));

    await session.supprimerCompte(motDePasse: 'MotDePasse2026');

    expect(corps, {'motDePasse': 'MotDePasse2026', 'code': null});
    expect(session.connecte, isFalse);
    expect(session.suppressionDemandee, isTrue);
  });

  test("une connexion pendant le délai de grâce annule la suppression et l'annonce", () async {
    final session = _session(MockClient((r) async {
      return _json({
        'etape': 'CONNECTE',
        'accessToken': 'a',
        'refreshToken': 'r',
        'suppressionAnnulee': true,
        'utilisateur': _profil(),
      });
    }))
      ..suppressionDemandee = true;

    final r = await session.connexion('awa@x.sn', 'MotDePasse2026');

    expect(r.suppressionAnnulee, isTrue);
    expect(session.suppressionAnnulee, isTrue);
    expect(session.suppressionDemandee, isFalse);
  });

  testWidgets('compte avec mot de passe : refus expliqué (409), puis demande acceptée', (tester) async {
    var appels = 0;
    final session = _session(MockClient((r) async {
      appels++;
      if (appels == 1) {
        return _json({
          'detail': 'Suppression impossible pour le moment : Vous avez 1 réservation acceptée à venir : annulez-la depuis « Mes réservations » ou faites le trajet.',
        }, 409);
      }
      return _json({'dateSuppressionDefinitive': '2026-12-13T10:00:00'});
    }));
    await _ouvrir(tester, session);

    final bouton = _bouton();
    expect(tester.widget<ButtonStyleButton>(bouton).onPressed, isNull); // rien saisi, case non cochée

    await tester.enterText(find.byType(TextField), 'MotDePasse2026');
    await tester.tap(find.byType(CheckboxListTile));
    await tester.pump();
    expect(tester.widget<ButtonStyleButton>(bouton).onPressed, isNotNull);

    await tester.tap(bouton);
    await tester.pumpAndSettle();
    expect(find.textContaining('réservation acceptée à venir'), findsOneWidget);
    expect(session.connecte, isTrue);

    await tester.tap(bouton);
    await tester.pumpAndSettle();
    expect(session.connecte, isFalse);
    expect(session.suppressionDemandee, isTrue);
  });

  testWidgets('compte Google : code envoyé par email, puis suppression confirmée par le code', (tester) async {
    final chemins = <String>[];
    Map<String, dynamic>? corps;
    final session = _session(MockClient((r) async {
      chemins.add(r.url.path);
      if (r.url.path.endsWith('/code')) {
        return _json({'etape': 'OTP_ENVOYE', 'canal': 'EMAIL', 'emailMasque': 'a***@x.sn'});
      }
      corps = jsonDecode(r.body) as Map<String, dynamic>;
      return _json({'dateSuppressionDefinitive': '2026-12-13T10:00:00'});
    }), motDePasseDefini: false);
    await _ouvrir(tester, session);

    expect(find.byType(TextField), findsNothing); // pas de mot de passe à saisir
    await tester.tap(find.text('Recevoir un code de confirmation'));
    await tester.pumpAndSettle();
    expect(find.textContaining('a***@x.sn'), findsOneWidget);

    await tester.enterText(find.byType(TextField), '123456');
    await tester.tap(find.byType(CheckboxListTile));
    await tester.pump();
    await tester.tap(_bouton());
    await tester.pumpAndSettle();

    expect(chemins, ['/api/moi/suppression/code', '/api/moi/suppression']);
    expect(corps, {'motDePasse': null, 'code': '123456'});
    expect(session.connecte, isFalse);
  });
}
