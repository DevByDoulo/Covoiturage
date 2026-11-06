import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'config.dart';

/// Erreur normalisée à partir du ProblemDetail renvoyé par le backend (champ « detail », « champ », « erreurs »…).
class ErreurApi implements Exception {
  ErreurApi(this.status, this.message, {this.champ, this.erreurs = const {}, this.tentativesRestantes});

  final int status;
  final String message;

  /// Champ du formulaire concerné (ex. « email » quand l'adresse est déjà utilisée).
  final String? champ;

  /// Erreurs de validation par champ (400).
  final Map<String, String> erreurs;
  final int? tentativesRestantes;

  factory ErreurApi.depuisReponse(http.Response r) {
    Map<String, dynamic> corps = const {};
    try {
      final decode = jsonDecode(utf8.decode(r.bodyBytes));
      if (decode is Map<String, dynamic>) corps = decode;
    } catch (_) {}
    final erreurs = <String, String>{};
    final brutes = corps['erreurs'];
    if (brutes is Map) brutes.forEach((k, v) => erreurs['$k'] = '$v');
    return ErreurApi(
      r.statusCode,
      (corps['detail'] as String?) ?? _messageParDefaut(r.statusCode),
      champ: corps['champ'] as String?,
      erreurs: erreurs,
      tentativesRestantes: (corps['tentativesRestantes'] as num?)?.toInt(),
    );
  }

  static String _messageParDefaut(int status) {
    if (status == 401) return 'Session expirée, veuillez vous reconnecter.';
    if (status == 403) return "Vous n'avez pas accès à cette action.";
    if (status == 404) return 'Élément introuvable.';
    if (status == 429) return 'Trop de tentatives. Réessayez plus tard.';
    if (status >= 500) return 'Le service est momentanément indisponible.';
    return 'La requête a échoué.';
  }

  /// Message à afficher pour n'importe quelle erreur (réseau compris).
  static String messageDe(Object e) {
    if (e is ErreurApi) return e.message;
    if (e is TimeoutException) return 'Le serveur met trop de temps à répondre. Réessayez.';
    return 'Impossible de joindre le serveur. Vérifiez votre connexion.';
  }

  @override
  String toString() => message;
}

/// Client de l'API : ajoute le jeton d'accès, et le renouvelle une fois (refresh) quand il a expiré.
class Api {
  Api({http.Client? client, String? baseUrl})
      : _client = client ?? http.Client(),
        _base = baseUrl ?? Config.apiUrl;

  final http.Client _client;
  final String _base;
  static const _delai = Duration(seconds: 20);

  String? accessToken;

  /// Fourni par la session : renouvelle le jeton d'accès et renvoie le nouveau, ou null si la session est perdue.
  Future<String?> Function()? renouveler;
  Future<String?>? _renouvellementEnCours;

  Future<dynamic> get(String chemin, {Map<String, Object?>? query}) => _envoyer('GET', chemin, query: query);

  Future<dynamic> post(String chemin, [Object? corps]) => _envoyer('POST', chemin, corps: corps);

  Future<dynamic> put(String chemin, [Object? corps]) => _envoyer('PUT', chemin, corps: corps);

  Future<dynamic> delete(String chemin) => _envoyer('DELETE', chemin);

  /// Appel sans jeton et sans renouvellement (connexion, inscription, refresh).
  Future<dynamic> postPublic(String chemin, Object? corps) => _envoyer('POST', chemin, corps: corps, authentifie: false);

  Future<dynamic> _envoyer(String methode, String chemin,
      {Map<String, Object?>? query, Object? corps, bool authentifie = true, bool deuxiemeEssai = false}) async {
    final params = <String, String>{};
    query?.forEach((k, v) {
      if (v != null && '$v'.isNotEmpty) params[k] = '$v';
    });
    final uri = Uri.parse('$_base$chemin').replace(queryParameters: params.isEmpty ? null : params);
    final requete = http.Request(methode, uri)
      ..headers['Accept'] = 'application/json'
      ..headers['Accept-Language'] = 'fr';
    if (corps != null) {
      requete.headers['Content-Type'] = 'application/json';
      requete.body = jsonEncode(corps);
    }
    if (authentifie && accessToken != null) requete.headers['Authorization'] = 'Bearer $accessToken';

    final reponse = await http.Response.fromStream(await _client.send(requete).timeout(_delai));

    if (reponse.statusCode == 401 && authentifie && !deuxiemeEssai && renouveler != null) {
      _renouvellementEnCours ??= renouveler!().whenComplete(() => _renouvellementEnCours = null);
      final nouveau = await _renouvellementEnCours;
      if (nouveau != null) {
        return _envoyer(methode, chemin, query: query, corps: corps, deuxiemeEssai: true);
      }
    }
    if (reponse.statusCode >= 400) throw ErreurApi.depuisReponse(reponse);
    if (reponse.bodyBytes.isEmpty) return null;
    return jsonDecode(utf8.decode(reponse.bodyBytes));
  }
}
