import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

/// 09 — Messages vocaux : logique d'enregistrement « façon WhatsApp », indépendante du plugin (testée avec un faux
/// enregistreur et fake_async).
///
/// Maintenir le micro enregistre ; glisser vers la gauche annule ; glisser vers le haut verrouille (mains libres,
/// avec Supprimer, Pause et Envoyer) ; relâcher envoie. Moins d'une seconde : ignoré. 5 minutes : envoi automatique.

const dureeMin = Duration(seconds: 1);
const dureeMax = Duration(minutes: 5);

/// Nombre de barres de la forme d'onde envoyée au serveur (64 au plus côté API).
const barresOnde = 48;

/// Distance (en pixels logiques) à parcourir pour annuler (vers la gauche) ou verrouiller (vers le haut).
const seuilAnnulation = 110.0;
const seuilVerrouillage = 80.0;

enum EtatVocal {
  /// Rien en cours : le bouton micro est affiché.
  inactif,

  /// Demande d'autorisation du micro en cours.
  autorisation,

  /// Enregistrement en maintenant le bouton.
  enregistrement,

  /// Enregistrement verrouillé (mains libres).
  verrouille,

  /// Enregistrement verrouillé et mis en pause.
  pause,
}

/// « 0:07 », « 1:23 », « 5:00 ».
String formaterDuree(Duration d) {
  final s = d.isNegative ? 0 : d.inSeconds;
  return '${s ~/ 60}:${(s % 60).toString().padLeft(2, '0')}';
}

/// Durée totale d'un vocal, arrondie à la seconde comme les aperçus du serveur (« 🎤 Message vocal (0:03) »).
String formaterDureeTotale(Duration d) => formaterDuree(Duration(seconds: (d.inMilliseconds / 1000).round()));

/// Niveau du plugin (dBFS, de -160 à 0) ramené de 0 à 100 ; en dessous de -50 dB, c'est le silence.
int niveauDepuisDb(double db) {
  if (db.isNaN || db.isInfinite) return 0;
  return (((db + 50) / 50).clamp(0.0, 1.0) * 100).round();
}

/// Ramène les niveaux mesurés (un tous les 100 ms) à [barres] barres (maximum de chaque tranche).
List<int> reduireNiveaux(List<int> niveaux, [int barres = barresOnde]) {
  if (niveaux.length <= barres) return [for (final n in niveaux) n.clamp(0, 100)];
  return [
    for (var i = 0; i < barres; i++)
      niveaux
          .sublist(i * niveaux.length ~/ barres, math.max(i * niveaux.length ~/ barres + 1, (i + 1) * niveaux.length ~/ barres))
          .reduce(math.max)
          .clamp(0, 100),
  ];
}

/// Extension d'un fichier audio d'après ses premiers octets (même reconnaissance que le serveur).
String extensionAudio(List<int> o) {
  bool commence(int debut, String texte) =>
      o.length >= debut + texte.length && String.fromCharCodes(o.sublist(debut, debut + texte.length)) == texte;
  if (o.length >= 4 && o[0] == 0x1A && o[1] == 0x45 && o[2] == 0xDF && o[3] == 0xA3) return 'webm';
  if (commence(0, 'OggS')) return 'ogg';
  if (commence(4, 'ftyp')) return 'm4a';
  if (o.length >= 2 && o[0] == 0xFF && (o[1] & 0xF6) == 0xF0) return 'aac';
  return 'm4a';
}

String typeMimeAudio(String extension) => switch (extension) {
      'webm' => 'audio/webm',
      'ogg' => 'audio/ogg',
      'aac' => 'audio/aac',
      _ => 'audio/mp4',
    };

/// Ce dont le contrôleur a besoin du plugin d'enregistrement (package `record` en vrai, un faux en test).
abstract class Enregistreur {
  /// Demande l'autorisation du micro si besoin ; vrai si elle est accordée.
  Future<bool> autorisation();

  Future<void> demarrer();

  /// Arrête et renvoie le chemin (ou l'URL « blob: » sur le web) du fichier produit.
  Future<String?> arreter();

  Future<void> pause();

  Future<void> reprendre();

  /// Arrête et efface le fichier.
  Future<void> annuler();

  /// Niveau sonore instantané, de 0 à 100.
  Future<int> niveau();
}

/// Enregistrement terminé, prêt à envoyer.
class VocalEnregistre {
  const VocalEnregistre(this.chemin, this.duree, this.niveaux);

  final String chemin;
  final Duration duree;
  final List<int> niveaux;
}

/// États, minuteur et gestes de l'enregistrement. [surEnvoi] reçoit chaque enregistrement à envoyer.
class ControleurVocal extends ChangeNotifier {
  ControleurVocal(this._enregistreur, {required this.surEnvoi, int Function()? maintenantMs})
      : _maintenantMs = maintenantMs ?? (() => DateTime.now().millisecondsSinceEpoch);

  final Enregistreur _enregistreur;
  final Future<void> Function(VocalEnregistre vocal) surEnvoi;
  final int Function() _maintenantMs;

  EtatVocal etat = EtatVocal.inactif;
  Duration ecoule = Duration.zero;
  int niveau = 0;

  /// Message à afficher (micro refusé, appui trop court…), effacé au prochain appui.
  String? info;

  /// Déplacement du doigt depuis l'appui (pour l'animation « glisser pour annuler »).
  Offset glissement = Offset.zero;

  bool _appuye = false;
  int _debutMs = 0;
  int _cumulMs = 0;
  Timer? _tic;
  final List<int> _niveaux = [];
  bool _envoiEnCours = false;

  bool get enCours => etat == EtatVocal.enregistrement || etat == EtatVocal.verrouille || etat == EtatVocal.pause;

  /// Doigt posé sur le micro : demande l'autorisation si besoin, puis démarre.
  Future<void> appuyer() async {
    if (etat != EtatVocal.inactif) return;
    _appuye = true;
    info = null;
    glissement = Offset.zero;
    etat = EtatVocal.autorisation;
    notifyListeners();
    bool ok;
    try {
      ok = await _enregistreur.autorisation();
    } catch (_) {
      ok = false;
    }
    if (!ok) {
      _remettreAZero(info: 'Autorisez le micro dans les réglages du téléphone pour envoyer des messages vocaux.');
      return;
    }
    if (!_appuye) {
      // Doigt relâché pendant la demande d'autorisation (première fois) : on n'enregistre pas.
      _remettreAZero(info: 'Maintenez le micro appuyé pour enregistrer.');
      return;
    }
    try {
      await _enregistreur.demarrer();
    } catch (_) {
      _remettreAZero(info: "Impossible de démarrer l'enregistrement.");
      return;
    }
    if (!_appuye) {
      // Simple tape sur le micro : rien n'est envoyé.
      await _enregistreur.annuler().catchError((_) {});
      _remettreAZero(info: 'Maintenez le micro appuyé pour enregistrer.');
      return;
    }
    _niveaux.clear();
    _cumulMs = 0;
    _debutMs = _maintenantMs();
    ecoule = Duration.zero;
    etat = EtatVocal.enregistrement;
    _tic = Timer.periodic(const Duration(milliseconds: 100), (_) => _mesurer());
    notifyListeners();
  }

  /// Le doigt bouge : à gauche, annuler ; vers le haut, verrouiller.
  Future<void> glisser(Offset depuisAppui) async {
    if (etat != EtatVocal.enregistrement) return;
    glissement = Offset(math.min(0, depuisAppui.dx), math.min(0, depuisAppui.dy));
    if (depuisAppui.dx <= -seuilAnnulation) {
      await annuler();
    } else if (depuisAppui.dy <= -seuilVerrouillage) {
      etat = EtatVocal.verrouille;
      glissement = Offset.zero;
      notifyListeners();
    } else {
      notifyListeners();
    }
  }

  /// Doigt relâché : envoie, sauf si l'enregistrement est verrouillé (il continue).
  Future<void> relacher() async {
    _appuye = false;
    if (etat == EtatVocal.enregistrement) await envoyer();
  }

  /// Le geste a été interrompu par le système (appel, notification…) : on abandonne.
  Future<void> interrompre() async {
    _appuye = false;
    if (etat == EtatVocal.enregistrement) await annuler();
  }

  Future<void> mettreEnPause() async {
    if (etat != EtatVocal.verrouille) return;
    await _enregistreur.pause();
    _cumulMs += _maintenantMs() - _debutMs;
    etat = EtatVocal.pause;
    notifyListeners();
  }

  Future<void> reprendre() async {
    if (etat != EtatVocal.pause) return;
    await _enregistreur.reprendre();
    _debutMs = _maintenantMs();
    etat = EtatVocal.verrouille;
    notifyListeners();
  }

  /// Supprimer / glisser à gauche : rien n'est envoyé.
  Future<void> annuler() async {
    if (!enCours) return;
    _tic?.cancel();
    _remettreAZero();
    try {
      await _enregistreur.annuler();
    } catch (_) {}
  }

  /// Arrête et envoie ; moins d'une seconde : ignoré (avec une indication).
  Future<void> envoyer() async {
    if (!enCours || _envoiEnCours) return;
    _envoiEnCours = true;
    _tic?.cancel();
    final duree = Duration(milliseconds: math.min(_dureeMs(), dureeMax.inMilliseconds));
    final niveaux = reduireNiveaux(List.of(_niveaux));
    String? chemin;
    try {
      chemin = await _enregistreur.arreter();
    } catch (_) {
      chemin = null;
    }
    _envoiEnCours = false;
    if (duree < dureeMin) {
      _remettreAZero(info: 'Maintenez le micro appuyé pour enregistrer.');
      return;
    }
    _remettreAZero();
    if (chemin == null) {
      info = "L'enregistrement a échoué.";
      notifyListeners();
      return;
    }
    await surEnvoi(VocalEnregistre(chemin, duree, niveaux));
  }

  int _dureeMs() => _cumulMs + (etat == EtatVocal.pause ? 0 : _maintenantMs() - _debutMs);

  Future<void> _mesurer() async {
    if (!enCours) return;
    ecoule = Duration(milliseconds: _dureeMs());
    if (etat != EtatVocal.pause) {
      try {
        niveau = await _enregistreur.niveau();
      } catch (_) {
        niveau = 0;
      }
      _niveaux.add(niveau);
    }
    notifyListeners();
    if (ecoule >= dureeMax) await envoyer();
  }

  void _remettreAZero({String? info}) {
    _tic?.cancel();
    _tic = null;
    etat = EtatVocal.inactif;
    ecoule = Duration.zero;
    niveau = 0;
    glissement = Offset.zero;
    if (info != null) this.info = info;
    notifyListeners();
  }

  @override
  void dispose() {
    _tic?.cancel();
    if (enCours) unawaited(_enregistreur.annuler().catchError((_) {}));
    super.dispose();
  }
}
