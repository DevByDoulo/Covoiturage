import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:yobalema/core/api.dart';
import 'package:yobalema/core/formats.dart';
import 'package:yobalema/core/modeles.dart';
import 'package:yobalema/features/avis/avis.dart';

http.Response _json(Object corps, [int status = 200]) =>
    http.Response.bytes(utf8.encode(jsonEncode(corps)), status, headers: {'content-type': 'application/json'});

void main() {
  setUpAll(() => initializeDateFormatting('fr_FR'));

  group('formats', () {
    test('montants, durées et distances', () {
      expect(fcfa(1650).replaceAll(RegExp(r'\s'), ' '), '1 650 FCFA');
      expect(duree(40), '40 min');
      expect(duree(75), '1 h 15');
      expect(duree(120), '2 h');
      expect(distance(450), '450 m');
      expect(distance(1300), '1,3 km');
    });

    test('décode un tracé Google (exemple de la documentation)', () {
      final points = decoderPolyline('_p~iF~ps|U_ulLnnqC_mqNvxq`@');
      expect(points, hasLength(3));
      expect(points.first.$1, closeTo(38.5, 1e-5));
      expect(points.first.$2, closeTo(-120.2, 1e-5));
      expect(points.last.$1, closeTo(43.252, 1e-5));
      expect(points.last.$2, closeTo(-126.453, 1e-5));
      expect(decoderPolyline(null), isEmpty);
    });
  });

  group('modèles', () {
    test('lit un trajet de la recherche', () {
      final t = Trajet.depuisJson({
        'id': 3,
        'conducteur': {'id': 2, 'prenom': 'Awa', 'nomInitiale': 'D.', 'photoProfil': null, 'noteMoyenne': 4.5},
        'vehicule': {'id': 1, 'marque': 'Toyota', 'modele': 'Corolla', 'annee': 2019},
        'depart': {'lieu': 'Dakar', 'latitude': 14.66, 'longitude': -17.43},
        'arrivee': {'lieu': 'Thiès', 'latitude': 14.79, 'longitude': -16.92},
        'escales': [],
        'dateHeureDepart': '2026-11-06T08:00:00',
        'flexibiliteMinutes': 20,
        'nombrePlacesTotal': 3,
        'nombrePlacesDisponibles': 2,
        'modeReservation': 'AUTOMATIQUE',
        'tailleBagage': 'MOYEN',
        'femmesUniquement': false,
        'distanceKm': 68.01,
        'dureeEstimeeMin': 63,
        'prixParPlace': 2100,
        'statut': 'PUBLIE',
        'correspondance': {
          'distanceRamassageM': 900,
          'distanceDeposeM': 450,
          'latitudeRamassage': 14.67,
          'longitudeRamassage': -17.42,
          'latitudeDepose': 14.78,
          'longitudeDepose': -16.93,
        },
      });
      expect(t.vehicule, 'Toyota Corolla (2019)');
      expect(t.reservable, isTrue);
      expect(t.correspondance!.distanceRamassageM, 900);
      expect(t.conducteur.noteMoyenne, 4.5);
    });

    test('paiement en ligne attendu seulement pour une réservation acceptée et non réglée', () {
      Reservation r(String statut, String moyen, String paiement) => Reservation.depuisJson({
            'id': 1,
            'trajet': {
              'id': 3,
              'lieuDepart': 'Dakar',
              'lieuArrivee': 'Thiès',
              'dateHeureDepart': '2026-11-06T08:00:00',
              'statut': 'PUBLIE',
              'conducteur': {'id': 2, 'prenom': 'Awa', 'nomInitiale': 'D.'},
            },
            'nombrePlaces': 1,
            'montantTotal': 2100,
            'statut': statut,
            'moyenPaiement': moyen,
            'statutPaiement': paiement,
            'embarque': false,
          });
      expect(r('ACCEPTEE', 'ORANGE_MONEY', 'EN_ATTENTE').aPayerEnLigne, isTrue);
      expect(r('ACCEPTEE', 'ORANGE_MONEY', 'REUSSI').aPayerEnLigne, isFalse);
      expect(r('EN_ATTENTE', 'WAVE', 'EN_ATTENTE').aPayerEnLigne, isFalse);
      expect(r('ACCEPTEE', 'ESPECES', 'EN_ATTENTE').aPayerEnLigne, isFalse);
    });
  });

  group('conducteur', () {
    test('date et heure de départ au format LocalDateTime', () {
      expect(dateHeureApi(DateTime(2026, 11, 7, 8, 5)), '2026-11-07T08:05:00');
    });

    test("lit l'estimation du prix", () {
      final e = Estimation.depuisJson({
        'distanceKm': 70.2,
        'dureeEstimeeMin': 65,
        'typeRoute': 'NATIONALE',
        'montantPeages': 0,
        'sourceItineraire': 'ESTIMATION',
        'itinerairePolyline': '_p~iF~ps|U',
        'tarif': {
          'prixRecommande': 2100,
          'prixMin': 1900,
          'prixMax': 2300,
          'coutCarburant': 5600.5,
          'coutUsure': 700,
          'coutPeages': 0,
          'facteurMeteo': 1.06,
          'sourceConsommation': 'IA',
          'heureDePointe': true,
        },
      });
      expect(e.prixRecommande, 2100);
      expect(e.prixMin, 1900);
      expect(e.prixMax, 2300);
      expect(e.facteurMeteo, closeTo(1.06, 1e-9));
      expect(e.heureDePointe, isTrue);
    });

    test('réservation vue par le conducteur et embarquement confirmé', () {
      final r = Reservation.depuisJson({
        'id': 9,
        'trajet': {
          'id': 3,
          'lieuDepart': 'Dakar',
          'lieuArrivee': 'Louga',
          'dateHeureDepart': '2026-11-06T08:00:00',
          'statut': 'PUBLIE',
          'conducteur': {'id': 2, 'prenom': 'Awa', 'nomInitiale': 'D.'},
        },
        'passager': {'id': 5, 'prenom': 'Moussa', 'nomInitiale': 'N.'},
        'pointRamassage': 'Gare de Dakar',
        'nombrePlaces': 1,
        'montantTotal': 4700,
        'statut': 'EN_ATTENTE',
        'embarque': false,
      });
      expect(r.passager!.prenom, 'Moussa');
      expect(r.pointRamassage, 'Gare de Dakar');

      final e = EmbarquementConfirme.depuisJson({
        'idReservation': 9,
        'passager': {'id': 5, 'prenom': 'Moussa', 'nomInitiale': 'N.'},
        'nombrePlaces': 1,
        'montantAEncaisser': 4700,
        'moyenPaiement': 'ESPECES',
      });
      expect(e.montantAEncaisser, 4700);
      expect(Vehicule.depuisJson({
        'id': 1,
        'immatriculation': 'DK-1234-AB',
        'marque': 'Toyota',
        'modele': 'Corolla',
        'annee': 2019,
        'nombrePlaces': 5,
        'statutValidation': 'VALIDE',
      }).valide, isTrue);
    });
  });

  group('messagerie', () {
    test('lit une conversation ouverte et une conversation fermée', () {
      Map<String, dynamic> conversation(String? fermeture) => {
            'id': 4,
            'trajet': {
              'id': 3,
              'lieuDepart': 'Dakar',
              'lieuArrivee': 'Louga',
              'dateHeureDepart': '2026-11-06T08:00:00',
              'statut': 'PUBLIE',
            },
            'interlocuteur': {'id': 2, 'prenom': 'Awa', 'nomInitiale': 'D.'},
            'jeSuisConducteur': false,
            'fermeture': fermeture,
            'messages': [
              {'id': 1, 'contenu': 'Bonjour', 'dateEnvoi': '2026-11-05T10:00:00', 'deMoi': true, 'lu': true},
              {'id': 2, 'contenu': 'Bonjour Moussa', 'dateEnvoi': '2026-11-05T10:02:00', 'deMoi': false, 'lu': false},
            ],
          };
      final ouverte = ConversationDetail.depuisJson(conversation(null));
      expect(ouverte.fermeture, isNull);
      expect(ouverte.messages.map((m) => m.deMoi), [true, false]);
      expect(ouverte.interlocuteur.prenom, 'Awa');
      expect(ConversationDetail.depuisJson(conversation('Conversation fermée')).fermeture, 'Conversation fermée');

      final resume = ConversationResume.depuisJson({
        'id': 4,
        'trajet': conversation(null)['trajet'],
        'interlocuteur': {'id': 2, 'prenom': 'Awa', 'nomInitiale': 'D.'},
        'jeSuisConducteur': false,
        'dernierMessage': null,
        'dernierDeMoi': false,
        'dateDernierMessage': null,
        'nonLus': 0,
      });
      expect(resume.dateDernierMessage, isNull);
    });
  });

  group('avis', () {
    test('lit un avis à donner et une réputation', () {
      final a = AvisADonner.depuisJson({
        'idReservation': 11,
        'idTrajet': 10,
        'trajet': 'Gare de Dakar → Rufisque',
        'dateHeureDepart': '2026-11-06T14:00:00',
        'aNoter': {'id': 2, 'prenom': 'Awa', 'nomInitiale': 'D.'},
        'role': 'CONDUCTEUR',
        'dateLimite': '2026-11-20T14:00:00',
      });
      expect(a.idReservation, 11);
      expect(a.aNoter.prenom, 'Awa');

      final r = Reputation.depuisJson({
        'idUtilisateur': 2,
        'noteMoyenne': 4.5,
        'nombreAvis': 2,
        'repartition': [0, 0, 0, 1, 1],
        'avis': [
          {
            'id': 1,
            'note': 5,
            'commentaire': 'Très ponctuelle',
            'dateEvaluation': '2026-11-06T15:00:00',
            'auteur': {'id': 5, 'prenom': 'Moussa', 'nomInitiale': 'N.'},
            'roleEvalue': 'CONDUCTEUR',
            'trajet': 'Gare de Dakar → Rufisque',
          },
        ],
      });
      expect(r.noteMoyenne, 4.5);
      expect(r.repartition, [0, 0, 0, 1, 1]);
      expect(r.avis.single.commentaire, 'Très ponctuelle');
      expect(noteTexte(4.5), '4,5');
      expect(Reputation.depuisJson({'nombreAvis': 0, 'repartition': [0, 0, 0, 0, 0], 'avis': []}).noteMoyenne, isNull);
    });
  });

  group('Api', () {
    test("lit le message d'erreur du ProblemDetail", () async {
      final api = Api(
        baseUrl: 'http://api.test/api',
        client: MockClient((_) async => _json({'detail': 'Code incorrect', 'tentativesRestantes': 4}, 400)),
      );
      await expectLater(
        api.postPublic('/auth/otp/verifier', {'identifiant': '771234567', 'code': '000000'}),
        throwsA(isA<ErreurApi>()
            .having((e) => e.message, 'message', 'Code incorrect')
            .having((e) => e.tentativesRestantes, 'tentatives', 4)),
      );
    });

    test("renouvelle le jeton d'accès une fois sur 401, puis rejoue la requête", () async {
      final jetonsVus = <String?>[];
      final api = Api(
        baseUrl: 'http://api.test/api',
        client: MockClient((requete) async {
          jetonsVus.add(requete.headers['Authorization']);
          return requete.headers['Authorization'] == 'Bearer neuf'
              ? _json({'nombre': 3})
              : _json({'detail': 'Jeton expiré'}, 401);
        }),
      )..accessToken = 'ancien';
      var renouvellements = 0;
      api.renouveler = () async {
        renouvellements++;
        return api.accessToken = 'neuf';
      };

      final r = await api.get('/moi/notifications/non-lues') as Map<String, dynamic>;

      expect(r['nombre'], 3);
      expect(renouvellements, 1);
      expect(jetonsVus, ['Bearer ancien', 'Bearer neuf']);
    });

    test('session perdue : le 401 remonte sans boucle', () async {
      var appels = 0;
      final api = Api(
        baseUrl: 'http://api.test/api',
        client: MockClient((_) async {
          appels++;
          return _json({'detail': 'Session expirée'}, 401);
        }),
      )..renouveler = () async => null;

      await expectLater(api.get('/moi'), throwsA(isA<ErreurApi>().having((e) => e.status, 'status', 401)));
      expect(appels, 1);
    });
  });
}
