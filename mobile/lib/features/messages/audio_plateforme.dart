import 'dart:io';

import 'package:cross_file/cross_file.dart';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import 'vocal.dart';

/// Enregistreur réel (package `record`) : AAC dans un M4A mono à 48 kbit/s (Opus/WebM dans un navigateur), rangé
/// dans le dossier temporaire de l'appli puis effacé après l'envoi.
class EnregistreurRecord implements Enregistreur {
  final _enregistreur = AudioRecorder();

  @override
  Future<bool> autorisation() => _enregistreur.hasPermission();

  @override
  Future<void> demarrer() async {
    if (kIsWeb) {
      await _enregistreur.start(const RecordConfig(encoder: AudioEncoder.opus, numChannels: 1), path: '');
      return;
    }
    final dossier = await getTemporaryDirectory();
    await _enregistreur.start(
      const RecordConfig(encoder: AudioEncoder.aacLc, bitRate: 48000, sampleRate: 44100, numChannels: 1),
      path: '${dossier.path}/vocal_${DateTime.now().millisecondsSinceEpoch}.m4a',
    );
  }

  @override
  Future<String?> arreter() => _enregistreur.stop();

  @override
  Future<void> pause() => _enregistreur.pause();

  @override
  Future<void> reprendre() => _enregistreur.resume();

  @override
  Future<void> annuler() => _enregistreur.cancel();

  @override
  Future<int> niveau() async => niveauDepuisDb((await _enregistreur.getAmplitude()).current);

  Future<void> liberer() => _enregistreur.dispose();
}

/// Octets du fichier enregistré (chemin sur le téléphone, URL « blob: » dans un navigateur).
Future<Uint8List> lireEnregistrement(String chemin) => XFile(chemin).readAsBytes();

/// Nom du fichier envoyé au serveur (qui reconnaît de toute façon le format à ses octets).
String nomEnregistrement() => kIsWeb ? 'vocal.webm' : 'vocal.m4a';

/// Efface un fichier temporaire (enregistrement envoyé, vocal écouté) ; sans effet dans un navigateur.
Future<void> effacerFichier(String? chemin) async {
  if (kIsWeb || chemin == null) return;
  try {
    final f = File(chemin);
    if (await f.exists()) await f.delete();
  } catch (_) {}
}

/// Source de lecture à partir des octets téléchargés : fichier temporaire sur le téléphone (renvoyé dans
/// [VocalCharge.fichier] pour être effacé ensuite), URI « data: » dans un navigateur.
Future<VocalCharge> sourceDepuisOctets(Uint8List octets, int idMessage) async {
  final extension = extensionAudio(octets);
  if (kIsWeb) return VocalCharge(AudioSource.uri(Uri.dataFromBytes(octets, mimeType: typeMimeAudio(extension))), null);
  final dossier = await getTemporaryDirectory();
  // L'extension compte pour le lecteur d'iOS, qui ne devine pas le format.
  final fichier = File('${dossier.path}/ecoute_$idMessage.$extension');
  await fichier.writeAsBytes(octets, flush: true);
  return VocalCharge(AudioSource.file(fichier.path), fichier.path);
}

class VocalCharge {
  const VocalCharge(this.source, this.fichier);

  final AudioSource source;
  final String? fichier;
}
