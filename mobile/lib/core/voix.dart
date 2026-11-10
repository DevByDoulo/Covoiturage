import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_tts/flutter_tts.dart';

/// Voix off en français (synthèse vocale du téléphone, ou du navigateur sur le web). Coupable ; le choix est
/// mémorisé sur l'appareil.
class Voix extends ChangeNotifier {
  Voix({FlutterSecureStorage? stockage}) : _stockage = stockage ?? const FlutterSecureStorage() {
    _preparer();
  }

  static const _cle = 'covoitia.voix';
  final FlutterSecureStorage _stockage;
  final FlutterTts _tts = FlutterTts();

  bool active = true;

  /// Dernière phrase (affichée aussi à l'écran pour qui n'a pas le son).
  String? derniere;

  Future<void> _preparer() async {
    try {
      active = await _stockage.read(key: _cle) != 'non';
      await _tts.setLanguage('fr-FR');
      await _tts.setSpeechRate(kIsWeb ? 1.0 : 0.5);
      // Sur iOS, la voix se mélange à la musique au lieu de la couper.
      await _tts.setIosAudioCategory(IosTextToSpeechAudioCategory.playback,
          [IosTextToSpeechAudioCategoryOptions.mixWithOthers, IosTextToSpeechAudioCategoryOptions.duckOthers]);
    } catch (_) {
      // Synthèse vocale indisponible : les consignes restent affichées.
    }
    notifyListeners();
  }

  Future<void> basculer() async {
    active = !active;
    notifyListeners();
    if (!active) await taire();
    try {
      await _stockage.write(key: _cle, value: active ? 'oui' : 'non');
    } catch (_) {}
  }

  /// [prioritaire] : coupe la phrase en cours (consigne de virage plus urgente qu'une information).
  Future<void> dire(String texte, {bool prioritaire = false}) async {
    derniere = texte;
    notifyListeners();
    if (!active) return;
    try {
      if (prioritaire) await _tts.stop();
      await _tts.speak(texte);
    } catch (_) {}
  }

  Future<void> taire() async {
    try {
      await _tts.stop();
    } catch (_) {}
  }
}
