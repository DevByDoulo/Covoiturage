import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';
import 'package:yobalema/core/api.dart';
import 'package:yobalema/core/google.dart';
import 'package:yobalema/core/session.dart';
import 'package:yobalema/features/auth/connexion.dart';
import 'package:yobalema/features/auth/profil_telephone.dart';
import 'package:yobalema/features/auth/verification.dart';

http.Response _json(Object? corps, [int status = 200]) =>
    http.Response.bytes(utf8.encode(jsonEncode(corps)), status, headers: {'content-type': 'application/json'});

const _connecte = {
  'etape': 'CONNECTE',
  'accessToken': 'acces',
  'refreshToken': 'refresh',
  'expiresIn': 900,
  'utilisateur': {'id': 1, 'prenom': 'Awa', 'nom': 'Diop', 'telephone': '+221771234567', 'role': 'PASSAGER', 'statut': 'ACTIF'},
};

class _GoogleInutilise implements ServiceGoogle {
  @override
  Future<String?> obtenirIdToken() async => null;
}

/// Session branchée sur un faux serveur : [repondre] reçoit le chemin et le corps de chaque appel.
Session _session(http.Response Function(String chemin, Map<String, dynamic> corps) repondre,
        {List<String>? appels}) =>
    Session(Api(
      baseUrl: 'http://test/api',
      client: MockClient((r) async {
        appels?.add(r.url.path);
        return repondre(r.url.path, r.body.isEmpty ? {} : jsonDecode(r.body) as Map<String, dynamic>);
      }),
    ));

void main() {
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  test('nouveau numéro : code, jeton puis compte créé (mot de passe facultatif absent)', () async {
    final corps = <String, Map<String, dynamic>>{};
    final session = _session((chemin, c) {
      corps[chemin] = c;
      if (chemin.endsWith('/telephone/code')) return _json({'etape': 'OTP_ENVOYE', 'canal': 'SMS', 'telephoneMasque': '+221 77 *** ** 67'});
      if (chemin.endsWith('/telephone/verifier')) return _json({'etape': 'PROFIL_REQUIS', 'jetonInscription': 'jeton-1'});
      return _json(_connecte, 201);
    });

    final code = await session.codeTelephone('+221771234567');
    expect(code.destination, '+221 77 *** ** 67');
    final verif = await session.verifierCodeTelephone('+221771234567', '123456');
    expect(verif.etape, 'PROFIL_REQUIS');
    expect(verif.jetonInscription, 'jeton-1');
    expect(session.connecte, isFalse);

    await session.terminerInscriptionTelephone('jeton-1', prenom: ' Awa ', nom: 'Diop', sexe: 'FEMME');
    expect(corps['/api/auth/telephone/terminer'], {'jeton': 'jeton-1', 'prenom': 'Awa', 'nom': 'Diop', 'sexe': 'FEMME'});
    expect(session.connecte, isTrue);
  });

  test('numéro déjà connu : le code connecte directement', () async {
    final session = _session((_, _) => _json(_connecte));
    final r = await session.verifierCodeTelephone('+221771234567', '123456');
    expect(r.connecte, isTrue);
    expect(session.utilisateur!.prenom, 'Awa');
  });

  group('écrans', () {
    Future<void> monter(WidgetTester tester, Session session, {String depart = '/connexion', Object? extra}) async {
      final routeur = GoRouter(
        initialLocation: depart,
        initialExtra: extra,
        routes: [
          GoRoute(path: '/connexion', builder: (_, _) => const ConnexionPage()),
          GoRoute(path: '/autres-options', builder: (_, _) => const Text('autres options')),
          GoRoute(
            path: '/verification',
            builder: (_, etat) => VerificationPage(demande: etat.extra as DemandeVerification),
          ),
          GoRoute(path: '/inscription/profil', builder: (_, etat) => Text('profil ${etat.extra}')),
        ],
      );
      await tester.pumpWidget(MultiProvider(
        providers: [
          ChangeNotifierProvider<Session>.value(value: session),
          Provider<ServiceGoogle>.value(value: _GoogleInutilise()),
        ],
        child: MaterialApp.router(routerConfig: routeur),
      ));
      await tester.pumpAndSettle();
    }

    testWidgets('départ : numéro, « ou », Google, autres options ; numéro invalide refusé sans appel', (tester) async {
      final appels = <String>[];
      await monter(tester, _session((_, _) => _json({}), appels: appels));
      expect(find.text('Quel est votre numéro de téléphone ?'), findsOneWidget);
      expect(find.text('Continuer avec Google'), findsOneWidget);
      expect(find.text('Autres options'), findsOneWidget);

      await tester.enterText(find.byKey(const Key('telephone')), '12 34');
      await tester.tap(find.text('Continuer'));
      await tester.pumpAndSettle();
      expect(find.textContaining('9 chiffres'), findsOneWidget);
      expect(appels, isEmpty);

      await tester.ensureVisible(find.text('Autres options'));
      await tester.tap(find.text('Autres options'));
      await tester.pumpAndSettle();
      expect(find.text('autres options'), findsOneWidget);
    });

    testWidgets('nouveau numéro : code par SMS, puis profil avec le jeton', (tester) async {
      final session = _session((chemin, c) {
        if (chemin.endsWith('/telephone/code')) {
          expect(c, {'telephone': '+221771234567'});
          return _json({'etape': 'OTP_ENVOYE', 'canal': 'SMS', 'telephoneMasque': '+221 77 *** ** 67'});
        }
        if (c['code'] != '123456') return _json({'detail': 'Code incorrect.', 'tentativesRestantes': 4}, 400);
        return _json({'etape': 'PROFIL_REQUIS', 'jetonInscription': 'jeton-1'});
      });
      await monter(tester, session);

      await tester.enterText(find.byKey(const Key('telephone')), '77 123 45 67');
      await tester.tap(find.text('Continuer'));
      await tester.pumpAndSettle();
      expect(find.text('Saisissez le code reçu par SMS'), findsOneWidget);

      await tester.enterText(find.byType(TextField), '000000');
      await tester.pumpAndSettle();
      expect(find.textContaining('il vous reste 4 tentative'), findsOneWidget);

      await tester.enterText(find.byType(TextField), '123456');
      await tester.pumpAndSettle();
      expect(find.text('profil jeton-1'), findsOneWidget);
    });

    testWidgets('profil : prénom, nom, sexe et conditions obligatoires ; mot de passe facultatif', (tester) async {
      final corps = <Map<String, dynamic>>[];
      final session = _session((_, c) {
        corps.add(c);
        return _json(_connecte, 201);
      });
      final routeur = GoRouter(
        initialLocation: '/inscription/profil',
        routes: [GoRoute(path: '/inscription/profil', builder: (_, _) => const ProfilTelephonePage(jeton: 'jeton-1'))],
      );
      await tester.pumpWidget(ChangeNotifierProvider<Session>.value(
        value: session,
        child: MaterialApp.router(routerConfig: routeur),
      ));
      await tester.pumpAndSettle();

      // Chiffres et symboles ne peuvent pas être tapés.
      await tester.enterText(find.byKey(const Key('prenom')), 'Awa123');
      await tester.enterText(find.byKey(const Key('nom')), '@Diop!');
      expect(tester.widget<TextFormField>(find.byKey(const Key('prenom'))).controller!.text, 'Awa');
      expect(tester.widget<TextFormField>(find.byKey(const Key('nom'))).controller!.text, 'Diop');
      await tester.enterText(find.byKey(const Key('prenom')), 'Awa');
      await tester.enterText(find.byKey(const Key('nom')), 'Diop');
      await tester.ensureVisible(find.text('Créer mon compte'));
      await tester.tap(find.text('Créer mon compte'));
      await tester.pumpAndSettle();
      expect(find.textContaining('une femme ou un homme'), findsOneWidget);

      await tester.tap(find.text('Une femme'));
      await tester.enterText(find.byKey(const Key('motDePasse')), 'court');
      await tester.ensureVisible(find.text('Créer mon compte'));
      await tester.tap(find.text('Créer mon compte'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Au moins 8 caractères'), findsOneWidget);

      await tester.enterText(find.byKey(const Key('motDePasse')), '');
      await tester.ensureVisible(find.byType(CheckboxListTile));
      await tester.tap(find.byType(CheckboxListTile));
      await tester.ensureVisible(find.text('Créer mon compte'));
      await tester.tap(find.text('Créer mon compte'));
      await tester.pumpAndSettle();
      expect(corps.single, {'jeton': 'jeton-1', 'prenom': 'Awa', 'nom': 'Diop', 'sexe': 'FEMME'});
      expect(session.connecte, isTrue);
    });
  });
}
