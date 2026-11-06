import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/api.dart';
import '../../core/config.dart';
import '../../core/formats.dart';
import '../../core/modeles.dart';
import '../../core/session.dart';
import '../../core/theme.dart';
import '../../shared/widgets.dart';
import '../messages/messages.dart';

const _aVenir = {'PUBLIE', 'COMPLET', 'EN_COURS'};

Color couleurStatutTrajet(String statut) => switch (statut) {
      'PUBLIE' || 'EN_COURS' => Couleurs.vert,
      'COMPLET' => Couleurs.orange,
      'ANNULE' => Couleurs.erreur,
      _ => Couleurs.texte2,
    };

enum _Etat { chargement, devenirConducteur, enValidation, pret }

/// Onglet « Conduire » : trajets proposés par le conducteur (à venir / passés) et bouton Publier.
/// Pour les autres comptes : comment devenir conducteur (véhicule et pièces se déposent sur le site).
class MesTrajetsPage extends StatefulWidget {
  const MesTrajetsPage({super.key});

  @override
  State<MesTrajetsPage> createState() => _MesTrajetsPageState();
}

class _MesTrajetsPageState extends State<MesTrajetsPage> {
  _Etat _etat = _Etat.chargement;
  List<Trajet> _trajets = const [];
  String? _erreur;
  bool _passes = false;

  @override
  void initState() {
    super.initState();
    _charger();
  }

  Future<void> _charger() async {
    final session = context.read<Session>();
    final api = context.read<Api>();
    try {
      // Profil frais : la validation des documents a pu arriver depuis la connexion.
      await session.rafraichir();
    } catch (_) {}
    final u = session.utilisateur;
    if (!mounted) return;
    if (u == null || u.role != 'CONDUCTEUR') return setState(() => _etat = _Etat.devenirConducteur);
    if (!u.conducteurValide) return setState(() => _etat = _Etat.enValidation);
    try {
      final liste = (await api.get('/moi/trajets') as List)
          .map((e) => Trajet.depuisJson(e as Map<String, dynamic>))
          .toList();
      setState(() {
        _trajets = liste;
        _erreur = null;
        _etat = _Etat.pret;
      });
    } catch (e) {
      setState(() {
        _erreur = ErreurApi.messageDe(e);
        _etat = _Etat.pret;
      });
    }
  }

  Future<void> _ouvrir(String chemin) async {
    await context.push(chemin);
    if (mounted) _charger();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Mes trajets'), actions: [
          const BoutonMessages(),
          IconButton(onPressed: _charger, icon: const Icon(Icons.refresh), tooltip: 'Actualiser'),
        ]),
        floatingActionButton: _etat == _Etat.pret
            ? FloatingActionButton.extended(
                onPressed: () => _ouvrir('/conduite/publier'),
                icon: const Icon(Icons.add),
                label: const Text('Publier'),
              )
            : null,
        body: RefreshIndicator(onRefresh: _charger, child: _corps()),
      );

  Widget _corps() => switch (_etat) {
        _Etat.chargement => const Center(child: CircularProgressIndicator()),
        _Etat.devenirConducteur => _explication(
            Icons.directions_car_outlined,
            'Proposez vos trajets',
            'Pour devenir conducteur, ajoutez votre véhicule et vos pièces (permis, pièce d\'identité, carte grise) '
                'sur le site. Un administrateur les vérifie, puis vous pourrez publier vos trajets ici.',
          ),
        _Etat.enValidation => _explication(
            Icons.hourglass_top,
            'Documents en cours de vérification',
            'Vous pourrez publier dès qu\'un administrateur aura validé vos pièces et un véhicule. '
                'Vous serez prévenu par une notification.',
          ),
        _Etat.pret => _liste(),
      };

  Widget _explication(IconData icone, String titre, String texte) => ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Icon(icone, size: 56, color: Couleurs.vert),
          const SizedBox(height: 12),
          Text(titre, textAlign: TextAlign.center, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Text(texte, textAlign: TextAlign.center, style: const TextStyle(color: Couleurs.texte2)),
          const SizedBox(height: 20),
          OutlinedButton.icon(
            onPressed: () => launchUrl(Uri.parse('${Config.siteUrl}/vehicules'), mode: LaunchMode.externalApplication),
            icon: const Icon(Icons.open_in_new),
            label: const Text('Véhicules et documents sur le site'),
          ),
        ],
      );

  Widget _liste() {
    final aVenir = _trajets.where((t) => _aVenir.contains(t.statut)).toList()
      ..sort((a, b) => a.dateHeureDepart.compareTo(b.dateHeureDepart));
    final passes = _trajets.where((t) => !_aVenir.contains(t.statut)).toList()
      ..sort((a, b) => b.dateHeureDepart.compareTo(a.dateHeureDepart));
    final liste = _passes ? passes : aVenir;
    return ListView(padding: const EdgeInsets.fromLTRB(16, 0, 16, 96), children: [
      if (_erreur != null) ...[Bandeau(_erreur!), const SizedBox(height: 12)],
      SegmentedButton<bool>(
        segments: [
          ButtonSegment(value: false, label: Text('À venir (${aVenir.length})')),
          ButtonSegment(value: true, label: Text('Passés (${passes.length})')),
        ],
        selected: {_passes},
        showSelectedIcon: false,
        onSelectionChanged: (s) => setState(() => _passes = s.first),
      ),
      const SizedBox(height: 12),
      if (liste.isEmpty)
        Padding(
          padding: const EdgeInsets.all(32),
          child: Text(_passes ? 'Aucun trajet passé pour le moment.' : 'Aucun trajet à venir. Touchez « Publier ».',
              textAlign: TextAlign.center, style: const TextStyle(color: Couleurs.texte2)),
        ),
      for (final t in liste) ...[_carte(t), const SizedBox(height: 10)],
    ]);
  }

  Widget _carte(Trajet t) => Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => _ouvrir('/conduite/${t.id}'),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('${t.depart.lieu} → ${t.arrivee.lieu}',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
              const SizedBox(height: 2),
              Text(dateHeure(t.dateHeureDepart), style: const TextStyle(color: Couleurs.texte2)),
              const SizedBox(height: 8),
              Wrap(spacing: 8, runSpacing: 6, crossAxisAlignment: WrapCrossAlignment.center, children: [
                Pastille(libellesStatutTrajet[t.statut] ?? t.statut, couleur: couleurStatutTrajet(t.statut)),
                Text('${t.nombrePlacesTotal - t.nombrePlacesDisponibles}/${t.nombrePlacesTotal} places réservées'),
                Text(fcfa(t.prixParPlace), style: const TextStyle(fontWeight: FontWeight.w700)),
              ]),
            ]),
          ),
        ),
      );
}
