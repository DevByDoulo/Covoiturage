import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/api.dart';
import '../../core/formats.dart';
import '../../core/modeles.dart';
import '../../core/theme.dart';
import '../../shared/widgets.dart';

/// Alerte de recherche (`/api/moi/alertes`) : une notification est envoyée dès qu'un trajet correspondant est publié.
class AlerteRecherche {
  AlerteRecherche({
    required this.id,
    required this.depart,
    required this.arrivee,
    required this.date,
    required this.rayonKm,
    this.prixMax,
  });

  final int id;
  final Point depart;
  final Point arrivee;
  final DateTime date;
  final double rayonKm;
  final double? prixMax;

  factory AlerteRecherche.depuisJson(Map<String, dynamic> j) => AlerteRecherche(
        id: (j['id'] as num).toInt(),
        depart: Point.depuisJson(j['depart'] as Map<String, dynamic>),
        arrivee: Point.depuisJson(j['arrivee'] as Map<String, dynamic>),
        date: DateTime.parse(j['date'] as String),
        rayonKm: (j['rayonKm'] as num?)?.toDouble() ?? 5,
        prixMax: (j['prixMax'] as num?)?.toDouble(),
      );
}

/// Liste des alertes, partagée entre la page Rechercher (bouton « Créer une alerte ») et le bloc « Mes alertes ».
class AlertesService extends ChangeNotifier {
  AlertesService(this._api);

  final Api _api;

  /// Null tant que la liste n'est pas chargée (ou si le compte n'a pas accès aux alertes).
  List<AlerteRecherche>? alertes;

  Future<void> charger() async {
    try {
      final l = await _api.get('/moi/alertes') as List;
      alertes = l.map((e) => AlerteRecherche.depuisJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      alertes = const [];
    }
    notifyListeners();
  }

  Future<void> creer({
    required Point depart,
    required Point arrivee,
    required DateTime date,
    double? prixMax,
  }) async {
    final a = await _api.post('/moi/alertes', {
      'depart': depart.versJson(),
      'arrivee': arrivee.versJson(),
      'date': dateApi(date),
      'prixMax': ?prixMax,
    }) as Map<String, dynamic>;
    alertes = [...?alertes, AlerteRecherche.depuisJson(a)]..sort((x, y) => x.date.compareTo(y.date));
    notifyListeners();
  }

  Future<void> supprimer(int id) async {
    await _api.delete('/moi/alertes/$id');
    alertes = alertes?.where((a) => a.id != id).toList();
    notifyListeners();
  }

  /// Une alerte identique (mêmes points, même jour) existe déjà.
  bool existe(Point depart, Point arrivee, DateTime date) => (alertes ?? const []).any((a) =>
      a.date.year == date.year &&
      a.date.month == date.month &&
      a.date.day == date.day &&
      (a.depart.latitude - depart.latitude).abs() < 1e-4 &&
      (a.depart.longitude - depart.longitude).abs() < 1e-4 &&
      (a.arrivee.latitude - arrivee.latitude).abs() < 1e-4 &&
      (a.arrivee.longitude - arrivee.longitude).abs() < 1e-4);
}

/// Bloc « Mes alertes » (masqué s'il n'y en a aucune), avec suppression.
class BlocMesAlertes extends StatefulWidget {
  const BlocMesAlertes({super.key});

  @override
  State<BlocMesAlertes> createState() => _BlocMesAlertesState();
}

class _BlocMesAlertesState extends State<BlocMesAlertes> {
  String? _erreur;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<AlertesService>().charger();
    });
  }

  Future<void> _supprimer(AlerteRecherche a) async {
    try {
      await context.read<AlertesService>().supprimer(a.id);
      if (mounted) setState(() => _erreur = null);
    } catch (e) {
      if (mounted) setState(() => _erreur = ErreurApi.messageDe(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final liste = context.watch<AlertesService>().alertes;
    if (liste == null || liste.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Bloc(titre: 'Mes alertes', icone: Icons.notifications_active_outlined, children: [
        const Text(
          'Vous serez prévenu dès qu\'un trajet correspondant est publié.',
          style: TextStyle(color: Couleurs.texte2, fontSize: 12),
        ),
        const SizedBox(height: 8),
        if (_erreur != null) ...[Bandeau(_erreur!), const SizedBox(height: 8)],
        for (final a in liste)
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text('${a.depart.lieu} → ${a.arrivee.lieu}',
                maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700)),
            subtitle: Text([
              DateFormat('EEE d MMM', 'fr_FR').format(a.date),
              if (a.prixMax != null) 'max ${fcfa(a.prixMax)}',
            ].join(' · ')),
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline, color: Couleurs.erreur),
              tooltip: 'Supprimer l\'alerte',
              onPressed: () => _supprimer(a),
            ),
          ),
      ]),
    );
  }
}

/// Bouton « Créer une alerte » affiché sous les résultats de la recherche (vides ou non).
class BoutonCreerAlerte extends StatefulWidget {
  const BoutonCreerAlerte({super.key, required this.depart, required this.arrivee, required this.date});

  final Point depart;
  final Point arrivee;
  final DateTime date;

  @override
  State<BoutonCreerAlerte> createState() => _BoutonCreerAlerteState();
}

class _BoutonCreerAlerteState extends State<BoutonCreerAlerte> {
  bool _envoi = false;
  String? _erreur;

  Future<void> _creer() async {
    setState(() {
      _envoi = true;
      _erreur = null;
    });
    try {
      await context.read<AlertesService>().creer(depart: widget.depart, arrivee: widget.arrivee, date: widget.date);
    } catch (e) {
      if (mounted) setState(() => _erreur = ErreurApi.messageDe(e));
    } finally {
      if (mounted) setState(() => _envoi = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final active = context.watch<AlertesService>().existe(widget.depart, widget.arrivee, widget.date);
    return Bloc(children: [
      const Text('Pas le trajet qu\'il vous faut ?', style: TextStyle(fontWeight: FontWeight.w800)),
      const Text(
        'Créez une alerte : vous recevrez une notification dès qu\'un conducteur publiera un trajet correspondant.',
        style: TextStyle(color: Couleurs.texte2),
      ),
      const SizedBox(height: 10),
      if (_erreur != null) ...[Bandeau(_erreur!), const SizedBox(height: 10)],
      if (active)
        const Bandeau('Alerte active pour cette recherche.', succes: true)
      else
        OutlinedButton.icon(
          onPressed: _envoi ? null : _creer,
          icon: _envoi
              ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2.5))
              : const Icon(Icons.notifications_active_outlined),
          label: const Text('Créer une alerte'),
        ),
    ]);
  }
}
