import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/localisation.dart';
import '../../core/modeles.dart';
import '../../core/theme.dart';

/// Champ d'adresse : on tape, on valide (loupe ou Entrée), on choisit une suggestion. Avec [maPosition], un
/// bouton remplit le champ avec la position du téléphone (08 — Géolocalisation).
class ChampLieu extends StatefulWidget {
  const ChampLieu({
    super.key,
    required this.libelle,
    required this.lieu,
    required this.surChoix,
    this.couleur = Couleurs.vert,
    this.maPosition = false,
  });

  final String libelle;
  final Lieu? lieu;
  final ValueChanged<Lieu> surChoix;
  final Color couleur;
  final bool maPosition;

  @override
  State<ChampLieu> createState() => _ChampLieuState();
}

class _ChampLieuState extends State<ChampLieu> {
  late final _texte = TextEditingController(text: widget.lieu?.libelle ?? '');
  List<Lieu> _suggestions = const [];
  bool _recherche = false;
  bool _localisation = false;
  bool _aucun = false;
  String? _message;

  @override
  void didUpdateWidget(ChampLieu ancien) {
    super.didUpdateWidget(ancien);
    // Un lieu fixé de l'extérieur (carte, inversion) remplace le texte saisi.
    if (widget.lieu != ancien.lieu && widget.lieu != null) _texte.text = widget.lieu!.libelle;
  }

  @override
  void dispose() {
    _texte.dispose();
    super.dispose();
  }

  Future<void> _chercher() async {
    if (_texte.text.trim().length < 2 || _recherche) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _recherche = true;
      _aucun = false;
      _message = null;
    });
    final resultats = await context.read<Geocodage>().rechercher(_texte.text);
    if (!mounted) return;
    setState(() {
      _recherche = false;
      _suggestions = resultats;
      _aucun = resultats.isEmpty;
    });
  }

  Future<void> _localiser() async {
    setState(() {
      _localisation = true;
      _message = null;
      _suggestions = const [];
      _aucun = false;
    });
    final geocodage = context.read<Geocodage>();
    try {
      final p = await context.read<PositionActuelle>().localiser();
      final adresse = await geocodage.adresseDe(p.latitude, p.longitude);
      if (!mounted) return;
      _choisir(Lieu(adresse ?? 'Ma position', p.latitude, p.longitude));
      if (p.precisionM > PositionActuelle.precisionApproximativeM) {
        setState(() => _message = 'Position approximative (à environ ${p.precisionM} m près) : vérifiez l\'adresse.');
      }
    } on LocalisationImpossible catch (e) {
      if (mounted) setState(() => _message = e.message);
    } finally {
      if (mounted) setState(() => _localisation = false);
    }
  }

  void _choisir(Lieu lieu) {
    _texte.text = lieu.libelle;
    setState(() => _suggestions = const []);
    widget.surChoix(lieu);
  }

  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        TextField(
          controller: _texte,
          textInputAction: TextInputAction.search,
          onSubmitted: (_) => _chercher(),
          decoration: InputDecoration(
            labelText: widget.libelle,
            hintText: 'Adresse, quartier, ville…',
            prefixIcon: Icon(Icons.place, color: widget.couleur),
            suffixIcon: Row(mainAxisSize: MainAxisSize.min, children: [
              if (_recherche || _localisation)
                const Padding(
                  padding: EdgeInsets.all(12),
                  child: SizedBox.square(dimension: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                )
              else ...[
                IconButton(icon: const Icon(Icons.search), tooltip: 'Rechercher ce lieu', onPressed: _chercher),
                if (widget.maPosition)
                  IconButton(
                    icon: const Icon(Icons.my_location, color: Couleurs.vert),
                    tooltip: 'Utiliser ma position actuelle',
                    onPressed: _localiser,
                  ),
              ],
            ]),
          ),
        ),
        if (_suggestions.isNotEmpty)
          Card(
            margin: const EdgeInsets.only(top: 4),
            child: Column(children: [
              for (final s in _suggestions)
                ListTile(
                  dense: true,
                  leading: const Icon(Icons.place_outlined),
                  title: Text(s.libelle, style: const TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: s.detail == null || s.detail!.isEmpty ? null : Text(s.detail!),
                  onTap: () => _choisir(s),
                ),
            ]),
          ),
        if (_aucun)
          const Padding(
            padding: EdgeInsets.only(top: 6, left: 4),
            child: Text('Aucun lieu trouvé. Précisez (quartier, ville) ou touchez la carte.',
                style: TextStyle(color: Couleurs.texte2, fontSize: 13)),
          ),
        if (_message != null)
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 4),
            child: Text(_message!, style: const TextStyle(color: Couleurs.erreur, fontSize: 13)),
          ),
      ]);
}
