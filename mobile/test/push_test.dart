import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';
import 'package:yobalema/core/api.dart';
import 'package:yobalema/core/push.dart';
import 'package:yobalema/features/notifications/preferences_push.dart';

http.Response _json(Object? corps, [int status = 200]) =>
    http.Response.bytes(utf8.encode(jsonEncode(corps)), status, headers: {'content-type': 'application/json'});

/// Firebase simulé.
class _FaussePlateforme implements PlateformePush {
  _FaussePlateforme({this.configuree = true, this.autorisee = true});

  final bool configuree;
  bool autorisee;
  String jetonActuel = 'jeton-1';
  int suppressions = 0;
  MessagePush? initial;
  final _jetons = StreamController<String>.broadcast();
  final _ouverts = StreamController<MessagePush>.broadcast();
  final _premierPlan = StreamController<MessagePush>.broadcast();

  @override
  Future<bool> initialiser() async => configuree;
  @override
  Future<bool> demanderPermission() async => autorisee;
  @override
  Future<String?> jeton() async => jetonActuel;
  @override
  Future<void> supprimerJeton() async => suppressions++;
  @override
  Stream<String> get nouveauxJetons => _jetons.stream;
  @override
  Future<MessagePush?> messageInitial() async => initial;
  @override
  Stream<MessagePush> get ouverts => _ouverts.stream;
  @override
  Stream<MessagePush> get premierPlan => _premierPlan.stream;
  @override
  String get nom => 'ANDROID';
}

void main() {
  group('destinationPour', () {
    test('liens du site vers les écrans mobiles', () {
      expect(destinationPour('/trajets/12'), const Destination('/trajets/12', empiler: true));
      expect(destinationPour('/trajets/12/suivi'), const Destination('/trajets/12/suivi', empiler: true));
      expect(destinationPour('/messages/4'), const Destination('/messages/4', empiler: true));
      expect(destinationPour('/signalements'), const Destination('/signalements', empiler: true));
      expect(destinationPour('/reservations'), const Destination('/reservations'));
      expect(destinationPour('/profil'), const Destination('/profil'));
    });

    test('lien inconnu ou absent : onglet Notifications', () {
      expect(destinationPour('/vehicules'), const Destination('/notifications'));
      expect(destinationPour(null), const Destination('/notifications'));
      expect(destinationPour('/trajets/abc'), const Destination('/notifications'));
    });
  });

  group('ServicePush', () {
    late List<String> appels;
    late Api api;

    setUp(() {
      appels = [];
      api = Api(
          baseUrl: 'http://test/api',
          client: MockClient((r) async {
            appels.add('${r.method} ${r.url.path}${r.body.isEmpty ? '' : ' ${r.body}'}');
            return http.Response('', 204);
          }));
    });

    test('connexion : permission, puis jeton enregistré ; déconnexion : jeton retiré', () async {
      final fcm = _FaussePlateforme();
      final push = ServicePush(api, fcm);
      await push.demarrer();
      expect(await push.activer(), isTrue);
      expect(appels, ['POST /api/moi/appareils {"jeton":"jeton-1","plateforme":"ANDROID"}']);

      // Firebase renouvelle le jeton : il est réenregistré
      fcm._jetons.add('jeton-2');
      await Future<void>.delayed(Duration.zero);
      expect(appels.last, 'POST /api/moi/appareils {"jeton":"jeton-2","plateforme":"ANDROID"}');

      await push.desactiver();
      expect(appels.last, 'DELETE /api/moi/appareils/jeton-2');
      expect(fcm.suppressions, 1);

      // Plus connecté : un nouveau jeton n'est pas envoyé
      fcm._jetons.add('jeton-3');
      await Future<void>.delayed(Duration.zero);
      expect(appels.length, 3);
    });

    test('permission refusée (Android 13+) : rien n\'est enregistré', () async {
      final push = ServicePush(api, _FaussePlateforme(autorisee: false));
      await push.demarrer();
      expect(await push.activer(), isFalse);
      expect(appels, isEmpty);
    });

    test('Firebase non configuré : push désactivé sans erreur', () async {
      final fcm = _FaussePlateforme(configuree: false);
      final push = ServicePush(api, fcm);
      await push.demarrer();
      expect(push.disponible, isFalse);
      expect(await push.activer(), isFalse);
      await push.desactiver();
      expect(appels, isEmpty);
      expect(fcm.suppressions, 0);
    });

    test('notifications touchées, reçues à l\'écran, et celle qui a lancé l\'application', () async {
      final fcm = _FaussePlateforme()..initial = const MessagePush(titre: 'T', contenu: 'C', lien: '/trajets/3');
      final push = ServicePush(api, fcm);
      final ouverts = <String?>[];
      final affiches = <String>[];
      push.surOuverture = (m) => ouverts.add(m.lien);
      push.surPremierPlan = (m) => affiches.add(m.titre);
      await push.demarrer();
      expect(push.prendreMessageInitial()?.lien, '/trajets/3');
      expect(push.prendreMessageInitial(), isNull);

      fcm._ouverts.add(const MessagePush(titre: 'Message', contenu: '', lien: '/messages/8'));
      fcm._premierPlan.add(const MessagePush(titre: 'Réservation confirmée', contenu: ''));
      await Future<void>.delayed(Duration.zero);
      expect(ouverts, ['/messages/8']);
      expect(affiches, ['Réservation confirmée']);
    });
  });

  testWidgets('Interrupteur « Notifications push » : préférence lue puis modifiée', (tester) async {
    final corps = <String>[];
    final api = Api(
        baseUrl: 'http://test/api',
        client: MockClient((r) async {
          if (r.url.path.endsWith('/preferences')) {
            if (r.method == 'GET') return _json({'pushActive': true});
            corps.add(r.body);
            return _json(jsonDecode(r.body));
          }
          return http.Response('', 204);
        }));
    final push = ServicePush(api, _FaussePlateforme());
    await push.demarrer();
    await tester.pumpWidget(MultiProvider(
      providers: [Provider.value(value: api), Provider.value(value: push)],
      child: const MaterialApp(home: Scaffold(body: InterrupteurPush())),
    ));
    await tester.pumpAndSettle();
    expect(tester.widget<SwitchListTile>(find.byType(SwitchListTile)).value, isTrue);

    await tester.tap(find.text('Notifications push'));
    await tester.pumpAndSettle();
    expect(corps, ['{"pushActive":false}']);
    expect(tester.widget<SwitchListTile>(find.byType(SwitchListTile)).value, isFalse);
  });
}
