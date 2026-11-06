import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/api.dart';
import '../../core/formats.dart';
import '../../core/modeles.dart';
import '../../core/session.dart';
import '../../core/theme.dart';
import '../../shared/carte.dart';
import '../../shared/widgets.dart';

/// Détail d'un trajet et réservation (nombre de places, moyen de paiement).
class DetailTrajetPage extends StatefulWidget {
  const DetailTrajetPage({super.key, required this.id});

  final int id;

  @override
  State<DetailTrajetPage> createState() => _DetailTrajetPageState();
}

class _DetailTrajetPageState extends State<DetailTrajetPage> {
  Trajet? _trajet;
  String? _erreur;
  List<String> _moyens = const ['ESPECES'];

  int _places = 1;
  String _moyen = 'ESPECES';
  bool _envoi = false;
  String? _erreurReservation;

  @override
  void initState() {
    super.initState();
    _charger();
  }

  Future<void> _charger() async {
    final api = context.read<Api>();
    try {
      final t = Trajet.depuisJson(await api.get('/trajets/${widget.id}') as Map<String, dynamic>);
      final moyens = await api.get('/paiements/moyens') as List;
      setState(() {
        _trajet = t;
        _moyens = [
          for (final m in moyens)
            if ((m as Map<String, dynamic>)['disponible'] == true) m['moyen'] as String,
        ];
      });
    } catch (e) {
      setState(() => _erreur = ErreurApi.messageDe(e));
    }
  }

  Future<void> _reserver() async {
    setState(() {
      _envoi = true;
      _erreurReservation = null;
    });
    try {
      final r = Reservation.depuisJson(await context.read<Api>().post(
          '/trajets/${widget.id}/reservations', {'nombrePlaces': _places, 'moyenPaiement': _moyen}) as Map<String, dynamic>);
      if (!mounted) return;
      afficherMessage(
          context,
          r.statut == 'ACCEPTEE'
              ? 'Réservation confirmée !'
              : 'Demande envoyée : le conducteur doit l\'accepter. Vous serez prévenu.');
      context.go('/reservations');
    } catch (e) {
      setState(() => _erreurReservation = ErreurApi.messageDe(e));
    } finally {
      if (mounted) setState(() => _envoi = false);
    }
  }

  /// 08 — Google Maps calcule l'itinéraire depuis la position du téléphone (aucune clé nécessaire).
  Future<void> _itineraire(Trajet t) => launchUrl(
        Uri.parse('https://www.google.com/maps/dir/?api=1&destination=${t.depart.latitude},${t.depart.longitude}'),
        mode: LaunchMode.externalApplication,
      );

  @override
  Widget build(BuildContext context) {
    final t = _trajet;
    return Scaffold(
      appBar: AppBar(title: const Text('Trajet')),
      body: t == null
          ? Center(
              child: _erreur == null
                  ? const CircularProgressIndicator()
                  : Padding(padding: const EdgeInsets.all(24), child: Bandeau(_erreur!)))
          : ListView(padding: const EdgeInsets.fromLTRB(16, 0, 16, 32), children: _contenu(t)),
    );
  }

  List<Widget> _contenu(Trajet t) {
    final moi = context.watch<Session>().utilisateur;
    final estConducteur = moi?.id == t.conducteur.id;
    return [
      Text(dateHeure(t.dateHeureDepart).replaceFirstMapped(RegExp(r'^\w'), (m) => m[0]!.toUpperCase()),
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
      Text('± ${t.flexibiliteMinutes} min', style: const TextStyle(color: Couleurs.texte2)),
      if (t.statut == 'ANNULE') ...[
        const SizedBox(height: 10),
        Bandeau('Trajet annulé${t.motifAnnulation == null ? '' : ' : ${t.motifAnnulation}'}'),
      ],
      const SizedBox(height: 12),
      Carte(
        hauteur: 230,
        polyline: t.itinerairePolyline,
        reperes: [
          Repere(t.depart.latitude, t.depart.longitude, 'depart', etiquette: 'A'),
          for (var i = 0; i < t.escales.length; i++)
            Repere(t.escales[i].latitude, t.escales[i].longitude, 'escale', etiquette: '${i + 1}'),
          Repere(t.arrivee.latitude, t.arrivee.longitude, 'arrivee', etiquette: 'B'),
        ],
      ),
      const SizedBox(height: 12),
      Bloc(titre: 'Itinéraire', icone: Icons.route_outlined, children: [
        _etape('A', Couleurs.vert, t.depart.lieu),
        for (var i = 0; i < t.escales.length; i++) _etape('${i + 1}', Couleurs.orange, t.escales[i].lieu),
        _etape('B', Couleurs.erreur, t.arrivee.lieu),
        const Divider(height: 24),
        Row(children: [
          _info('Distance', '${t.distanceKm.toStringAsFixed(0)} km'),
          _info('Durée', duree(t.dureeEstimeeMin)),
          _info('Prix / place', fcfa(t.prixParPlace)),
        ]),
        if (!estConducteur && t.statut != 'ANNULE' && t.statut != 'TERMINE')
          TextButton.icon(
            onPressed: () => _itineraire(t),
            icon: const Icon(Icons.directions_outlined),
            label: const Text('Itinéraire vers le point de départ'),
          ),
      ]),
      const SizedBox(height: 12),
      Bloc(titre: 'Conducteur et véhicule', icone: Icons.person_outline, children: [
        Row(children: [
          Avatar(nom: '${t.conducteur.prenom} ${t.conducteur.nomInitiale}', photo: t.conducteur.photoProfil),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('${t.conducteur.prenom} ${t.conducteur.nomInitiale}', style: const TextStyle(fontWeight: FontWeight.w700)),
              Text(t.conducteur.noteMoyenne == null
                  ? 'Pas encore d\'avis'
                  : '★ ${t.conducteur.noteMoyenne!.toStringAsFixed(1).replaceAll('.', ',')} / 5'),
            ]),
          ),
        ]),
        const SizedBox(height: 10),
        Text('${t.vehicule} · ${t.modeReservation == 'AUTOMATIQUE' ? 'réservation immédiate' : 'le conducteur accepte chaque demande'}',
            style: const TextStyle(color: Couleurs.texte2)),
        if (t.femmesUniquement) ...[
          const SizedBox(height: 6),
          const Pastille('Trajet réservé aux femmes', couleur: Color(0xFFB4236B)),
        ],
      ]),
      const SizedBox(height: 12),
      if (estConducteur)
        FilledButton.icon(
          onPressed: () => context.pushReplacement('/conduite/${t.id}'),
          icon: const Icon(Icons.manage_accounts_outlined),
          label: const Text('Gérer ce trajet'),
        )
      else if (t.reservable)
        _blocReservation(t)
      else if (t.statut == 'PUBLIE' || t.statut == 'COMPLET')
        const Bandeau('Ce trajet est complet.'),
    ];
  }

  Widget _blocReservation(Trajet t) => Bloc(titre: 'Réserver', icone: Icons.event_seat_outlined, children: [
        Row(children: [
          const Expanded(child: Text('Places')),
          IconButton.outlined(
            onPressed: _places > 1 ? () => setState(() => _places--) : null,
            icon: const Icon(Icons.remove),
            tooltip: 'Une place de moins',
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text('$_places', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          ),
          IconButton.outlined(
            onPressed: _places < t.nombrePlacesDisponibles ? () => setState(() => _places++) : null,
            icon: const Icon(Icons.add),
            tooltip: 'Une place de plus',
          ),
        ]),
        const SizedBox(height: 12),
        const Text('Paiement'),
        const SizedBox(height: 6),
        Wrap(spacing: 8, children: [
          for (final m in _moyens)
            ChoiceChip(
              label: Text(libellesMoyen[m] ?? m),
              selected: _moyen == m,
              onSelected: (_) => setState(() => _moyen = m),
            ),
        ]),
        if (_moyen != 'ESPECES')
          const Padding(
            padding: EdgeInsets.only(top: 6),
            child: Text('Vous paierez en ligne une fois la réservation confirmée.',
                style: TextStyle(color: Couleurs.texte2, fontSize: 12)),
          ),
        const SizedBox(height: 14),
        if (_erreurReservation != null) ...[Bandeau(_erreurReservation!), const SizedBox(height: 12)],
        FilledButton(
          onPressed: _envoi ? null : _reserver,
          child: _envoi
              ? const SizedBox.square(dimension: 22, child: CircularProgressIndicator(strokeWidth: 2.5))
              : Text('Réserver · ${fcfa(t.prixParPlace * _places)}'),
        ),
      ]);

  Widget _etape(String etiquette, Color couleur, String lieu) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(children: [
          CircleAvatar(
              radius: 11,
              backgroundColor: couleur,
              child: Text(etiquette, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800))),
          const SizedBox(width: 10),
          Expanded(child: Text(lieu)),
        ]),
      );

  Widget _info(String libelle, String valeur) => Expanded(
        child: Column(children: [
          Text(libelle, style: const TextStyle(color: Couleurs.texte2, fontSize: 12)),
          const SizedBox(height: 2),
          Text(valeur, style: const TextStyle(fontWeight: FontWeight.w800)),
        ]),
      );
}
