import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../../core/api.dart';
import '../../core/guide.dart';
import '../../core/itineraire.dart';
import '../../core/localisation.dart';
import '../../core/modeles.dart';
import '../../core/session.dart';
import '../../core/theme.dart';
import '../../core/voix.dart';
import '../../shared/carte.dart';
import '../../shared/carte_direct.dart';
import '../../shared/widgets.dart';

/// Point de rendez-vous d'un passager : l'escale choisie comme prise en charge (la réservation n'en donne que le
/// nom), sinon le départ du trajet. Le conducteur, lui, va au départ.
Point pointDeRendezVous(Trajet t, String? pointRamassage) {
  for (final e in t.escales) {
    if (pointRamassage != null && e.lieu == pointRamassage) return e;
  }
  return t.depart;
}

/// Réservation active du passager sur ce trajet (pour son point de prise en charge), ou null.
Future<Reservation?> maReservation(Api api, int idTrajet) async {
  try {
    final liste = (await api.get('/moi/reservations') as List).map((e) => Reservation.depuisJson(e as Map<String, dynamic>));
    for (final r in liste) {
      if (r.idTrajet == idTrajet && (r.statut == 'ACCEPTEE' || r.statut == 'EN_ATTENTE')) return r;
    }
  } catch (_) {}
  return null;
}

/// 08 — Guidage vocal jusqu'au point de rendez-vous (comme sur le site) : passager vers son point de prise en
/// charge, conducteur vers le départ ; position suivie, itinéraire OSRM, consignes lues à voix haute, recalcul si
/// l'on s'écarte du tracé, écran gardé allumé.
class GuidagePage extends StatefulWidget {
  const GuidagePage({super.key, required this.id});

  final int id;

  @override
  State<GuidagePage> createState() => _GuidagePageState();
}

class _GuidagePageState extends State<GuidagePage> {
  Trajet? _trajet;
  Point? _destination;
  bool _conducteur = false;
  ModeDeplacement _mode = ModeDeplacement.pied;
  String? _erreur;

  bool _enCours = false;
  bool _calcul = false;
  bool _demandeEnCours = false;
  PositionSuivie? _position;
  Itineraire? _itineraire;
  Guide? _guide;
  EtatGuidage? _etat;
  StreamSubscription<PositionSuivie>? _suivi;
  final _itineraires = ItineraireService();

  @override
  void initState() {
    super.initState();
    _charger();
  }

  @override
  void dispose() {
    _arreter();
    super.dispose();
  }

  Future<void> _charger() async {
    final api = context.read<Api>();
    final moi = context.read<Session>().utilisateur?.id;
    try {
      final t = Trajet.depuisJson(await api.get('/trajets/${widget.id}') as Map<String, dynamic>);
      final conducteur = t.conducteur.id == moi;
      final r = conducteur ? null : await maReservation(api, t.id);
      if (!mounted) return;
      setState(() {
        _trajet = t;
        _conducteur = conducteur;
        _mode = conducteur ? ModeDeplacement.voiture : ModeDeplacement.pied;
        _destination = conducteur ? t.depart : pointDeRendezVous(t, r?.pointRamassage);
      });
    } catch (e) {
      if (mounted) setState(() => _erreur = ErreurApi.messageDe(e));
    }
  }

  void _demarrer() {
    final voix = context.read<Voix>();
    setState(() {
      _erreur = null;
      _calcul = true;
    });
    voix.dire('Recherche de votre position.');
    WakelockPlus.enable().catchError((_) {});
    _suivi = context.read<PositionActuelle>().suivre().listen(
          _nouvellePosition,
          onError: (Object e) {
            if (!mounted) return;
            setState(() => _erreur = e is LocalisationImpossible ? e.message : 'Position introuvable.');
            _arreter();
          },
        );
  }

  void _arreter() {
    _suivi?.cancel();
    _suivi = null;
    WakelockPlus.disable().catchError((_) {});
    if (mounted) {
      context.read<Voix>().taire();
      setState(() {
        _enCours = false;
        _calcul = false;
        _guide = null;
        _etat = null;
      });
    }
  }

  void _nouvellePosition(PositionSuivie p) {
    if (!mounted) return;
    setState(() => _position = p);
    final guide = _guide;
    if (guide == null) {
      if (_calcul && !_demandeEnCours) _calculer(p, recalcul: false);
      return;
    }
    final etat = guide.avancer((latitude: p.latitude, longitude: p.longitude));
    setState(() => _etat = etat);
    final voix = context.read<Voix>();
    for (final a in etat.annonces) {
      voix.dire(a, prioritaire: true);
    }
    if (etat.arrive) {
      // Arrivé : on garde la carte mais on arrête de suivre la position.
      _suivi?.cancel();
      WakelockPlus.disable().catchError((_) {});
    } else if (etat.horsRoute && !_demandeEnCours) {
      voix.dire('Vous vous êtes écarté de l\'itinéraire. Recalcul.', prioritaire: true);
      _calculer(p, recalcul: true);
    }
  }

  Future<void> _calculer(PositionSuivie p, {required bool recalcul}) async {
    final d = _destination;
    if (d == null) return;
    _demandeEnCours = true;
    final voix = context.read<Voix>();
    try {
      final it = await _itineraires.calculer(
          (latitude: p.latitude, longitude: p.longitude), (latitude: d.latitude, longitude: d.longitude), _mode);
      if (!mounted || _suivi == null) return;
      final guide = Guide(it, _mode);
      if (!recalcul) voix.dire(guide.annonceDepart());
      final etat = guide.avancer((latitude: p.latitude, longitude: p.longitude));
      etat.annonces.forEach(voix.dire);
      setState(() {
        _itineraire = it;
        _guide = guide;
        _etat = etat;
        _enCours = true;
        _calcul = false;
      });
    } catch (_) {
      if (!recalcul && mounted) {
        setState(() => _erreur = 'Impossible de calculer l\'itinéraire pour le moment (service OpenStreetMap indisponible). Réessayez.');
        _arreter();
      }
    } finally {
      _demandeEnCours = false;
    }
  }

  String _arriveeEstimee() {
    final e = _etat, it = _itineraire;
    if (e == null || it == null) return '';
    final vitesse = _mode == ModeDeplacement.pied ? 1.3 : math.max(3, it.distanceM / math.max(1, it.dureeS));
    final h = DateTime.now().add(Duration(seconds: (e.distanceRestanteM / vitesse).round()));
    return '${h.hour.toString().padLeft(2, '0')}h${h.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final d = _destination;
    return Scaffold(
      appBar: AppBar(leading: retourAccueil(context), title: const Text('Aller au rendez-vous')),
      body: d == null
          ? Center(child: _erreur != null ? Padding(padding: const EdgeInsets.all(24), child: Bandeau(_erreur!)) : const CircularProgressIndicator())
          : ListView(padding: const EdgeInsets.fromLTRB(16, 0, 16, 24), children: [
              if (_erreur != null) ...[Bandeau(_erreur!), const SizedBox(height: 12)],
              if (_enCours) _consigne(d) else _preparation(d),
              const SizedBox(height: 12),
              CarteDirect(
                hauteur: _enCours ? 380 : 260,
                trace: _itineraire?.trace ?? const [],
                suivre: _enCours && _position != null ? (latitude: _position!.latitude, longitude: _position!.longitude) : null,
                reperes: [
                  Repere(d.latitude, d.longitude, 'depart', etiquette: 'A'),
                  if (_position != null) Repere(_position!.latitude, _position!.longitude, 'moi'),
                ],
              ),
              if (_enCours) ..._pied(),
            ]),
    );
  }

  Widget _preparation(Point d) {
    final voix = context.watch<Voix>();
    return Bloc(children: [
      Row(children: [
        const Icon(Icons.place, color: Couleurs.vert),
        const SizedBox(width: 6),
        Expanded(child: Text(d.lieu, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16))),
      ]),
      Text(_conducteur ? 'Départ de votre trajet' : 'Votre point de prise en charge',
          style: const TextStyle(color: Couleurs.texte2)),
      const SizedBox(height: 12),
      SegmentedButton<ModeDeplacement>(
        segments: const [
          ButtonSegment(value: ModeDeplacement.pied, label: Text('À pied'), icon: Icon(Icons.directions_walk)),
          ButtonSegment(value: ModeDeplacement.voiture, label: Text('En voiture'), icon: Icon(Icons.directions_car)),
        ],
        selected: {_mode},
        onSelectionChanged: (s) => setState(() => _mode = s.first),
      ),
      const SizedBox(height: 12),
      FilledButton.icon(
        onPressed: _calcul || _trajet == null ? null : _demarrer,
        icon: _calcul
            ? const SizedBox.square(dimension: 20, child: CircularProgressIndicator(strokeWidth: 2.5))
            : const Icon(Icons.play_arrow),
        label: Text(_calcul ? 'Recherche de votre position…' : 'Démarrer le guidage vocal'),
      ),
      const SizedBox(height: 8),
      Row(children: [
        Icon(voix.active ? Icons.volume_up : Icons.volume_off, size: 18, color: Couleurs.texte2),
        const SizedBox(width: 6),
        Expanded(child: Text(voix.active ? 'Voix activée' : 'Voix coupée', style: const TextStyle(color: Couleurs.texte2))),
        TextButton(onPressed: voix.basculer, child: Text(voix.active ? 'Couper' : 'Activer')),
      ]),
      const Text(
        'Votre position reste sur votre téléphone : elle n\'est envoyée qu\'au service d\'itinéraire (OpenStreetMap), '
        'sans votre nom.',
        style: TextStyle(color: Couleurs.texte2, fontSize: 12),
      ),
    ]);
  }

  Widget _consigne(Point d) {
    final e = _etat;
    final arrive = e?.arrive ?? false;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: arrive ? Couleurs.orange : Couleurs.vert, borderRadius: BorderRadius.circular(16)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(
          arrive ? 'Vous êtes arrivé' : (e?.prochaine?.instruction ?? 'Calcul de l\'itinéraire…'),
          style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 2),
        Text(
          arrive ? d.lieu : (e?.prochaine == null ? '' : 'dans ${distanceAffichee(e!.distanceProchaineM)}'),
          style: const TextStyle(color: Colors.white),
        ),
      ]),
    );
  }

  List<Widget> _pied() {
    final e = _etat;
    final voix = context.watch<Voix>();
    return [
      const SizedBox(height: 10),
      if (e != null && !e.arrive)
        Text('${distanceAffichee(e.distanceRestanteM)} · arrivée vers ${_arriveeEstimee()}',
            style: const TextStyle(fontWeight: FontWeight.w700)),
      const SizedBox(height: 8),
      Row(children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: voix.basculer,
            icon: Icon(voix.active ? Icons.volume_up : Icons.volume_off),
            label: Text(voix.active ? 'Voix activée' : 'Voix coupée'),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: OutlinedButton.icon(onPressed: _arreter, icon: const Icon(Icons.stop), label: const Text('Arrêter')),
        ),
      ]),
    ];
  }
}
