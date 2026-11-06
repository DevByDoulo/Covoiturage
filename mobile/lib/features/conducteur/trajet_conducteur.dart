import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/api.dart';
import '../../core/formats.dart';
import '../../core/modeles.dart';
import '../../core/theme.dart';
import '../../shared/carte.dart';
import '../../shared/widgets.dart';
import 'mes_trajets.dart';
import 'scanner.dart';

/// Trajet vu par son conducteur : demandes reçues (accepter / refuser), embarquement par PIN ou QR code,
/// démarrer, terminer ou annuler le trajet.
class TrajetConducteurPage extends StatefulWidget {
  const TrajetConducteurPage({super.key, required this.id});

  final int id;

  @override
  State<TrajetConducteurPage> createState() => _TrajetConducteurPageState();
}

class _TrajetConducteurPageState extends State<TrajetConducteurPage> {
  Trajet? _trajet;
  List<Reservation> _reservations = const [];
  String? _erreur;
  bool _action = false;
  final _code = TextEditingController();

  @override
  void initState() {
    super.initState();
    _charger();
  }

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<void> _charger() async {
    final api = context.read<Api>();
    try {
      final resultats = await Future.wait([
        api.get('/trajets/${widget.id}'),
        api.get('/trajets/${widget.id}/reservations'),
      ]);
      setState(() {
        _trajet = Trajet.depuisJson(resultats[0] as Map<String, dynamic>);
        _reservations = (resultats[1] as List).map((e) => Reservation.depuisJson(e as Map<String, dynamic>)).toList();
        _erreur = null;
      });
    } catch (e) {
      setState(() => _erreur = ErreurApi.messageDe(e));
    }
  }

  /// Exécute une action, affiche son message, puis recharge le trajet et les passagers.
  Future<void> _executer(Future<Object?> Function(Api api) appel, {String? succes}) async {
    final api = context.read<Api>();
    setState(() => _action = true);
    try {
      await appel(api);
      if (mounted && succes != null) afficherMessage(context, succes);
      await _charger();
    } catch (e) {
      if (mounted) afficherMessage(context, ErreurApi.messageDe(e), erreur: true);
    } finally {
      if (mounted) setState(() => _action = false);
    }
  }

  Future<String?> _demanderMotif({required String titre, required String bouton, String? aide}) => showDialog<String>(
        context: context,
        builder: (c) {
          final motif = TextEditingController();
          return AlertDialog(
            title: Text(titre),
            content: Column(mainAxisSize: MainAxisSize.min, children: [
              if (aide != null) ...[Text(aide), const SizedBox(height: 12)],
              TextField(
                controller: motif,
                maxLength: 500,
                maxLines: 3,
                minLines: 1,
                decoration: const InputDecoration(labelText: 'Motif (facultatif)'),
              ),
            ]),
            actions: [
              TextButton(onPressed: () => Navigator.pop(c), child: const Text('Retour')),
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: Couleurs.erreur, minimumSize: const Size(0, 44)),
                onPressed: () => Navigator.pop(c, motif.text.trim()),
                child: Text(bouton),
              ),
            ],
          );
        },
      );

  Future<void> _refuser(Reservation r) async {
    final motif = await _demanderMotif(titre: 'Refuser la demande de ${r.passager?.prenom} ?', bouton: 'Refuser');
    if (motif == null) return;
    await _executer((api) => api.post('/reservations/${r.id}/refuser', {'motif': motif.isEmpty ? null : motif}),
        succes: 'Demande refusée.');
  }

  Future<void> _annulerTrajet() async {
    final motif = await _demanderMotif(
      titre: 'Annuler ce trajet ?',
      bouton: 'Annuler le trajet',
      aide: 'Les passagers sont prévenus et remboursés s\'ils ont payé en ligne.',
    );
    if (motif == null) return;
    await _executer((api) => api.post('/trajets/${widget.id}/annuler', {'motif': motif.isEmpty ? null : motif}),
        succes: 'Trajet annulé.');
  }

  Future<void> _scanner() async {
    final lu = await Navigator.of(context).push<String>(MaterialPageRoute(builder: (_) => const ScannerPage()));
    if (lu != null) await _embarquer(lu);
  }

  Future<void> _embarquer(String code) async {
    if (code.trim().isEmpty) return;
    final api = context.read<Api>();
    setState(() => _action = true);
    try {
      final e = EmbarquementConfirme.depuisJson(
          await api.post('/trajets/${widget.id}/embarquement', {'code': code.trim()}) as Map<String, dynamic>);
      _code.clear();
      await _charger();
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (c) => AlertDialog(
          icon: const Icon(Icons.check_circle, color: Couleurs.vert, size: 48),
          title: Text('${e.passager.prenom} est à bord'),
          content: Text(
            e.montantAEncaisser > 0
                ? 'Encaissez ${fcfa(e.montantAEncaisser)} en espèces (${e.nombrePlaces} place${e.nombrePlaces > 1 ? 's' : ''}).'
                : 'Déjà payé en ligne : rien à encaisser.',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16),
          ),
          actions: [FilledButton(onPressed: () => Navigator.pop(c), child: const Text('OK'))],
        ),
      );
    } catch (e) {
      if (mounted) afficherMessage(context, ErreurApi.messageDe(e), erreur: true);
    } finally {
      if (mounted) setState(() => _action = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = _trajet;
    return Scaffold(
      appBar: AppBar(title: const Text('Mon trajet'), actions: [
        IconButton(onPressed: _charger, icon: const Icon(Icons.refresh), tooltip: 'Actualiser'),
      ]),
      body: t == null
          ? Center(child: _erreur != null ? Padding(padding: const EdgeInsets.all(24), child: Bandeau(_erreur!)) : const CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _charger,
              child: ListView(padding: const EdgeInsets.fromLTRB(16, 0, 16, 32), children: _contenu(t)),
            ),
    );
  }

  List<Widget> _contenu(Trajet t) {
    final aEmbarquer = _reservations.where((r) => r.statut == 'ACCEPTEE' && !r.embarque).toList();
    final ouvert = t.statut == 'PUBLIE' || t.statut == 'COMPLET' || t.statut == 'EN_COURS';
    return [
      Text('${t.depart.lieu} → ${t.arrivee.lieu}', style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800)),
      const SizedBox(height: 4),
      Wrap(spacing: 8, crossAxisAlignment: WrapCrossAlignment.center, children: [
        Text(dateHeure(t.dateHeureDepart), style: const TextStyle(color: Couleurs.texte2)),
        Pastille(libellesStatutTrajet[t.statut] ?? t.statut, couleur: couleurStatutTrajet(t.statut)),
      ]),
      if (t.statut == 'ANNULE' && t.motifAnnulation != null) ...[
        const SizedBox(height: 8),
        Bandeau('Annulé : ${t.motifAnnulation}'),
      ],
      const SizedBox(height: 12),
      Carte(
        hauteur: 190,
        polyline: t.itinerairePolyline,
        reperes: [
          Repere(t.depart.latitude, t.depart.longitude, 'depart', etiquette: 'A'),
          for (var i = 0; i < t.escales.length; i++)
            Repere(t.escales[i].latitude, t.escales[i].longitude, 'escale', etiquette: '${i + 1}'),
          Repere(t.arrivee.latitude, t.arrivee.longitude, 'arrivee', etiquette: 'B'),
        ],
      ),
      const SizedBox(height: 12),
      Bloc(children: [
        Wrap(spacing: 16, runSpacing: 6, children: [
          Text('${t.distanceKm.toStringAsFixed(0)} km · ${duree(t.dureeEstimeeMin)}'),
          Text('${fcfa(t.prixParPlace)} / place', style: const TextStyle(fontWeight: FontWeight.w700)),
          Text('${t.nombrePlacesDisponibles} place${t.nombrePlacesDisponibles > 1 ? 's' : ''} libre${t.nombrePlacesDisponibles > 1 ? 's' : ''} sur ${t.nombrePlacesTotal}'),
          Text(t.modeReservation == 'AUTOMATIQUE' ? 'Réservation immédiate' : 'Vous acceptez chaque demande'),
        ]),
      ]),
      const SizedBox(height: 12),
      _blocPassagers(),
      if (ouvert && aEmbarquer.isNotEmpty) ...[const SizedBox(height: 12), _blocEmbarquement(aEmbarquer.length)],
      const SizedBox(height: 16),
      if (_action) const LinearProgressIndicator(),
      if (t.statut == 'PUBLIE' || t.statut == 'COMPLET') ...[
        FilledButton.icon(
          onPressed: _action
              ? null
              : () => _executer((api) => api.post('/trajets/${widget.id}/demarrer', {}), succes: 'Trajet démarré. Bonne route !'),
          icon: const Icon(Icons.play_arrow),
          label: const Text('Démarrer le trajet'),
        ),
        const Padding(
          padding: EdgeInsets.only(top: 4, bottom: 8),
          child: Text('Possible à partir d\'une heure avant le départ.',
              textAlign: TextAlign.center, style: TextStyle(color: Couleurs.texte2, fontSize: 12)),
        ),
        TextButton(
          onPressed: _action ? null : _annulerTrajet,
          style: TextButton.styleFrom(foregroundColor: Couleurs.erreur),
          child: const Text('Annuler le trajet'),
        ),
      ],
      if (t.statut == 'EN_COURS')
        FilledButton.icon(
          onPressed: _action
              ? null
              : () => _executer((api) => api.post('/trajets/${widget.id}/terminer', {}), succes: 'Trajet terminé.'),
          icon: const Icon(Icons.flag),
          label: const Text('Terminer le trajet'),
        ),
    ];
  }

  Widget _blocPassagers() => Bloc(titre: 'Passagers', icone: Icons.group_outlined, children: [
        if (_reservations.isEmpty) const Text('Aucune réservation pour l\'instant.', style: TextStyle(color: Couleurs.texte2)),
        for (final r in _reservations) ...[
          _ligne(r),
          if (r != _reservations.last) const Divider(height: 20),
        ],
      ]);

  Widget _ligne(Reservation r) {
    final p = r.passager;
    final nom = p == null ? 'Passager' : '${p.prenom} ${p.nomInitiale}';
    final couleur = switch (r.statut) {
      'ACCEPTEE' || 'TERMINEE' => Couleurs.vert,
      'EN_ATTENTE' => Couleurs.orange,
      _ => Couleurs.erreur,
    };
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Avatar(nom: nom, photo: p?.photoProfil, rayon: 18),
        const SizedBox(width: 10),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(nom, style: const TextStyle(fontWeight: FontWeight.w700)),
            Text('${r.nombrePlaces} place${r.nombrePlaces > 1 ? 's' : ''} · ${fcfa(r.montantTotal)}',
                style: const TextStyle(color: Couleurs.texte2)),
          ]),
        ),
        r.embarque ? const Pastille('À bord') : Pastille(libellesStatutReservation[r.statut] ?? r.statut, couleur: couleur),
      ]),
      if (r.statut == 'ACCEPTEE' && r.moyenPaiement != null)
        Padding(
          padding: const EdgeInsets.only(top: 4, left: 46),
          child: Text(
              '${libellesMoyen[r.moyenPaiement]} : ${libellesStatutPaiement[r.statutPaiement] ?? '—'}'
              '${r.pointRamassage == null ? '' : ' · prise en charge : ${r.pointRamassage}'}',
              style: const TextStyle(color: Couleurs.texte2, fontSize: 13)),
        ),
      if (r.statut == 'EN_ATTENTE')
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Row(children: [
            Expanded(
              child: FilledButton(
                style: FilledButton.styleFrom(minimumSize: const Size(0, 42)),
                onPressed: _action
                    ? null
                    : () => _executer((api) => api.post('/reservations/${r.id}/accepter', {}), succes: 'Demande acceptée.'),
                child: const Text('Accepter'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(minimumSize: const Size(0, 42)),
                onPressed: _action ? null : () => _refuser(r),
                child: const Text('Refuser'),
              ),
            ),
          ]),
        ),
    ]);
  }

  Widget _blocEmbarquement(int restants) => Bloc(titre: 'Embarquement', icone: Icons.qr_code_scanner, children: [
        Text('$restants passager${restants > 1 ? 's' : ''} à faire monter. Scannez son QR code ou saisissez son code à 6 chiffres.',
            style: const TextStyle(color: Couleurs.texte2)),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: _action ? null : _scanner,
          icon: const Icon(Icons.qr_code_scanner),
          label: const Text('Scanner le QR code'),
        ),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(
            child: TextField(
              controller: _code,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(6)],
              style: const TextStyle(letterSpacing: 6, fontWeight: FontWeight.w700),
              decoration: const InputDecoration(labelText: 'Code à 6 chiffres', counterText: ''),
              onSubmitted: _embarquer,
            ),
          ),
          const SizedBox(width: 8),
          ListenableBuilder(
            listenable: _code,
            builder: (_, _) => FilledButton(
              style: FilledButton.styleFrom(minimumSize: const Size(0, 52)),
              onPressed: _action || _code.text.length != 6 ? null : () => _embarquer(_code.text),
              child: const Text('Valider'),
            ),
          ),
        ]),
      ]);
}
