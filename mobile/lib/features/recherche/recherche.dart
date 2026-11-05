import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/api.dart';
import '../../core/formats.dart';
import '../../core/localisation.dart';
import '../../core/modeles.dart';
import '../../core/theme.dart';
import '../../shared/carte.dart';
import '../../shared/widgets.dart';
import 'champ_lieu.dart';

/// Recherche de trajets (même API que le site : le tracé passe près du départ et de l'arrivée, dans le bon sens).
class RecherchePage extends StatefulWidget {
  const RecherchePage({super.key});

  @override
  State<RecherchePage> createState() => _RecherchePageState();
}

class _RecherchePageState extends State<RecherchePage> {
  Lieu? _depart;
  Lieu? _arrivee;
  DateTime _date = DateTime.now();
  int _places = 1;
  bool _departActif = true;

  bool _chargement = false;
  String? _erreur;
  List<Trajet>? _resultats;
  Trajet? _selection;

  Future<void> _rechercher() async {
    if (_depart == null || _arrivee == null) {
      setState(() => _erreur = 'Choisissez un lieu de départ et un lieu d\'arrivée.');
      return;
    }
    setState(() {
      _chargement = true;
      _erreur = null;
    });
    try {
      final liste = await context.read<Api>().get('/trajets/recherche', query: {
        'latDepart': _depart!.latitude,
        'lngDepart': _depart!.longitude,
        'latArrivee': _arrivee!.latitude,
        'lngArrivee': _arrivee!.longitude,
        'date': dateApi(_date),
        'places': _places,
      }) as List;
      final trajets = liste.map((e) => Trajet.depuisJson(e as Map<String, dynamic>)).toList()
        ..sort((a, b) => a.dateHeureDepart.compareTo(b.dateHeureDepart));
      setState(() {
        _resultats = trajets;
        _selection = trajets.isEmpty ? null : trajets.first;
      });
    } catch (e) {
      setState(() => _erreur = ErreurApi.messageDe(e));
    } finally {
      if (mounted) setState(() => _chargement = false);
    }
  }

  Future<void> _choisirDate() async {
    final aujourdhui = DateTime.now();
    final d = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(aujourdhui.year, aujourdhui.month, aujourdhui.day),
      lastDate: aujourdhui.add(const Duration(days: 90)),
    );
    if (d != null) setState(() => _date = d);
  }

  /// Toucher la carte place le point du champ actif (départ puis arrivée).
  Future<void> _placerSurCarte(double lat, double lng) async {
    final provisoire = Lieu('Point sur la carte', lat, lng);
    final departActif = _departActif;
    setState(() {
      if (departActif) {
        _depart = provisoire;
        _departActif = false;
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

  List<Repere> get _reperes {
    final c = _selection?.correspondance;
    return [
      if (_depart != null) Repere(_depart!.latitude, _depart!.longitude, 'depart', etiquette: 'A'),
      if (_arrivee != null) Repere(_arrivee!.latitude, _arrivee!.longitude, 'arrivee', etiquette: 'B'),
      if (c != null) Repere(c.ramassage.latitude, c.ramassage.longitude, 'ramassage'),
      if (c != null) Repere(c.depose.latitude, c.depose.longitude, 'depose'),
    ];
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Rechercher un trajet')),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          children: [
            Bloc(children: [
              ChampLieu(
                libelle: 'Départ',
                lieu: _depart,
                maPosition: true,
                surChoix: (l) => setState(() {
                  _depart = l;
                  _departActif = false;
                }),
              ),
              const SizedBox(height: 10),
              ChampLieu(
                libelle: 'Arrivée',
                lieu: _arrivee,
                couleur: Couleurs.erreur,
                surChoix: (l) => setState(() => _arrivee = l),
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: _depart == null && _arrivee == null
                      ? null
                      : () => setState(() {
                            final d = _depart;
                            _depart = _arrivee;
                            _arrivee = d;
                          }),
                  icon: const Icon(Icons.swap_vert),
                  label: const Text('Inverser départ et arrivée'),
                ),
              ),
              Row(children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _choisirDate,
                    icon: const Icon(Icons.calendar_today_outlined, size: 18),
                    label: Text(DateFormat('EEE d MMM', 'fr_FR').format(_date)),
                  ),
                ),
                const SizedBox(width: 12),
                IconButton.outlined(
                  onPressed: _places > 1 ? () => setState(() => _places--) : null,
                  icon: const Icon(Icons.remove),
                  tooltip: 'Un passager de moins',
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text('$_places', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                ),
                IconButton.outlined(
                  onPressed: _places < 8 ? () => setState(() => _places++) : null,
                  icon: const Icon(Icons.add),
                  tooltip: 'Un passager de plus',
                ),
              ]),
              const SizedBox(height: 14),
              if (_erreur != null) ...[Bandeau(_erreur!), const SizedBox(height: 12)],
              FilledButton.icon(
                onPressed: _chargement ? null : _rechercher,
                icon: _chargement
                    ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2.5))
                    : const Icon(Icons.search),
                label: const Text('Rechercher'),
              ),
            ]),
            const SizedBox(height: 16),
            Carte(reperes: _reperes, polyline: _selection?.itinerairePolyline, surTouche: _placerSurCarte),
            const SizedBox(height: 6),
            Text(
              _departActif ? 'Touchez la carte pour placer le départ.' : 'Touchez la carte pour placer l\'arrivée.',
              style: const TextStyle(color: Couleurs.texte2, fontSize: 12),
            ),
            const SizedBox(height: 16),
            if (_resultats != null) ..._listeResultats(),
          ],
        ),
      );

  List<Widget> _listeResultats() {
    final liste = _resultats!;
    if (liste.isEmpty) {
      return const [
        Bloc(children: [
          Center(child: Icon(Icons.route_outlined, size: 40, color: Couleurs.texte2)),
          SizedBox(height: 8),
          Text('Aucun trajet ne correspond ce jour-là.',
              textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w700)),
          Text('Essayez une autre date, ou créez une alerte depuis le site.',
              textAlign: TextAlign.center, style: TextStyle(color: Couleurs.texte2)),
        ]),
      ];
    }
    return [
      Text('${liste.length} trajet${liste.length > 1 ? 's' : ''} le ${DateFormat('EEEE d MMMM', 'fr_FR').format(_date)}',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
      const SizedBox(height: 10),
      for (final t in liste) ...[
        CarteTrajet(
          trajet: t,
          selectionne: identical(t, _selection),
          surSelection: () => setState(() => _selection = t),
          surOuverture: () => context.push('/trajets/${t.id}'),
        ),
        const SizedBox(height: 10),
      ],
    ];
  }
}

/// Résumé d'un trajet dans les résultats de recherche.
class CarteTrajet extends StatelessWidget {
  const CarteTrajet({super.key, required this.trajet, required this.surOuverture, this.surSelection, this.selectionne = false});

  final Trajet trajet;
  final VoidCallback surOuverture;
  final VoidCallback? surSelection;
  final bool selectionne;

  @override
  Widget build(BuildContext context) {
    final t = trajet;
    final c = t.correspondance;
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: selectionne ? Couleurs.vert : Colors.transparent, width: 2),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: surOuverture,
        onLongPress: surSelection,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Text(DateFormat("HH'h'mm").format(t.dateHeureDepart),
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              const SizedBox(width: 10),
              Expanded(
                child: Text('${t.depart.lieu} → ${t.arrivee.lieu}',
                    maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700)),
              ),
              Text(fcfa(t.prixParPlace), style: const TextStyle(fontWeight: FontWeight.w800, color: Couleurs.vert)),
            ]),
            const SizedBox(height: 8),
            Row(children: [
              Avatar(nom: '${t.conducteur.prenom} ${t.conducteur.nomInitiale}', photo: t.conducteur.photoProfil, rayon: 14),
              const SizedBox(width: 8),
              Text('${t.conducteur.prenom} ${t.conducteur.nomInitiale}'),
              if (t.conducteur.noteMoyenne != null) ...[
                const SizedBox(width: 6),
                const Icon(Icons.star, size: 16, color: Couleurs.orange),
                Text(t.conducteur.noteMoyenne!.toStringAsFixed(1).replaceAll('.', ',')),
              ],
              const Spacer(),
              Text('${t.nombrePlacesDisponibles} place${t.nombrePlacesDisponibles > 1 ? 's' : ''}',
                  style: const TextStyle(color: Couleurs.texte2)),
            ]),
            if (c != null) ...[
              const SizedBox(height: 8),
              Text(
                'Prise en charge à ${distance(c.distanceRamassageM)} de votre départ · dépose à ${distance(c.distanceDeposeM)} de votre arrivée',
                style: const TextStyle(color: Couleurs.texte2, fontSize: 12),
              ),
            ],
            if (surSelection != null && !selectionne)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: surSelection,
                  icon: const Icon(Icons.map_outlined, size: 18),
                  label: const Text('Voir sur la carte'),
                ),
              ),
          ]),
        ),
      ),
    );
  }
}
