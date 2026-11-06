import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'api.dart';
import 'modeles.dart';

/// Session de l'utilisateur : jetons (le refresh token est gardé dans le stockage sécurisé du téléphone)
/// et profil. Même fonctionnement que SessionService du site web.
class Session extends ChangeNotifier {
  Session(this.api, {FlutterSecureStorage? stockage}) : _stockage = stockage ?? const FlutterSecureStorage() {
    api.renouveler = _renouveler;
  }

  static const _cleRefresh = 'covoitia.refresh';

  final Api api;
  final FlutterSecureStorage _stockage;

  Profil? utilisateur;

  /// Faux tant que la session n'a pas été restaurée au démarrage.
  bool pret = false;

  bool get connecte => utilisateur != null;

  /// Au démarrage : rouvre la session avec le refresh token enregistré.
  Future<void> restaurer() async {
    try {
      if (await _renouveler() != null) await chargerProfil();
    } catch (_) {
      // Pas de réseau : l'utilisateur se reconnectera.
    }
    pret = true;
    notifyListeners();
  }

  Future<void> chargerProfil() async {
    utilisateur = Profil.depuisJson(await api.get('/moi') as Map<String, dynamic>);
    notifyListeners();
  }

  /// Jeton et profil frais : le rôle CONDUCTEUR ou la validation des documents ont pu changer depuis la connexion.
  Future<void> rafraichir() async {
    await _renouveler();
    await chargerProfil();
  }

  Future<AuthReponse> connexion(String identifiant, String motDePasse) =>
      _authentifier('/auth/connexion', {'identifiant': identifiant.trim(), 'motDePasse': motDePasse});

  Future<AuthReponse> inscription(Map<String, dynamic> donnees) => _authentifier('/auth/inscription', donnees);

  Future<AuthReponse> verifierCode(String identifiant, String code) =>
      _authentifier('/auth/otp/verifier', {'identifiant': identifiant, 'code': code});

  Future<AuthReponse> renvoyerCode(String identifiant) =>
      _authentifier('/auth/otp/renvoyer', {'identifiant': identifiant});

  Future<void> deconnexion() async {
    final refresh = await _stockage.read(key: _cleRefresh);
    if (refresh != null) {
      try {
        await api.postPublic('/auth/deconnexion', {'refreshToken': refresh});
      } catch (_) {}
    }
    await _oublier();
  }

  Future<AuthReponse> _authentifier(String chemin, Map<String, dynamic> corps) async {
    final r = AuthReponse.depuisJson(await api.postPublic(chemin, corps) as Map<String, dynamic>);
    if (r.connecte) {
      api.accessToken = r.accessToken;
      await _stockage.write(key: _cleRefresh, value: r.refreshToken);
      utilisateur = r.utilisateur;
      notifyListeners();
    }
    return r;
  }

  /// Renouvelle le jeton d'accès (le refresh token est à usage unique : on garde le nouveau).
  Future<String?> _renouveler() async {
    final refresh = await _stockage.read(key: _cleRefresh);
    if (refresh == null) return null;
    try {
      final r = AuthReponse.depuisJson(
          await api.postPublic('/auth/refresh', {'refreshToken': refresh}) as Map<String, dynamic>);
      api.accessToken = r.accessToken;
      await _stockage.write(key: _cleRefresh, value: r.refreshToken);
      return r.accessToken;
    } on ErreurApi {
      await _oublier();
      return null;
    }
  }

  Future<void> _oublier() async {
    api.accessToken = null;
    utilisateur = null;
    await _stockage.delete(key: _cleRefresh);
    notifyListeners();
  }
}
