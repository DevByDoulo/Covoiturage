import 'package:flutter/foundation.dart';

/// Adresse de l'API. Par défaut : le backend lancé en local sur le port 8080.
/// L'émulateur Android voit le PC sous l'adresse 10.0.2.2 ; un vrai téléphone doit utiliser l'adresse IP du PC
/// sur le Wi-Fi : `flutter run --dart-define=API_URL=http://192.168.1.20:8080/api`.
class Config {
  static const String _apiDefinie = String.fromEnvironment('API_URL');

  static String get apiUrl {
    if (_apiDefinie.isNotEmpty) return _apiDefinie;
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) return 'http://10.0.2.2:8080/api';
    return 'http://localhost:8080/api';
  }

  /// Racine du serveur, pour les fichiers (photos de profil : « /api/fichiers/photos/… »).
  static String get serveurUrl => apiUrl.replaceFirst(RegExp(r'/api/?$'), '');

  static String? urlFichier(String? chemin) => chemin == null ? null : '$serveurUrl$chemin';
}
