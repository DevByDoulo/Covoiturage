import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';
import 'package:yobalema/core/api.dart';
import 'package:yobalema/core/formats.dart';
import 'package:yobalema/core/google.dart';
import 'package:yobalema/core/session.dart';
import 'package:yobalema/features/auth/connexion.dart';
import 'package:yobalema/features/auth/google.dart';
import 'package:yobalema/features/auth/verification.dart';
import 'package:yobalema/shared/widgets.dart';

http.Response _json(Object? corps, [int status = 200]) =>
    http.Response.bytes(utf8.encode(jsonEncode(corps)), status, headers: {'content-type': 'application/json'});

const _profil = {
  'id': 1,
  'prenom': 'Awa',
  'nom': 'Diop',
  'email': 'awa@gmail.com',
  'telephone': '+221771234567',
  'role': 'PASSAGER',
  'statut': 'ACTIF',
};

const _connecte = {
  'etape': 'CONNECTE',
  'accessToken': 'acces',
  'refreshToken': 'refresh',
  'expiresIn': 900,
  'utilisateur': _profil,
};

/// Remplace le plugin : renvoie un jeton, null (annulation) ou lève une erreur.
class _GoogleFactice implements ServiceGoogle {
  _GoogleFactice(this._resultat);

  final Future<String?> Function() _resultat;
  int appels = 0;

  @override
  Future<String?> obtenirIdToken() {
    appels++;
    return _resultat();
  }
}

/// Session branchée sur un faux serveur ; [corps] reçoit le corps de chaque POST /auth/google.
Session _session(http.Response Function(Map<String, dynamic> corps) google, {List<Map<String, dynamic>>? corps}) =>
    Session(
      Api(
        baseUrl: 'http://test/api',
        client: MockClient((r) async {
          if (r.url.path == '/api/auth/google') {
            final c = jsonDecode(r.body) as Map<String, dynamic>;
            corps?.add(c);
            return google(c);
          }
          return http.Response('', 404);
        }),
      ),
    );

void main() {
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  group('configuration et messages', () {
    test("sans ID client Web, Google n'est pas configuré", () {
      expect(const ConfigGoogle().configuree, isFalse);
      expect(const ConfigGoogle(serverClientId: '  ').configuree, isFalse);
      expect(const ConfigGoogle(serverClientId: '123-abc.apps.googleusercontent.com').configuree, isTrue);
    });

    test("l'annulation n'affiche rien, les autres erreurs ont un message", () {
      expect(messageEchecGoogle(GoogleSignInExceptionCode.canceled), isNull);
      expect(messageEchecGoogle(GoogleSignInExceptionCode.interrupted), contains('connexion internet'));
      expect(messageEchecGoogle(GoogleSignInExceptionCode.clientConfigurationError), contains('SHA-1'));
      expect(messageEchecGoogle(GoogleSignInExceptionCode.unknownError), isNotNull);
    });

    test('numéro sénégalais : chiffres seuls, indicatif retiré', () {
      expect(numeroSenegal('77 123 45 67'), '771234567');
      expect(numeroSenegal('+221 77 123 45 67'), '771234567');
      expect(numeroSenegalValide('+221 77 123 45 67'), isTrue);
      expect(numeroSenegalValide('33 123 45 67'), isFalse);
      expect(numeroSenegalValide('77 123 45'), isFalse);
    });
  });

  group('continuerAvecGoogle', () {
    test("annulation : aucun appel à l'API", () async {
      final corps = <Map<String, dynamic>>[];
      final issue = await continuerAvecGoogle(_GoogleFactice(() async => null), _session((_) => _json(_connecte), corps: corps));
      expect(issue, isA<GoogleAnnule>());
      expect(corps, isEmpty);
    });

    test('compte connu : la session est ouverte avec les jetons de l\'appli', () async {
      final corps = <Map<String, dynamic>>[];
      final session = _session((_) => _json(_connecte), corps: corps);
      final issue = await continuerAvecGoogle(_GoogleFactice(() async => 'id-token'), session);
      expect(issue, isA<GoogleConnecte>());
      expect(corps.single, {'idToken': 'id-token'});
      expect(session.connecte, isTrue);
      expect(session.api.accessToken, 'acces');
      expect(session.utilisateur!.prenom, 'Awa');
    });

    test('compte inconnu : le numéro est demandé, avec le même idToken', () async {
      final session = _session((_) => _json({'etape': 'TELEPHONE_REQUIS'}));
      final issue = await continuerAvecGoogle(_GoogleFactice(() async => 'id-token'), session);
      expect(issue, isA<GoogleTelephoneRequis>().having((i) => i.idToken, 'idToken', 'id-token'));
      expect(session.connecte, isFalse);
    });

    test('erreur réseau : message de connexion', () async {
      final session = Session(Api(baseUrl: 'http://test/api', client: MockClient((_) => throw http.ClientException('hors ligne'))));
      final issue = await continuerAvecGoogle(_GoogleFactice(() async => 'id-token'), session);
      expect(issue, isA<GoogleErreur>().having((e) => e.message, 'message', contains('Vérifiez votre connexion')));
    });

    test('jeton refusé ou serveur non configuré : message du backend', () async {
      final refuse = await continuerAvecGoogle(
          _GoogleFactice(() async => 'id-token'), _session((_) => _json({'detail': 'Jeton Google invalide'}, 401)));
      expect(refuse, isA<GoogleErreur>().having((e) => e.message, 'message', 'Jeton Google invalide'));
    });

    test('échec côté Google : son message est affiché', () async {
      final issue = await continuerAvecGoogle(
          _GoogleFactice(() async => throw const EchecGoogle('Mal configurée')), _session((_) => _json(_connecte)));
      expect(issue, isA<GoogleErreur>().having((e) => e.message, 'message', 'Mal configurée'));
    });
  });

  group('écrans', () {
    Future<void> monter(WidgetTester tester, Session session, ServiceGoogle google, String depart) async {
      final routeur = GoRouter(
        initialLocation: depart,
        initialExtra: depart == '/google/telephone' ? 'id-token' : null,
        routes: [
          GoRoute(path: '/connexion', builder: (_, _) => const ConnexionPage()),
          GoRoute(
            path: '/google/telephone',
            builder: (_, etat) => GoogleTelephonePage(idToken: etat.extra as String),
          ),
          GoRoute(
            path: '/verification',
            builder: (_, etat) {
              final d = etat.extra as DemandeVerification;
              return Text('verification ${d.identifiant} ${d.canal} ${d.destination}');
            },
          ),
        ],
      );
      await tester.pumpWidget(MultiProvider(
        providers: [
          ChangeNotifierProvider<Session>.value(value: session),
          Provider<ServiceGoogle>.value(value: google),
        ],
        child: MaterialApp.router(routerConfig: routeur),
      ));
      await tester.pumpAndSettle();
    }

    testWidgets('connexion : erreur Google affichée, puis compte inconnu → écran du numéro', (tester) async {
      var reponse = _json({'detail': 'Le service est momentanément indisponible.'}, 503);
      final session = _session((_) => reponse);
      await monter(tester, session, _GoogleFactice(() async => 'id-token'), '/connexion');

      await tester.ensureVisible(find.text('Continuer avec Google'));
      await tester.tap(find.text('Continuer avec Google'));
      await tester.pumpAndSettle();
      expect(find.text('Le service est momentanément indisponible.'), findsOneWidget);

      reponse = _json({'etape': 'TELEPHONE_REQUIS'});
      await tester.tap(find.text('Continuer avec Google'));
      await tester.pumpAndSettle();
      expect(find.text('Encore une étape'), findsOneWidget);
    });

    testWidgets('connexion : annulation, aucun message', (tester) async {
      final google = _GoogleFactice(() async => null);
      await monter(tester, _session((_) => _json(_connecte)), google, '/connexion');
      await tester.ensureVisible(find.text('Continuer avec Google'));
      await tester.tap(find.text('Continuer avec Google'));
      await tester.pumpAndSettle();
      expect(google.appels, 1);
      expect(find.text('Connexion'), findsOneWidget);
      expect(find.byType(Bandeau), findsNothing);
    });

    testWidgets('numéro : validation, numéro déjà pris, puis code envoyé', (tester) async {
      final corps = <Map<String, dynamic>>[];
      final session = _session((c) {
        if (c['telephone'] == '770000000') {
          return _json({'detail': 'Ce numéro est déjà associé à un compte', 'champ': 'telephone'}, 409);
        }
        return _json({'etape': 'OTP_ENVOYE', 'canal': 'SMS', 'telephoneMasque': '+221 77 *** ** 67', 'renvoiPossibleDansSecondes': 60});
      }, corps: corps);
      await monter(tester, session, _GoogleFactice(() async => null), '/google/telephone');

      await tester.tap(find.text('Recevoir le code'));
      await tester.pump();
      expect(find.text('Numéro sénégalais à 9 chiffres, commençant par 7'), findsOneWidget);
      expect(corps, isEmpty);

      await tester.enterText(find.byType(TextFormField), '77 000 00 00');
      await tester.tap(find.text('Recevoir le code'));
      await tester.pumpAndSettle();
      expect(find.text('Ce numéro est déjà associé à un compte'), findsOneWidget);

      await tester.enterText(find.byType(TextFormField), '77 123 45 67');
      await tester.tap(find.text('Femme'));
      await tester.ensureVisible(find.text('Recevoir le code'));
      await tester.tap(find.text('Recevoir le code'));
      await tester.pumpAndSettle();
      expect(corps.last, {'idToken': 'id-token', 'telephone': '771234567', 'sexe': 'FEMME'});
      expect(find.text('verification 771234567 SMS +221 77 *** ** 67'), findsOneWidget);
    });
  });
}
