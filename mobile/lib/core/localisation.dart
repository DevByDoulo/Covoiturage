import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

import 'modeles.dart';

/// 08 — Adresse ↔ coordonnées avec OpenStreetMap (Nominatim, sans clé), comme le site web.
/// Règle d'usage Nominatim : une recherche à la validation (jamais à chaque frappe), une requête par seconde au plus.
class Geocodage {
  Geocodage({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;
  static const _api = 'https://nominatim.openstreetmap.org';
  DateTime _prochainAppel = DateTime.fromMillisecondsSinceEpoch(0);

  Map<String, String> get _entetes => {
        'Accept-Language': 'fr',
        // Nominatim demande d'identifier l'application (le navigateur fixe lui-même cet en-tête sur le web).
        if (!kIsWeb) 'User-Agent': 'YOBALEMAsn/1.0 (application mobile, projet de fin d etudes)',
      };

  Future<List<Lieu>> rechercher(String texte) async {
    final q = texte.trim();
    if (q.length < 2) return const [];
    await _espacer();
    try {
      final r = await _client.get(
          Uri.parse('$_api/search').replace(queryParameters: {
            'q': q,
            'format': 'jsonv2',
            'countrycodes': 'sn',
            'limit': '6',
          }),
          headers: _entetes);
      if (r.statusCode != 200) return const [];
      return (jsonDecode(utf8.decode(r.bodyBytes)) as List).map((e) => _versLieu(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return const [];
    }
  }

  Future<String?> adresseDe(double latitude, double longitude) async {
    await _espacer();
    try {
      final r = await _client.get(
          Uri.parse('$_api/reverse').replace(queryParameters: {
            'lat': '$latitude',
            'lon': '$longitude',
            'format': 'jsonv2',
            'zoom': '17',
          }),
          headers: _entetes);
      if (r.statusCode != 200) return null;
      final j = jsonDecode(utf8.decode(r.bodyBytes)) as Map<String, dynamic>;
      return j['display_name'] == null ? null : _versLieu(j).libelle;
    } catch (_) {
      return null;
    }
  }

  Future<void> _espacer() async {
    final attente = _prochainAppel.difference(DateTime.now());
    if (!attente.isNegative) await Future<void>.delayed(attente);
    _prochainAppel = DateTime.now().add(const Duration(milliseconds: 1100));
  }

  static Lieu _versLieu(Map<String, dynamic> j) {
    final morceaux = (j['display_name'] as String).split(', ');
    final nom = (j['name'] as String?)?.isNotEmpty == true ? j['name'] as String : morceaux.first;
    return Lieu(nom, double.parse('${j['lat']}'), double.parse('${j['lon']}'),
        detail: morceaux.skip(1).take(3).join(', '));
  }
}

/// Position suivie en continu ; cap en degrés (0 = nord) et vitesse en m/s si l'appareil les connaît.
typedef PositionSuivie = ({double latitude, double longitude, int precisionM, double? cap, double? vitesse});

/// Position du téléphone (GPS). Le système demande l'autorisation à l'utilisateur la première fois.
class PositionActuelle {
  /// Au-delà, la position vient du réseau plutôt que du GPS : à vérifier par l'utilisateur.
  static const precisionApproximativeM = 500;

  Future<void> _autoriser() async {
    // Navigateur : il demande lui-même l'autorisation au premier accès à la position (l'API Permissions n'est pas
    // fiable partout) ; un refus arrive alors comme erreur du suivi.
    if (kIsWeb) return;
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw const LocalisationImpossible('La localisation est désactivée sur le téléphone. Activez-la, ou saisissez l\'adresse.');
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
      throw const LocalisationImpossible(
          'Accès à votre position refusé. Autorisez-le dans les réglages, ou saisissez l\'adresse.');
    }
  }

  /// Suivi continu (guidage, partage de position). [arrierePlan] : le suivi continue écran éteint ou appli en
  /// arrière-plan (Android : service avec une notification permanente ; iOS : localisation en arrière-plan).
  Stream<PositionSuivie> suivre({bool arrierePlan = false}) async* {
    await _autoriser();
    final LocationSettings reglages;
    if (kIsWeb) {
      reglages = const LocationSettings(accuracy: LocationAccuracy.high);
    } else if (defaultTargetPlatform == TargetPlatform.android) {
      reglages = AndroidSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5,
        foregroundNotificationConfig: arrierePlan
            ? const ForegroundNotificationConfig(
                notificationTitle: 'YOBALEMAsn partage votre position',
                notificationText: 'Vos passagers suivent votre arrivée. Arrêtez le partage depuis votre trajet.',
                enableWakeLock: true,
              )
            : null,
      );
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      reglages = AppleSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 5,
        activityType: ActivityType.automotiveNavigation,
        allowBackgroundLocationUpdates: arrierePlan,
        showBackgroundLocationIndicator: arrierePlan,
        pauseLocationUpdatesAutomatically: false,
      );
    } else {
      reglages = const LocationSettings(accuracy: LocationAccuracy.high, distanceFilter: 5);
    }
    yield* Geolocator.getPositionStream(locationSettings: reglages)
        .map((p) => (
              latitude: p.latitude,
              longitude: p.longitude,
              precisionM: p.accuracy.round(),
              cap: p.heading >= 0 ? p.heading : null,
              vitesse: p.speed >= 0 ? p.speed : null,
            ))
        .handleError((Object e) => throw e is PermissionDeniedException
            ? const LocalisationImpossible('Accès à votre position refusé. Autorisez-le dans les réglages du navigateur ou du téléphone.')
            : const LocalisationImpossible('Votre position est introuvable pour le moment (GPS ou réseau). Réessayez.'));
  }

  Future<({double latitude, double longitude, int precisionM})> localiser() async {
    await _autoriser();
    try {
      final p = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, timeLimit: Duration(seconds: 15)));
      return (latitude: p.latitude, longitude: p.longitude, precisionM: p.accuracy.round());
    } catch (_) {
      throw const LocalisationImpossible('Votre position est introuvable pour le moment. Réessayez, ou saisissez l\'adresse.');
    }
  }
}

class LocalisationImpossible implements Exception {
  const LocalisationImpossible(this.message);

  final String message;

  @override
  String toString() => message;
}
