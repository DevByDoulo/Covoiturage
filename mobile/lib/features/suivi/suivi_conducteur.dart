import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/api.dart';
import '../../core/itineraire.dart';
import '../../core/modeles.dart';
import '../../core/theme.dart';
import '../../core/voix.dart';
import '../../shared/carte.dart';
import '../../shared/carte_direct.dart';
import '../../shared/widgets.dart';
import '../guidage/guidage.dart';

const _intervalle = Duration(seconds: 5);

/// Paliers annoncés quand le conducteur s'approche (une fois chacun).
const _paliersM = [2000.0, 1000.0, 500.0, 200.0];
const _arriveM = 60.0;
const _ancienneS = 60;
const _vitesseDefautMs = 7.0;
const _detour = 1.3;

/// Position du conducteur lue sur l'API.
class PositionConducteur {
  PositionConducteur(this.latitude, this.longitude, this.vitesse, this.ageSecondes);

  final double latitude;
  final double longitude;
  final double? vitesse;
  final int ageSecondes;

  factory PositionConducteur.depuisJson(Map<String, dynamic> j) => PositionConducteur(
      (j['latitude'] as num).toDouble(),
      (j['longitude'] as num).toDouble(),
      (j['vitesse'] as num?)?.toDouble(),
      (j['ageSecondes'] as num?)?.toInt() ?? 0);
}

/// Annonces vocales du suivi : premier signal, chaque palier franchi, puis l'arrivée (une fois chacun).
/// Logique pure, testée dans test/guide_test.dart.
class AnnoncesSuivi {
  AnnoncesSuivi(this.prenom);

  final String prenom;
  final _paliersDits = <double>{};
  bool _premiere = false;
  bool _arrivee = false;

  String? pour(double distance) {
    if (distance <= _arriveM) {
      if (_arrivee) return null;
      _arrivee = true;
      return '$prenom est au point de rendez-vous.';
    }
    if (!_premiere) {
      _premiere = true;
      _paliersDits.addAll(_paliersM.where((m) => distance <= m));
      return '$prenom est en route. $prenom est à ${distanceParlee(distance)} du point de rendez-vous.';
    }
    final franchis = _paliersM.where((m) => distance <= m && !_paliersDits.contains(m)).toList();
    if (franchis.isEmpty) return null;
    final palier = franchis.last;
    _paliersDits.addAll(_paliersM.where((m) => m >= palier));
    return '$prenom est à ${distanceParlee(distance)} du point de rendez-vous.';
  }
}

/// 08 — Le passager suit son conducteur en direct : voiture sur la carte, distance et heure estimée au point de
/// rendez-vous, annonces vocales (« Awa est à 500 mètres du point de rendez-vous »).
class SuiviConducteurPage extends StatefulWidget {
  const SuiviConducteurPage({super.key, required this.id});

  final int id;

  @override
  State<SuiviConducteurPage> createState() => _SuiviConducteurPageState();
}

class _SuiviConducteurPageState extends State<SuiviConducteurPage> {
  Trajet? _trajet;
  Point? _rendezVous;
  PositionConducteur? _position;
  String? _erreur;
  Timer? _minuteur;
  AnnoncesSuivi? _annonces;

  @override
  void initState() {
    super.initState();
    _charger();
  }

  @override
  void dispose() {
    _minuteur?.cancel();
    super.dispose();
  }

  Future<void> _charger() async {
    final api = context.read<Api>();
    try {
      final t = Trajet.depuisJson(await api.get('/trajets/${widget.id}') as Map<String, dynamic>);
      final r = await maReservation(api, t.id);
      if (!mounted) return;
      setState(() {
        _trajet = t;
        _rendezVous = pointDeRendezVous(t, r?.pointRamassage);
        _annonces = AnnoncesSuivi(t.conducteur.prenom);
      });
      _interroger();
      _minuteur = Timer.periodic(_intervalle, (_) => _interroger());
    } catch (e) {
      if (mounted) setState(() => _erreur = ErreurApi.messageDe(e));
    }
  }

  /// Une erreur passagère (réseau) n'arrête pas le suivi : on réessaie au tour suivant.
  Future<void> _interroger() async {
    try {
      final j = await context.read<Api>().get('/trajets/${widget.id}/position');
      if (!mounted) return;
      final p = j == null ? null : PositionConducteur.depuisJson(j as Map<String, dynamic>);
      setState(() {
        _position = p;
        _erreur = null;
      });
      final d = _distance;
      if (p != null && d != null) {
        final phrase = _annonces?.pour(d);
        if (phrase != null) context.read<Voix>().dire(phrase, prioritaire: true);
      }
    } catch (e) {
      if (mounted) setState(() => _erreur = ErreurApi.messageDe(e));
    }
  }

  double? get _distance {
    final p = _position, r = _rendezVous;
    if (p == null || r == null) return null;
    return distanceM((latitude: p.latitude, longitude: p.longitude), (latitude: r.latitude, longitude: r.longitude));
  }

  String _arriveeEstimee() {
    final d = _distance, p = _position;
    if (d == null || p == null) return '';
    final vitesse = (p.vitesse ?? 0) > 2 ? p.vitesse! : _vitesseDefautMs;
    final h = DateTime.now().add(Duration(seconds: (d * _detour / vitesse).round()));
    return '${h.hour.toString().padLeft(2, '0')}h${h.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final t = _trajet, r = _rendezVous;
    final voix = context.watch<Voix>();
    return Scaffold(
      appBar: AppBar(leading: retourAccueil(context), title: const Text('Suivre mon conducteur')),
      body: t == null || r == null
          ? Center(child: _erreur != null ? Padding(padding: const EdgeInsets.all(24), child: Bandeau(_erreur!)) : const CircularProgressIndicator())
          : ListView(padding: const EdgeInsets.fromLTRB(16, 0, 16, 24), children: [
              if (_erreur != null) ...[Bandeau(_erreur!), const SizedBox(height: 12)],
              _etat(t, r),
              const SizedBox(height: 12),
              CarteDirect(
                hauteur: 360,
                suivre: _position == null ? null : (latitude: _position!.latitude, longitude: _position!.longitude),
                reperes: [
                  Repere(r.latitude, r.longitude, 'depart', etiquette: 'A'),
                  if (_position != null) Repere(_position!.latitude, _position!.longitude, 'voiture'),
                ],
              ),
              const SizedBox(height: 10),
              Row(children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: voix.basculer,
                    icon: Icon(voix.active ? Icons.volume_up : Icons.volume_off),
                    label: Text(voix.active ? 'Annonces activées' : 'Annonces coupées'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => context.push('/trajets/${t.id}/guidage'),
                    icon: const Icon(Icons.directions_walk),
                    label: const Text('Me guider'),
                  ),
                ),
              ]),
              const SizedBox(height: 8),
              Text('Rendez-vous : ${r.lieu}. La position de ${t.conducteur.prenom} n\'est visible que par ses passagers, '
                  'pendant le trajet.', style: const TextStyle(color: Couleurs.texte2, fontSize: 13)),
            ]),
    );
  }

  Widget _etat(Trajet t, Point r) {
    final p = _position;
    final d = _distance;
    final arrive = d != null && d <= _arriveM;
    final (titre, sousTitre) = p == null
        ? ('${t.conducteur.prenom} ne partage pas sa position pour le moment',
            'Cette page se met à jour toute seule dès que le partage commence (au plus tôt une heure avant le départ).')
        : arrive
            ? ('${t.conducteur.prenom} est au point de rendez-vous', r.lieu)
            : ('${t.conducteur.prenom} est à ${distanceAffichee(d!)}', 'du point de rendez-vous · arrivée vers ${_arriveeEstimee()}');
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: arrive ? Couleurs.orange : Couleurs.vert, borderRadius: BorderRadius.circular(16)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(titre, style: const TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.w800)),
        const SizedBox(height: 2),
        Text(sousTitre, style: const TextStyle(color: Colors.white)),
        if (p != null && p.ageSecondes > _ancienneS)
          Text('Dernière position reçue il y a ${p.ageSecondes < 120 ? '${p.ageSecondes} s' : '${(p.ageSecondes / 60).round()} min'}.',
              style: const TextStyle(color: Colors.white70, fontSize: 12)),
      ]),
    );
  }
}
