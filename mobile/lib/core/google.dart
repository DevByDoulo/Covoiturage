import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'api.dart';
import 'session.dart';

/// IDs clients OAuth Google, passés au lancement par --dart-define (jamais écrits dans le dépôt) :
/// `--dart-define=GOOGLE_SERVER_CLIENT_ID=<ID client Web>` (le même que GOOGLE_CLIENT_ID du backend et du site).
/// Sur Android, le client « Android » n'apparaît pas dans le code : Google le reconnaît au nom du paquet et au SHA-1.
class ConfigGoogle {
  const ConfigGoogle({this.serverClientId = '', this.iosClientId = ''});

  static const environnement = ConfigGoogle(
    serverClientId: String.fromEnvironment('GOOGLE_SERVER_CLIENT_ID'),
    iosClientId: String.fromEnvironment('GOOGLE_IOS_CLIENT_ID'),
  );

  /// ID client Web : audience de l'idToken, vérifiée par le backend.
  final String serverClientId;

  /// ID client iOS (uniquement pour une version iPhone).
  final String iosClientId;

  bool get configuree => serverClientId.trim().isNotEmpty;
}

/// Échec côté Google (configuration, fenêtre impossible à afficher…), avec le message à montrer.
class EchecGoogle implements Exception {
  const EchecGoogle(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Message à afficher pour une erreur du plugin ; null quand l'utilisateur a simplement fermé la fenêtre.
String? messageEchecGoogle(GoogleSignInExceptionCode code) => switch (code) {
  GoogleSignInExceptionCode.canceled => null,
  GoogleSignInExceptionCode.interrupted =>
    'La connexion avec Google a été interrompue. Vérifiez votre connexion internet et réessayez.',
  GoogleSignInExceptionCode.clientConfigurationError || GoogleSignInExceptionCode.providerConfigurationError =>
    "La connexion Google est mal configurée pour cette application (ID client ou empreinte SHA-1).",
  GoogleSignInExceptionCode.uiUnavailable => "Impossible d'afficher la fenêtre de connexion Google sur cet appareil.",
  _ => 'La connexion avec Google a échoué. Réessayez.',
};

/// Obtient l'idToken Google de l'utilisateur. Interface pour pouvoir tester les écrans sans le plugin.
abstract class ServiceGoogle {
  /// L'idToken, ou null si l'utilisateur a fermé la fenêtre de choix du compte. Lève [EchecGoogle] sinon.
  Future<String?> obtenirIdToken();
}

/// Implémentation réelle avec le package google_sign_in (Android / iOS).
class ServiceGooglePlugin implements ServiceGoogle {
  ServiceGooglePlugin(this.config);

  final ConfigGoogle config;
  Future<void>? _initialisation;

  GoogleSignIn get _google => GoogleSignIn.instance;

  @override
  Future<String?> obtenirIdToken() async {
    if (!config.configuree) {
      throw const EchecGoogle("La connexion Google n'est pas configurée dans cette version de l'application.");
    }
    if (kIsWeb) throw const EchecGoogle('Sur navigateur, connectez-vous avec Google depuis le site YOBALEMAsn.');
    try {
      await (_initialisation ??= _google.initialize(
        serverClientId: config.serverClientId,
        clientId: defaultTargetPlatform == TargetPlatform.iOS && config.iosClientId.isNotEmpty
            ? config.iosClientId
            : null,
      ));
      if (!_google.supportsAuthenticate()) {
        throw const EchecGoogle("La connexion Google n'est pas disponible sur cet appareil.");
      }
      final compte = await _google.authenticate();
      final idToken = compte.authentication.idToken;
      // La session Google ne sert plus : la prochaine fois, l'utilisateur pourra choisir un autre compte.
      _google.signOut().ignore();
      if (idToken == null) throw const EchecGoogle("Google n'a pas fourni de jeton d'identité. Réessayez.");
      return idToken;
    } on GoogleSignInException catch (e) {
      final message = messageEchecGoogle(e.code);
      if (message == null) return null;
      throw EchecGoogle(message);
    } on EchecGoogle {
      rethrow;
    } catch (_) {
      _initialisation = null;
      throw const EchecGoogle('La connexion avec Google a échoué. Réessayez.');
    }
  }
}

/// Ce que l'écran doit faire après « Continuer avec Google ».
sealed class IssueGoogle {
  const IssueGoogle();
}

/// L'utilisateur a fermé la fenêtre : rien à afficher.
class GoogleAnnule extends IssueGoogle {
  const GoogleAnnule();
}

/// Session ouverte : le routeur ouvre l'application.
class GoogleConnecte extends IssueGoogle {
  const GoogleConnecte();
}

/// Premier passage (compte créé ou lié par le backend) : demander le numéro, vérifié ensuite par un code.
class GoogleTelephoneRequis extends IssueGoogle {
  const GoogleTelephoneRequis(this.idToken);

  final String idToken;
}

class GoogleErreur extends IssueGoogle {
  const GoogleErreur(this.message);

  final String message;
}

/// « Continuer avec Google » : idToken auprès de Google, puis POST /auth/google (même endpoint que le site).
Future<IssueGoogle> continuerAvecGoogle(ServiceGoogle google, Session session) async {
  final String? idToken;
  try {
    idToken = await google.obtenirIdToken();
  } on EchecGoogle catch (e) {
    return GoogleErreur(e.message);
  } catch (_) {
    return const GoogleErreur('La connexion avec Google a échoué. Réessayez.');
  }
  if (idToken == null) return const GoogleAnnule();
  try {
    final r = await session.connexionGoogle(idToken);
    if (r.connecte) return const GoogleConnecte();
    if (r.etape == 'TELEPHONE_REQUIS') return GoogleTelephoneRequis(idToken);
    return const GoogleErreur('Réponse inattendue du serveur. Réessayez.');
  } catch (e) {
    return GoogleErreur(ErreurApi.messageDe(e));
  }
}
