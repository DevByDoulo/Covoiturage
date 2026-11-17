import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import 'api.dart';

/// Écran de l'application à ouvrir pour le lien d'une notification (liens du site, voir le module 06 du backend).
class Destination {
  const Destination(this.chemin, {this.empiler = false});

  final String chemin;

  /// Vrai : l'écran s'ouvre par-dessus l'onglet courant (retour possible). Faux : on change d'onglet.
  final bool empiler;

  @override
  bool operator ==(Object other) => other is Destination && other.chemin == chemin && other.empiler == empiler;

  @override
  int get hashCode => Object.hash(chemin, empiler);

  @override
  String toString() => 'Destination($chemin, empiler: $empiler)';
}

/// Liens du site → écrans mobiles. Un lien sans équivalent (ex. « /vehicules », géré sur le site) ouvre les
/// notifications.
Destination destinationPour(String? lien) {
  final l = lien ?? '';
  if (RegExp(r'^/trajets/\d+(/(suivi|guidage))?$').hasMatch(l)) return Destination(l, empiler: true);
  if (RegExp(r'^/messages(/\d+)?$').hasMatch(l)) return Destination(l, empiler: true);
  if (l == '/signalements') return Destination(l, empiler: true);
  if (l.startsWith('/reservations')) return const Destination('/reservations');
  if (l == '/profil') return const Destination('/profil');
  return const Destination('/notifications');
}

/// Notification push reçue (application ouverte) ou touchée par l'utilisateur.
class MessagePush {
  const MessagePush({required this.titre, required this.contenu, this.lien});

  final String titre;
  final String contenu;
  final String? lien;

  static MessagePush depuis(RemoteMessage m) => MessagePush(
        titre: m.notification?.title ?? m.data['titre'] as String? ?? 'YOBALEMAsn',
        contenu: m.notification?.body ?? m.data['contenu'] as String? ?? '',
        lien: m.data['lien'] as String?,
      );
}

/// Accès à Firebase Cloud Messaging, remplacé par un faux dans les tests.
abstract class PlateformePush {
  /// Faux si Firebase n'est pas configuré (pas de google-services.json, navigateur) : le push est désactivé.
  Future<bool> initialiser();

  /// Android 13+ : fenêtre système « Autoriser les notifications ». Vrai si elles sont autorisées.
  Future<bool> demanderPermission();

  Future<String?> jeton();

  Future<void> supprimerJeton();

  Stream<String> get nouveauxJetons;

  /// Notification qui a lancé l'application (appli fermée), ou null.
  Future<MessagePush?> messageInitial();

  /// Notification touchée alors que l'application était en arrière-plan.
  Stream<MessagePush> get ouverts;

  /// Notification reçue pendant que l'application est à l'écran (le système ne l'affiche pas).
  Stream<MessagePush> get premierPlan;

  /// « ANDROID » ou « IOS » (valeurs de PlateformeAppareil côté API).
  String get nom;
}

class PlateformeFirebase implements PlateformePush {
  FirebaseMessaging get _fcm => FirebaseMessaging.instance;

  @override
  Future<bool> initialiser() async {
    if (kIsWeb) return false; // le site a son propre push ; l'appli lancée dans un navigateur n'en a pas
    try {
      await Firebase.initializeApp();
      return true;
    } catch (e) {
      debugPrint('Firebase non configuré, notifications push désactivées : $e');
      return false;
    }
  }

  @override
  Future<bool> demanderPermission() async {
    final r = await _fcm.requestPermission();
    return r.authorizationStatus == AuthorizationStatus.authorized ||
        r.authorizationStatus == AuthorizationStatus.provisional;
  }

  // Jeton d'enregistrement FCM classique : c'est la cible de Message.setToken() du SDK Admin Java (backend).
  // firebase_messaging 17 le marque « deprecated » au profit des identifiants d'installation (register / FID),
  // que le backend n'utilise pas.
  @override
  // ignore: deprecated_member_use
  Future<String?> jeton() => _fcm.getToken();

  @override
  // ignore: deprecated_member_use
  Future<void> supprimerJeton() => _fcm.deleteToken();

  @override
  // ignore: deprecated_member_use
  Stream<String> get nouveauxJetons => _fcm.onTokenRefresh;

  @override
  Future<MessagePush?> messageInitial() async {
    final m = await _fcm.getInitialMessage();
    return m == null ? null : MessagePush.depuis(m);
  }

  @override
  Stream<MessagePush> get ouverts => FirebaseMessaging.onMessageOpenedApp.map(MessagePush.depuis);

  @override
  Stream<MessagePush> get premierPlan => FirebaseMessaging.onMessage.map(MessagePush.depuis);

  @override
  String get nom => defaultTargetPlatform == TargetPlatform.iOS ? 'IOS' : 'ANDROID';
}

/// Notifications push (module 06) : le jeton de l'appareil est enregistré après la connexion
/// (`POST /moi/appareils`) et retiré à la déconnexion (`DELETE /moi/appareils/{jeton}`).
class ServicePush {
  ServicePush(this.api, [PlateformePush? plateforme]) : plateforme = plateforme ?? PlateformeFirebase();

  final Api api;
  final PlateformePush plateforme;

  bool _disponible = false;
  bool _connecte = false;
  String? _jeton;
  MessagePush? _initial;
  final _abonnements = <StreamSubscription<Object?>>[];

  /// Appelés par l'application : ouvrir l'écran d'une notification touchée, afficher une notification reçue
  /// pendant que l'application est à l'écran.
  void Function(MessagePush)? surOuverture;
  void Function(MessagePush)? surPremierPlan;

  bool get disponible => _disponible;

  Future<void> demarrer() async {
    try {
      _disponible = await plateforme.initialiser();
    } catch (_) {
      _disponible = false;
    }
    if (!_disponible) return;
    _abonnements
      ..add(plateforme.ouverts.listen((m) => surOuverture?.call(m)))
      ..add(plateforme.premierPlan.listen((m) => surPremierPlan?.call(m)))
      ..add(plateforme.nouveauxJetons.listen((j) {
        if (_connecte) _enregistrer(j);
      }));
    _initial = await plateforme.messageInitial();
  }

  /// La notification qui a lancé l'application, une seule fois.
  MessagePush? prendreMessageInitial() {
    final m = _initial;
    _initial = null;
    return m;
  }

  /// Après la connexion : permission (Android 13+), jeton, enregistrement auprès de l'API.
  /// Faux si le push est indisponible ou refusé.
  Future<bool> activer() async {
    _connecte = true;
    if (!_disponible) return false;
    try {
      if (!await plateforme.demanderPermission()) return false;
      final j = await plateforme.jeton();
      if (j == null || !_connecte) return false;
      await _enregistrer(j);
      return true;
    } catch (e) {
      debugPrint('Notifications push non activées : $e');
      return false;
    }
  }

  /// Avant la déconnexion (le jeton d'accès est encore valable) : cet appareil ne reçoit plus rien pour ce compte.
  Future<void> desactiver() async {
    _connecte = false;
    final j = _jeton;
    _jeton = null;
    if (!_disponible) return;
    if (j != null) {
      try {
        await api.delete('/moi/appareils/${Uri.encodeComponent(j)}');
      } catch (_) {}
    }
    await _supprimerJetonLocal();
  }

  /// Session perdue sans déconnexion (jeton expiré) : le jeton local est invalidé, le serveur l'effacera
  /// au prochain envoi refusé par Firebase.
  Future<void> oublier() async {
    if (!_connecte) return;
    _connecte = false;
    _jeton = null;
    if (_disponible) await _supprimerJetonLocal();
  }

  Future<void> _supprimerJetonLocal() async {
    try {
      await plateforme.supprimerJeton();
    } catch (_) {}
  }

  Future<void> _enregistrer(String jeton) async {
    try {
      await api.post('/moi/appareils', {'jeton': jeton, 'plateforme': plateforme.nom});
      _jeton = jeton;
    } catch (e) {
      debugPrint('Jeton push non enregistré : $e');
    }
  }

  void fermer() {
    for (final a in _abonnements) {
      a.cancel();
    }
    _abonnements.clear();
  }
}
