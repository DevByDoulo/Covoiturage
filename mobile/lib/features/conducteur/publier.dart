import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/api.dart';
import '../../core/formats.dart';
import '../../core/localisation.dart';
import '../../core/modeles.dart';
import '../../core/session.dart';
import '../../core/theme.dart';
import '../../shared/carte.dart';
import '../../shared/widgets.dart';
import '../recherche/champ_lieu.dart';

/// Délai minimal entre la publication et le départ (comme sur le site).
const _delaiMinimal = Duration(minutes: 30);

/// Publication d'un trajet : départ et arrivée, date, véhicule et options, puis prix proposé par l'IA
/// (ajustable dans la fourchette) et publication. Les escales se gèrent sur le site.
class PublierPage extends StatefulWidget {
  const PublierPage({super.key});

  @override
  State<PublierPage> createState() => _PublierPageState();
}

class _PublierPageState extends State<PublierPage> {
  List<Vehicule>? _vehicules;
  int? _idVehicule;

  Lieu? _depart;
  Lieu? _arrivee;
  bool _departActif = true;

  DateTime _date = _demainHuitHeures();
  int _places = 3;
  int _flexibilite = 20;
  String _mode = 'MANUELLE';
  String _bagage = 'MOYEN';
  bool _femmes = false;
  String _route = 'NATIONALE';
  final _peages = TextEditingController();

  Estimation? _estimation;
  String? _cleEstimation;
  double? _prix;

  bool _calcul = false;
  bool _publication = false;
  String? _erreur;

  static DateTime _demainHuitHeures() {
    final d = DateTime.now().add(const Duration(days: 1));
    return DateTime(d.year, d.month, d.day, 8);
  }

  @override
  void initState() {
    super.initState();
    _chargerVehicules();
  }

  @override
  void dispose() {
    _peages.dispose();
    super.dispose();
  }

  Future<void> _chargerVehicules() async {
    try {
      final liste = (await context.read<Api>().get('/moi/vehicules') as List)
          .map((e) => Vehicule.depuisJson(e as Map<String, dynamic>))
          .where((v) => v.valide)
          .toList();
      setState(() {
        _vehicules = liste;
        if (liste.isNotEmpty) _choisirVehicule(liste.first.id);
      });
    } catch (e) {
      setState(() {
        _vehicules = const [];
        _erreur = ErreurApi.messageDe(e);
      });
    }
  }

  Vehicule? get _vehicule => _vehicules?.where((v) => v.id == _idVehicule).firstOrNull;

  /// Une place reste au conducteur.
  int get _placesMax => ((_vehicule?.nombrePlaces ?? 5) - 1).clamp(1, 8);

  void _choisirVehicule(int id) {
    _idVehicule = id;
    if (_places > _placesMax) _places = _placesMax;
  }

  double? get _montantPeages {
    if (_route != 'AUTOROUTE') return null;
    return double.tryParse(_peages.text.replaceAll(RegExp(r'\s'), ''));
  }

  /// Demande d'estimation ; null tant que le départ, l'arrivée ou le véhicule manquent.
  Map<String, dynamic>? get _demande {
    if (_depart == null || _arrivee == null || _idVehicule == null) return null;
    Map<String, dynamic> point(Lieu l) => {'lieu': l.libelle, 'latitude': l.latitude, 'longitude': l.longitude};
    return {
      'idVehicule': _idVehicule,
      'depart': point(_depart!),
      'arrivee': point(_arrivee!),
      'escales': const [],
      'dateHeureDepart': dateHeureApi(_date),
      'nombrePlaces': _places,
      'typeRoute': _route,
      'montantPeages': _montantPeages,
    };
  }

  /// L'estimation n'est valable que pour la demande qui l'a produite.
  bool get _estimationAJour => _estimation != null && _cleEstimation == jsonEncode(_demande);

  bool get _departTropProche => _date.isBefore(DateTime.now().add(_delaiMinimal));

  Future<void> _calculer() async {
    final demande = _demande;
    if (demande == null) {
      setState(() => _erreur = 'Choisissez le départ et l\'arrivée.');
      return;
    }
    if (_departTropProche) {
      setState(() => _erreur = 'Le départ doit être dans au moins 30 minutes.');
      return;
    }
    setState(() {
      _calcul = true;
      _erreur = null;
    });
    try {
      final e = Estimation.depuisJson(await context.read<Api>().post('/trajets/estimation', demande) as Map<String, dynamic>);
      setState(() {
        _estimation = e;
        _cleEstimation = jsonEncode(demande);
        _prix = e.prixRecommande;
      });
    } catch (e) {
      setState(() => _erreur = ErreurApi.messageDe(e));
    } finally {
      if (mounted) setState(() => _calcul = false);
    }
  }

  Future<void> _publier() async {
    final demande = _demande;
    if (demande == null || !_estimationAJour || _publication) return;
    if (_departTropProche) {
      setState(() => _erreur = 'Le départ doit être dans au moins 30 minutes.');
      return;
    }
    setState(() {
      _publication = true;
      _erreur = null;
    });
    try {
      final t = await context.read<Api>().post('/trajets', {
        ...demande,
        'flexibiliteMinutes': _flexibilite,
        'modeReservation': _mode,
        'tailleBagage': _bagage,
        'femmesUniquement': _femmes && (context.read<Session>().utilisateur?.estFemme ?? false),
        'prixParPlace': _prix,
      }) as Map<String, dynamic>;
      if (!mounted) return;
      afficherMessage(context, 'Trajet publié !');
      context.pushReplacement('/conduite/${t['id']}');
    } catch (e) {
      setState(() {
        _erreur = ErreurApi.messageDe(e);
        _publication = false;
      });
    }
  }

  Future<void> _choisirDate() async {
    final maintenant = DateTime.now();
    final jour = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(maintenant.year, maintenant.month, maintenant.day),
      lastDate: maintenant.add(const Duration(days: 90)),
    );
    if (jour == null || !mounted) return;
    final heure = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(_date));
    if (heure == null) return;
    setState(() => _date = DateTime(jour.year, jour.month, jour.day, heure.hour, heure.minute));
  }

  /// Toucher la carte place le point du champ actif, puis l'adresse est retrouvée.
  Future<void> _placerSurCarte(double lat, double lng) async {
    final provisoire = Lieu('Point sur la carte', lat, lng);
    final departActif = _departActif;
    setState(() {
      if (departActif) {
        _depart = provisoire;
        if (_arrivee == null) _departActif = false;
      } else {
        _arrivee = provisoire;
      }
    });
    final adresse = await context.read<Geocodage>().adresseDe(lat, lng);
    if (adresse == null || !mounted) return;
    setState(() {
      final lieu = Lieu(adresse, lat, lng);
      if (departActif && _depart == provisoire) _depart = lieu;
      if (!departActif && _arrivee == provisoire) _arrivee = lieu;
    });
  }

  @override
  Widget build(BuildContext context) {
    final vehicules = _vehicules;
    return Scaffold(
      appBar: AppBar(title: const Text('Publier un trajet')),
      body: vehicules == null
          ? const Center(child: CircularProgressIndicator())
          : vehicules.isEmpty
              ? ListView(padding: const EdgeInsets.all(24), children: [
                  Bandeau(_erreur ?? 'Aucun véhicule validé : ajoutez-en un sur le site et attendez sa validation.'),
                ])
              : ListView(padding: const EdgeInsets.fromLTRB(16, 0, 16, 32), children: _formulaire(vehicules)),
    );
  }

  List<Widget> _formulaire(List<Vehicule> vehicules) {
    final estFemme = context.watch<Session>().utilisateur?.estFemme ?? false;
    final e = _estimation;
    return [
      Bloc(titre: 'Itinéraire', icone: Icons.route_outlined, children: [
        ChampLieu(
          libelle: 'Départ',
          lieu: _depart,
          maPosition: true,
          surChoix: (l) => setState(() {
            _depart = l;
            _departActif = _arrivee != null;
          }),
        ),
        const SizedBox(height: 10),
        ChampLieu(
          libelle: 'Arrivée',
          lieu: _arrivee,
          couleur: Couleurs.erreur,
          surChoix: (l) => setState(() => _arrivee = l),
        ),
        const SizedBox(height: 10),
        Row(children: [
          const Text('La carte place : '),
          const SizedBox(width: 6),
          ChoiceChip(label: const Text('Départ'), selected: _departActif, onSelected: (_) => setState(() => _departActif = true)),
          const SizedBox(width: 6),
          ChoiceChip(label: const Text('Arrivée'), selected: !_departActif, onSelected: (_) => setState(() => _departActif = false)),
        ]),
        const SizedBox(height: 8),
        Carte(
          hauteur: 200,
          polyline: _estimationAJour ? e?.itinerairePolyline : null,
          surTouche: _placerSurCarte,
          reperes: [
            if (_depart != null) Repere(_depart!.latitude, _depart!.longitude, 'depart', etiquette: 'A'),
            if (_arrivee != null) Repere(_arrivee!.latitude, _arrivee!.longitude, 'arrivee', etiquette: 'B'),
          ],
        ),
      ]),
      const SizedBox(height: 12),
      Bloc(titre: 'Départ et véhicule', icone: Icons.event_outlined, children: [
        OutlinedButton.icon(
          onPressed: _choisirDate,
          icon: const Icon(Icons.calendar_month),
          label: Text(DateFormat("EEEE d MMMM 'à' HH'h'mm", 'fr_FR').format(_date)),
        ),
        if (_departTropProche)
          const Padding(
            padding: EdgeInsets.only(top: 6),
            child: Text('Le départ doit être dans au moins 30 minutes.', style: TextStyle(color: Couleurs.erreur, fontSize: 13)),
          ),
        const SizedBox(height: 12),
        DropdownButtonFormField<int>(
          initialValue: _idVehicule,
          isExpanded: true,
          decoration: const InputDecoration(labelText: 'Véhicule', prefixIcon: Icon(Icons.directions_car_outlined)),
          items: [
            for (final v in vehicules) DropdownMenuItem(value: v.id, child: Text('${v.libelle} · ${v.immatriculation}')),
          ],
          onChanged: (id) => setState(() => _choisirVehicule(id!)),
        ),
        const SizedBox(height: 8),
        Row(children: [
          const Expanded(child: Text('Places proposées')),
          IconButton.outlined(
            onPressed: _places > 1 ? () => setState(() => _places--) : null,
            icon: const Icon(Icons.remove),
          ),
          SizedBox(width: 36, child: Text('$_places', textAlign: TextAlign.center, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800))),
          IconButton.outlined(
            onPressed: _places < _placesMax ? () => setState(() => _places++) : null,
            icon: const Icon(Icons.add),
          ),
        ]),
      ]),
      const SizedBox(height: 12),
      Bloc(titre: 'Options', icone: Icons.tune, children: [
        const Text('Route', style: TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        SegmentedButton<String>(
          segments: const [
            ButtonSegment(value: 'NATIONALE', label: Text('Nationale')),
            ButtonSegment(value: 'AUTOROUTE', label: Text('Autoroute (péage)')),
          ],
          selected: {_route},
          showSelectedIcon: false,
          onSelectionChanged: (s) => setState(() => _route = s.first),
        ),
        if (_route == 'AUTOROUTE') ...[
          const SizedBox(height: 10),
          TextField(
            controller: _peages,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(5)],
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              labelText: 'Péages pour le véhicule (FCFA)',
              helperText: 'Vide : estimés d\'après l\'itinéraire',
            ),
          ),
        ],
        const SizedBox(height: 14),
        const Text('Réservation', style: TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        SegmentedButton<String>(
          segments: const [
            ButtonSegment(value: 'MANUELLE', label: Text('Sur validation')),
            ButtonSegment(value: 'AUTOMATIQUE', label: Text('Immédiate')),
          ],
          selected: {_mode},
          showSelectedIcon: false,
          onSelectionChanged: (s) => setState(() => _mode = s.first),
        ),
        const SizedBox(height: 4),
        Text(
          _mode == 'MANUELLE' ? 'Vous acceptez ou refusez chaque demande.' : 'La place est réservée dès la demande.',
          style: const TextStyle(color: Couleurs.texte2, fontSize: 12),
        ),
        const SizedBox(height: 14),
        const Text('Bagages acceptés', style: TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        SegmentedButton<String>(
          segments: [for (final b in libellesBagage.entries) ButtonSegment(value: b.key, label: Text(b.value))],
          selected: {_bagage},
          showSelectedIcon: false,
          onSelectionChanged: (s) => setState(() => _bagage = s.first),
        ),
        const SizedBox(height: 14),
        DropdownButtonFormField<int>(
          initialValue: _flexibilite,
          decoration: const InputDecoration(labelText: 'Souplesse sur l\'heure de départ'),
          items: [for (final m in const [15, 20, 25, 30]) DropdownMenuItem(value: m, child: Text('± $m min'))],
          onChanged: (m) => setState(() => _flexibilite = m!),
        ),
        if (estFemme)
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: _femmes,
            onChanged: (v) => setState(() => _femmes = v),
            title: const Text('Réservé aux femmes'),
          ),
      ]),
      const SizedBox(height: 12),
      if (_erreur != null) ...[Bandeau(_erreur!), const SizedBox(height: 12)],
      if (e != null && _estimationAJour) ...[_blocPrix(e), const SizedBox(height: 12)],
      if (!_estimationAJour)
        FilledButton.icon(
          onPressed: _calcul ? null : _calculer,
          icon: _calcul
              ? const SizedBox.square(dimension: 20, child: CircularProgressIndicator(strokeWidth: 2.5))
              : const Icon(Icons.calculate_outlined),
          label: Text(_estimation == null ? 'Calculer le prix' : 'Recalculer le prix'),
        )
      else
        FilledButton.icon(
          onPressed: _publication ? null : _publier,
          icon: _publication
              ? const SizedBox.square(dimension: 20, child: CircularProgressIndicator(strokeWidth: 2.5))
              : const Icon(Icons.check),
          label: Text('Publier à ${fcfa(_prix)} la place'),
        ),
    ];
  }

  Widget _blocPrix(Estimation e) {
    final prix = (_prix ?? e.prixRecommande).clamp(e.prixMin, e.prixMax);
    // Pas de 25 FCFA dans la fourchette proposée.
    final pas = ((e.prixMax - e.prixMin) / 25).round();
    return Bloc(titre: 'Prix proposé', icone: Icons.auto_awesome_outlined, children: [
      Text('${e.distanceKm.toStringAsFixed(0)} km · ${duree(e.dureeEstimeeMin)}'
          '${e.sourceItineraire == 'ESTIMATION' ? ' (distance estimée)' : ''}',
          style: const TextStyle(color: Couleurs.texte2)),
      const SizedBox(height: 8),
      Center(
        child: Text('${fcfa(prix)} / place',
            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Couleurs.vert)),
      ),
      Center(
        child: Text('Recommandé : ${fcfa(e.prixRecommande)}', style: const TextStyle(color: Couleurs.texte2)),
      ),
      if (pas > 0)
        Slider(
          value: prix,
          min: e.prixMin,
          max: e.prixMax,
          divisions: pas,
          label: fcfa(prix),
          onChanged: (v) => setState(() => _prix = (v / 25).round() * 25.0),
        ),
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(fcfa(e.prixMin), style: const TextStyle(color: Couleurs.texte2, fontSize: 12)),
        Text(fcfa(e.prixMax), style: const TextStyle(color: Couleurs.texte2, fontSize: 12)),
      ]),
      const Divider(height: 24),
      const Text('Coûts du trajet', style: TextStyle(fontWeight: FontWeight.w700)),
      const SizedBox(height: 6),
      _ligneCout('Carburant', e.coutCarburant),
      _ligneCout('Usure du véhicule', e.coutUsure),
      if (e.coutPeages > 0) _ligneCout('Péages', e.coutPeages),
      if (e.facteurMeteo > 1.001)
        Text('Météo au départ : +${((e.facteurMeteo - 1) * 100).toStringAsFixed(0)} % de consommation',
            style: const TextStyle(color: Couleurs.texte2, fontSize: 13)),
      if (e.heureDePointe)
        const Text('Heure de pointe prise en compte', style: TextStyle(color: Couleurs.texte2, fontSize: 13)),
    ]);
  }

  Widget _ligneCout(String libelle, double montant) => Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Row(children: [Expanded(child: Text(libelle)), Text(fcfa(montant))]),
      );
}
