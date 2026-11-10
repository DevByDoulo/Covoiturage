import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';
import 'package:yobalema/core/api.dart';
import 'package:yobalema/core/session.dart';
import 'package:yobalema/features/auth/mot_de_passe_oublie.dart';

http.Response _json(Object? corps, [int status = 200]) =>
    http.Response.bytes(utf8.encode(jsonEncode(corps)), status, headers: {'content-type': 'application/json'});

void main() {
  test('les trois appels de la session visent les bons endpoints', () async {
    final appels = <String, Map<String, dynamic>>{};
    final session = Session(
      Api(
        baseUrl: 'http://test/api',
        client: MockClient((r) async {
          appels[r.url.path] = jsonDecode(r.body) as Map<String, dynamic>;
          if (r.url.path.endsWith('/oublie')) {
            return _json({
              'etape': 'OTP_ENVOYE',
              'canal': 'EMAIL',
              'emailMasque': 'a***@x.sn',
              'renvoiPossibleDansSecondes': 30,
            });
          }
          if (r.url.path.endsWith('/verifier-code')) return _json({'jeton': 'jeton-1', 'validiteSecondes': 600});
          return http.Response('', 204);
        }),
      ),
    );

    final r = await session.demanderCodeReinitialisation(' a@x.sn ');
    expect(r.canal, 'EMAIL');
    expect(r.destination, 'a***@x.sn');
    expect(r.renvoiDans, 30);
    expect(appels['/api/auth/mot-de-passe/oublie'], {'identifiant': 'a@x.sn'});

    final jeton = await session.verifierCodeReinitialisation('a@x.sn', '123456');
    expect(jeton, 'jeton-1');
    expect(appels['/api/auth/mot-de-passe/verifier-code'], {'identifiant': 'a@x.sn', 'code': '123456'});

    await session.reinitialiserMotDePasse(jeton, 'Nouveau123');
    expect(appels['/api/auth/mot-de-passe/reinitialiser'], {'jeton': 'jeton-1', 'nouveauMotDePasse': 'Nouveau123'});
  });

  testWidgets('parcours complet : email, code, nouveau mot de passe, retour à la connexion', (tester) async {
    final session = Session(
      Api(
        baseUrl: 'http://test/api',
        client: MockClient((r) async {
          if (r.url.path.endsWith('/oublie')) {
            return _json({'etape': 'OTP_ENVOYE', 'canal': 'EMAIL', 'emailMasque': 'a***@x.sn'});
          }
          if (r.url.path.endsWith('/verifier-code')) {
            final code = (jsonDecode(r.body) as Map)['code'];
            if (code != '123456') return _json({'detail': 'Code incorrect.', 'tentativesRestantes': 4}, 400);
            return _json({'jeton': 'jeton-1', 'validiteSecondes': 600});
          }
          return http.Response('', 204);
        }),
      ),
    );
    final routeur = GoRouter(
      initialLocation: '/mot-de-passe-oublie',
      routes: [
        GoRoute(path: '/mot-de-passe-oublie', builder: (_, _) => const MotDePasseOubliePage()),
        GoRoute(
          path: '/connexion',
          builder: (_, etat) => Text('connexion reinitialise=${etat.uri.queryParameters['reinitialise']}'),
        ),
      ],
    );
    await tester.pumpWidget(
      ChangeNotifierProvider<Session>.value(
        value: session,
        child: MaterialApp.router(routerConfig: routeur),
      ),
    );

    // Étape 1 : champ vide refusé, puis envoi.
    await tester.tap(find.text('Envoyer le code'));
    await tester.pump();
    expect(find.text('Saisissez votre email ou votre numéro'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField), 'a@x.sn');
    await tester.tap(find.text('Envoyer le code'));
    await tester.pumpAndSettle();

    // Étape 2 : mauvais code (message avec tentatives), puis bon code.
    expect(find.text('Saisissez le code reçu par email'), findsOneWidget);
    expect(find.text('Envoyé à a***@x.sn'), findsOneWidget);
    await tester.enterText(find.byType(TextField), '000000');
    await tester.pumpAndSettle();
    expect(find.textContaining('il vous reste 4 tentative(s)'), findsOneWidget);
    await tester.enterText(find.byType(TextField), '123456');
    await tester.pumpAndSettle();

    // Étape 3 : mot de passe trop faible refusé, puis valide.
    final champs = find.byType(TextFormField);
    await tester.enterText(champs.at(0), 'court');
    await tester.enterText(champs.at(1), 'court');
    await tester.tap(find.text('Enregistrer le mot de passe'));
    await tester.pump();
    expect(find.text('Au moins 8 caractères, dont une lettre et un chiffre'), findsOneWidget);
    await tester.enterText(champs.at(0), 'Nouveau123');
    await tester.enterText(champs.at(1), 'Nouveau123');
    await tester.tap(find.text('Enregistrer le mot de passe'));
    await tester.pumpAndSettle();

    expect(find.text('connexion reinitialise=1'), findsOneWidget);
  });
}
