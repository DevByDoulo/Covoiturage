import 'dart:async';

import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:provider/provider.dart';

import '../../core/api.dart';
import '../../core/modeles.dart';
import '../../core/theme.dart';
import 'audio_plateforme.dart';
import 'vocal.dart';

const _bleuEcoute = Color(0xFF34B7F1);
const _vitesses = [1.0, 1.5, 2.0];

/// Forme d'onde affichée quand l'application n'en a pas envoyé.
final _ondeParDefaut = List<int>.generate(32, (i) => 30 + (i * 37) % 50);

/// 09 — Bulle d'un message vocal : lecture / pause, forme d'onde (toucher ou glisser pour avancer), durée, vitesse
/// 1x / 1,5x / 2x, micro bleu une fois écouté. Le fichier n'est téléchargé qu'à la première lecture (API
/// authentifiée), dans un fichier temporaire effacé à la fermeture de l'écran.
class BulleVocale extends StatefulWidget {
  const BulleVocale({super.key, required this.idConversation, required this.message, this.onEcoute});

  final int idConversation;
  final MessageApp message;

  /// Le destinataire vient d'écouter le vocal (message mis à jour par le serveur).
  final ValueChanged<MessageApp>? onEcoute;

  @override
  State<BulleVocale> createState() => _BulleVocaleState();
}

class _BulleVocaleState extends State<BulleVocale> {
  /// Un seul vocal joue à la fois.
  static AudioPlayer? _enCours;

  AudioPlayer? _lecteur;
  String? _fichier;
  final List<StreamSubscription<Object?>> _abonnements = [];
  bool _chargement = false;
  bool _lecture = false;
  double _vitesse = 1;
  Duration _position = Duration.zero;
  String? _erreur;
  bool _ecouteSignalee = false;

  Duration get _duree => Duration(milliseconds: widget.message.dureeMs ?? 0);

  @override
  void dispose() {
    for (final a in _abonnements) {
      a.cancel();
    }
    if (_enCours == _lecteur) _enCours = null;
    _lecteur?.dispose();
    effacerFichier(_fichier);
    super.dispose();
  }

  Future<void> _basculer() async {
    if (_lecture) {
      await _lecteur?.pause();
      return;
    }
    if (_lecteur == null && !await _charger()) return;
    final lecteur = _lecteur!;
    if (_enCours != null && _enCours != lecteur) await _enCours!.pause();
    _enCours = lecteur;
    unawaited(lecteur.play()); // se termine à l'arrêt de la lecture
    _signalerEcoute();
  }

  Future<bool> _charger() async {
    setState(() {
      _chargement = true;
      _erreur = null;
    });
    final api = context.read<Api>();
    try {
      final octets = await api.telecharger('/moi/conversations/${widget.idConversation}/messages/${widget.message.id}/audio');
      final charge = await sourceDepuisOctets(octets, widget.message.id);
      final lecteur = AudioPlayer();
      await lecteur.setAudioSource(charge.source, initialPosition: _position);
      await lecteur.setSpeed(_vitesse);
      _abonnements
        ..add(lecteur.positionStream.listen((p) {
          if (mounted) setState(() => _position = p > _duree ? _duree : p);
        }))
        ..add(lecteur.playerStateStream.listen((e) {
          if (!mounted) return;
          if (e.processingState == ProcessingState.completed) {
            lecteur.pause();
            lecteur.seek(Duration.zero);
            setState(() {
              _lecture = false;
              _position = Duration.zero;
            });
          } else {
            setState(() => _lecture = e.playing);
          }
        }));
      _lecteur = lecteur;
      _fichier = charge.fichier;
      return true;
    } catch (e) {
      if (mounted) setState(() => _erreur = ErreurApi.messageDe(e));
      return false;
    } finally {
      if (mounted) setState(() => _chargement = false);
    }
  }

  void _signalerEcoute() {
    final m = widget.message;
    if (m.deMoi || m.ecoute || _ecouteSignalee) return;
    _ecouteSignalee = true;
    context
        .read<Api>()
        .post('/moi/conversations/${widget.idConversation}/messages/${m.id}/ecoute')
        .then((r) => widget.onEcoute?.call(MessageApp.depuisJson(r as Map<String, dynamic>)))
        .catchError((_) => _ecouteSignalee = false);
  }

  void _changerVitesse() {
    setState(() => _vitesse = _vitesses[(_vitesses.indexOf(_vitesse) + 1) % _vitesses.length]);
    _lecteur?.setSpeed(_vitesse);
  }

  void _allerA(double fraction) {
    final cible = Duration(milliseconds: (fraction.clamp(0.0, 1.0) * _duree.inMilliseconds).round());
    setState(() => _position = cible);
    _lecteur?.seek(cible);
  }

  @override
  Widget build(BuildContext context) {
    final m = widget.message;
    final couleur = m.deMoi ? Colors.white : Couleurs.vert;
    if (!m.audioDisponible) {
      return Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.mic_off_outlined, size: 18, color: m.deMoi ? Colors.white70 : Couleurs.texte2),
        const SizedBox(width: 6),
        Flexible(
          child: Text(m.contenu ?? 'Message vocal expiré',
              style: TextStyle(fontStyle: FontStyle.italic, color: m.deMoi ? Colors.white : Couleurs.texte2)),
        ),
      ]);
    }
    final onde = m.formeOnde.isEmpty ? _ondeParDefaut : m.formeOnde;
    final avancement = _duree.inMilliseconds == 0 ? 0.0 : _position.inMilliseconds / _duree.inMilliseconds;
    final temps = _lecture || _position > Duration.zero ? formaterDuree(_position) : formaterDureeTotale(_duree);
    return SizedBox(
      width: 240,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
        Row(children: [
          SizedBox.square(
            dimension: 40,
            child: IconButton(
              padding: EdgeInsets.zero,
              tooltip: _lecture ? 'Pause' : 'Écouter',
              onPressed: _chargement ? null : _basculer,
              icon: _chargement
                  ? SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2, color: couleur))
                  : Icon(_lecture ? Icons.pause_rounded : Icons.play_arrow_rounded, color: couleur, size: 32),
            ),
          ),
          Expanded(
            child: Semantics(
              label: 'Position de lecture',
              value: temps,
              slider: true,
              child: LayoutBuilder(
                builder: (_, contraintes) => GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTapDown: (d) => _allerA(d.localPosition.dx / contraintes.maxWidth),
                  onHorizontalDragUpdate: (d) => _allerA(d.localPosition.dx / contraintes.maxWidth),
                  child: CustomPaint(
                    size: Size(contraintes.maxWidth, 30),
                    painter: PeintreOnde(onde, avancement, couleur),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 4),
          InkWell(
            onTap: _changerVitesse,
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(color: Colors.black12, borderRadius: BorderRadius.circular(10)),
              child: Text('${_vitesse == 1.5 ? '1,5' : _vitesse.toStringAsFixed(0)}x',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: m.deMoi ? Colors.white : Couleurs.texte)),
            ),
          ),
        ]),
        Row(mainAxisSize: MainAxisSize.min, children: [
          const SizedBox(width: 8),
          Tooltip(
            message: m.ecoute ? 'Écouté' : 'Pas encore écouté',
            child: Icon(Icons.mic, size: 14, color: m.ecoute ? _bleuEcoute : (m.deMoi ? Colors.white70 : Couleurs.vert)),
          ),
          const SizedBox(width: 4),
          Text(temps, style: TextStyle(fontSize: 11, color: m.deMoi ? Colors.white70 : Couleurs.texte2)),
          if (_erreur != null) ...[
            const SizedBox(width: 6),
            Flexible(child: Text(_erreur!, style: const TextStyle(fontSize: 11, color: Couleurs.erreur))),
          ],
        ]),
      ]),
    );
  }
}

/// Barres de la forme d'onde ; celles déjà jouées sont pleines.
class PeintreOnde extends CustomPainter {
  PeintreOnde(this.niveaux, this.avancement, this.couleur);

  final List<int> niveaux;
  final double avancement;
  final Color couleur;

  @override
  void paint(Canvas canvas, Size size) {
    if (niveaux.isEmpty) return;
    final pas = size.width / niveaux.length;
    final largeur = (pas * 0.6).clamp(1.5, 4.0);
    final joue = Paint()..color = couleur;
    final reste = Paint()..color = couleur.withValues(alpha: 0.35);
    for (var i = 0; i < niveaux.length; i++) {
      final h = size.height * (0.1 + niveaux[i] / 100 * 0.9);
      final x = i * pas + (pas - largeur) / 2;
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(x, (size.height - h) / 2, largeur, h), const Radius.circular(2)),
        (i + 0.5) / niveaux.length <= avancement ? joue : reste,
      );
    }
  }

  @override
  bool shouldRepaint(PeintreOnde ancien) =>
      ancien.avancement != avancement || ancien.niveaux != niveaux || ancien.couleur != couleur;
}

/// Pendant l'enregistrement en maintenant le bouton : minuteur, « glisser pour annuler » et « glisser pour verrouiller ».
class BandeauEnregistrement extends StatelessWidget {
  const BandeauEnregistrement({super.key, required this.controleur});

  final ControleurVocal controleur;

  @override
  Widget build(BuildContext context) {
    final glisse = (-controleur.glissement.dx / seuilAnnulation).clamp(0.0, 1.0);
    return Row(children: [
      AnimatedScale(
        scale: 1 + controleur.niveau / 150,
        duration: const Duration(milliseconds: 100),
        child: const Icon(Icons.fiber_manual_record, color: Colors.red, size: 16),
      ),
      const SizedBox(width: 6),
      Text(formaterDuree(controleur.ecoule), style: const TextStyle(fontFeatures: [FontFeature.tabularFigures()])),
      const SizedBox(width: 12),
      Expanded(
        child: Opacity(
          opacity: 1 - glisse * 0.8,
          child: Transform.translate(
            offset: Offset(controleur.glissement.dx / 2, 0),
            child: const Text('‹ Glisser pour annuler', maxLines: 1, overflow: TextOverflow.fade, softWrap: false,
                style: TextStyle(color: Couleurs.texte2)),
          ),
        ),
      ),
      const Icon(Icons.lock_outline, size: 16, color: Couleurs.texte2),
      const Icon(Icons.keyboard_arrow_up, size: 16, color: Couleurs.texte2),
    ]);
  }
}

/// Enregistrement verrouillé (mains libres) : Supprimer, minuteur, Pause / Reprendre et Envoyer.
class BarreVerrouillee extends StatelessWidget {
  const BarreVerrouillee({super.key, required this.controleur});

  final ControleurVocal controleur;

  @override
  Widget build(BuildContext context) {
    final enPause = controleur.etat == EtatVocal.pause;
    return Row(children: [
      IconButton(
        tooltip: 'Supprimer',
        onPressed: controleur.annuler,
        icon: const Icon(Icons.delete_outline, color: Couleurs.erreur),
      ),
      Icon(enPause ? Icons.pause_circle_outline : Icons.fiber_manual_record, color: enPause ? Couleurs.texte2 : Colors.red, size: 16),
      const SizedBox(width: 6),
      Text('${formaterDuree(controleur.ecoule)} / ${formaterDuree(dureeMax)}',
          style: const TextStyle(fontFeatures: [FontFeature.tabularFigures()])),
      const Spacer(),
      IconButton(
        tooltip: enPause ? 'Reprendre' : 'Pause',
        onPressed: enPause ? controleur.reprendre : controleur.mettreEnPause,
        icon: Icon(enPause ? Icons.mic : Icons.pause),
      ),
      IconButton.filled(tooltip: 'Envoyer', onPressed: controleur.envoyer, icon: const Icon(Icons.send)),
    ]);
  }
}
