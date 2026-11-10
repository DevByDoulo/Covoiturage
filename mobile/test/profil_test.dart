import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:yobalema/core/api.dart';
import 'package:yobalema/core/modeles.dart';
import 'package:yobalema/core/session.dart';
import 'package:yobalema/features/profil/modifier_profil.dart';

http.Response _json(Object? corps, [int status = 200]) =>
    http.Response.bytes(utf8.encode(jsonEncode(corps)), status, headers: {'content-type': 'application/json'});

Map<String, dynamic> _profil({String prenom = 'Awa', String nom = 'Diop', String? bio, String? photo}) => {
      'id': 7,
      'prenom': prenom,
      'nom': nom,
      'email': 'awa@x.sn',
      'telephone': '+221771234567',
      'sexe': 'FEMME',
      'bio': bio,
      'photoProfil': photo,
      'role': 'PASSAGER',
      'conducteurValide': false,
    };

Session _session(MockClient client) =>
    Session(Api(baseUrl: 'http://test/api', client: client))..utilisateur = Profil.depuisJson(_profil());

Future<void> _ouvrir(WidgetTester tester, Session session, {ChoisirImage? choisirImage}) async {
  // Écran de téléphone (412 × 915) : tout le formulaire est visible.
  tester.view.physicalSize = const Size(1236, 2745);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  final routeur = GoRouter(initialLocation: '/profil', routes: [
    GoRoute(path: '/profil', builder: (_, _) => const Scaffold(body: Text('Page profil'))),
    GoRoute(
      path: '/profil/modifier',
      builder: (_, _) => choisirImage == null ? const ModifierProfilPage() : ModifierProfilPage(choisirImage: choisirImage),
    ),
  ]);
  await tester.pumpWidget(ChangeNotifierProvider.value(value: session, child: MaterialApp.router(routerConfig: routeur)));
  routeur.push('/profil/modifier');
  await tester.pumpAndSettle();
}

void main() {
  test('modifierProfil : PUT /moi avec le sexe inchangé et une présentation vide envoyée à null', () async {
    Map<String, dynamic>? corps;
    final session = _session(MockClient((r) async {
      expect(r.method, 'PUT');
      expect(r.url.path, '/api/moi');
      corps = jsonDecode(r.body) as Map<String, dynamic>;
      return _json(_profil(prenom: 'Aïda', nom: 'Fall'));
    }));

    await session.modifierProfil(prenom: ' Aïda ', nom: 'Fall ', bio: '   ');
    expect(corps, {'prenom': 'Aïda', 'nom': 'Fall', 'bio': null, 'sexe': 'FEMME'});
    expect(session.utilisateur!.nomComplet, 'Aïda Fall');
  });

  test('changerPhoto : envoi multipart du champ « fichier », profil remplacé', () async {
    final session = _session(MockClient((r) async {
      expect(r.method, 'POST');
      expect(r.url.path, '/api/moi/photo');
      expect(r.headers['content-type'], startsWith('multipart/form-data'));
      final corps = latin1.decode(r.bodyBytes);
      expect(corps, contains('name="fichier"; filename="photo.jpg"'));
      return _json(_profil(photo: '/api/fichiers/photos/abc.jpg'));
    }));

    await session.changerPhoto([0xFF, 0xD8, 0xFF, 0xE0], 'photo.jpg');
    expect(session.utilisateur!.photoProfil, '/api/fichiers/photos/abc.jpg');
  });

  testWidgets('enregistre prénom, nom et présentation puis revient au profil', (tester) async {
    Map<String, dynamic>? corps;
    final session = _session(MockClient((r) async {
      corps = jsonDecode(r.body) as Map<String, dynamic>;
      return _json(_profil(prenom: corps!['prenom'] as String, nom: corps!['nom'] as String, bio: corps!['bio'] as String?));
    }));
    await _ouvrir(tester, session);

    expect(find.text('Awa'), findsOneWidget);
    expect(find.text('+221771234567'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('prenom')), '');
    await tester.tap(find.text('Enregistrer'));
    await tester.pump();
    expect(find.text('Prénom obligatoire.'), findsOneWidget);
    expect(corps, isNull);

    await tester.enterText(find.byKey(const Key('prenom')), 'Aïda');
    await tester.enterText(find.byKey(const Key('bio')), 'Dakar – Thiès chaque lundi.');
    await tester.tap(find.text('Enregistrer'));
    await tester.pumpAndSettle();

    expect(corps, {'prenom': 'Aïda', 'nom': 'Diop', 'bio': 'Dakar – Thiès chaque lundi.', 'sexe': 'FEMME'});
    expect(session.utilisateur!.bio, 'Dakar – Thiès chaque lundi.');
    expect(find.text('Page profil'), findsOneWidget);
    expect(find.text('Profil mis à jour.'), findsOneWidget);
  });

  testWidgets('affiche l\'erreur du serveur sous le bon champ', (tester) async {
    final session = _session(MockClient((r) async => _json({
          'detail': 'Données invalides',
          'erreurs': {'nom': 'Le nom est trop long'},
        }, 400)));
    await _ouvrir(tester, session);

    await tester.tap(find.text('Enregistrer'));
    await tester.pumpAndSettle();
    expect(find.text('Le nom est trop long'), findsOneWidget);
    expect(find.text('Données invalides'), findsOneWidget);
  });

  testWidgets('photo trop lourde refusée sans appel au serveur', (tester) async {
    var appels = 0;
    final session = _session(MockClient((r) async {
      appels++;
      return _json(_profil());
    }));
    ImageSource? sourceDemandee;
    await _ouvrir(tester, session, choisirImage: (source) async {
      sourceDemandee = source;
      return XFile.fromData(Uint8List(tailleMaxPhoto + 1), name: 'grande.jpg');
    });

    await tester.tap(find.byTooltip('Changer la photo de profil'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Choisir dans la galerie'));
    await tester.pumpAndSettle();

    expect(sourceDemandee, ImageSource.gallery);
    expect(find.text('La photo dépasse 5 Mo. Choisissez une image plus légère.'), findsOneWidget);
    expect(appels, 0);
  });
}
