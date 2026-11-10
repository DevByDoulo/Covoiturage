import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/api.dart';
import '../../core/formats.dart';
import '../../core/modeles.dart';
import '../../core/theme.dart';
import '../../shared/widgets.dart';
import '../avis/avis.dart';
import '../messages/messages.dart';
import '../signalements/signalements.dart';

/// Réservations du passager : suivi, code d'embarquement (PIN + QR), paiement en ligne et annulation.
class ReservationsPage extends StatefulWidget {
  const ReservationsPage({super.key});

  @override
  State<ReservationsPage> createState() => _ReservationsPageState();
}

class _ReservationsPageState extends State<ReservationsPage> {
  List<Reservation>? _liste;
  String? _erreur;
  int? _action;
  int _version = 0;

  @override
  void initState() {
    super.initState();
    _charger();
  }

  Future<void> _charger() async {
    try {
      final brut = await context.read<Api>().get('/moi/reservations') as List;
      setState(() {
        _liste = brut.map((e) => Reservation.depuisJson(e as Map<String, dynamic>)).toList();
        _erreur = null;
        _version++;
      });
    } catch (e) {
      setState(() => _erreur = ErreurApi.messageDe(e));
    }
  }

  Future<void> _code(Reservation r) async {
    try {
      final c = CodeEmbarquement.depuisJson(
          await context.read<Api>().get('/reservations/${r.id}/embarquement') as Map<String, dynamic>);
      if (!mounted) return;
      await showModalBottomSheet<void>(
        context: context,
        showDragHandle: true,
        builder: (_) => _FeuilleCode(code: c),
      );
    } catch (e) {
      if (mounted) afficherMessage(context, ErreurApi.messageDe(e), erreur: true);
    }
  }

  /// Ouvre la page de paiement de l'opérateur (Wave ou Orange Money, via PayDunya) dans le navigateur.
  Future<void> _payer(Reservation r) async {
    setState(() => _action = r.id);
    try {
      final s = await context.read<Api>().post('/reservations/${r.id}/paiement', {}) as Map<String, dynamic>;
      final url = s['urlPaiement'] as String?;
      if (url != null) await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      if (mounted) {
        afficherMessage(context, 'Après le paiement, revenez ici et touchez « J\'ai payé : vérifier ».');
      }
    } catch (e) {
      if (mounted) afficherMessage(context, ErreurApi.messageDe(e), erreur: true);
    } finally {
      if (mounted) setState(() => _action = null);
    }
  }

  /// Demande à l'opérateur l'état du paiement de cette réservation.
  Future<void> _verifier(Reservation r) async {
    final api = context.read<Api>();
    setState(() => _action = r.id);
    try {
      final paiements = await api.get('/moi/paiements') as List;
      final ligne = paiements.cast<Map<String, dynamic>>().where((p) => p['idReservation'] == r.id).firstOrNull;
      if (ligne == null) throw ErreurApi(404, 'Aucun paiement en ligne trouvé pour cette réservation.');
      final v = await api.post('/paiements/${Uri.encodeComponent(ligne['referenceTransaction'] as String)}/verifier', {})
          as Map<String, dynamic>;
      if (!mounted) return;
      afficherMessage(
          context,
          v['statut'] == 'REUSSI'
              ? 'Paiement reçu, merci !'
              : 'Paiement pas encore confirmé (${libellesStatutPaiement[v['statut']] ?? v['statut']}).');
      await _charger();
    } catch (e) {
      if (mounted) afficherMessage(context, ErreurApi.messageDe(e), erreur: true);
    } finally {
      if (mounted) setState(() => _action = null);
    }
  }

  Future<void> _annuler(Reservation r) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Annuler la réservation ?'),
        content: Text(r.statutPaiement == 'REUSSI'
            ? 'Le montant payé vous sera remboursé intégralement.'
            : '${r.lieuDepart} → ${r.lieuArrivee}, ${dateCourte(r.dateHeureDepart)}'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Garder')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Couleurs.erreur, minimumSize: const Size(0, 44)),
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Annuler la réservation'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    setState(() => _action = r.id);
    try {
      await context.read<Api>().post('/reservations/${r.id}/annuler', {'motif': null});
      if (mounted) afficherMessage(context, 'Réservation annulée.');
      await _charger();
    } catch (e) {
      if (mounted) afficherMessage(context, ErreurApi.messageDe(e), erreur: true);
    } finally {
      if (mounted) setState(() => _action = null);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Mes réservations'), actions: [
          const BoutonMessages(),
          IconButton(onPressed: _charger, icon: const Icon(Icons.refresh), tooltip: 'Actualiser'),
        ]),
        body: RefreshIndicator(onRefresh: _charger, child: _corps()),
      );

  Widget _corps() {
    if (_liste == null) {
      return ListView(padding: const EdgeInsets.all(24), children: [
        if (_erreur != null) Bandeau(_erreur!) else const Center(child: CircularProgressIndicator()),
      ]);
    }
    if (_liste!.isEmpty) {
      return ListView(padding: const EdgeInsets.all(24), children: [
        BlocAvisADonner(key: ValueKey(_version)),
        const Icon(Icons.confirmation_number_outlined, size: 48, color: Couleurs.texte2),
        const SizedBox(height: 8),
        const Text('Aucune réservation pour l\'instant.', textAlign: TextAlign.center),
        const SizedBox(height: 16),
        FilledButton(onPressed: () => context.go('/rechercher'), child: const Text('Rechercher un trajet')),
      ]);
    }
    return ListView(padding: const EdgeInsets.fromLTRB(16, 0, 16, 24), children: [
      // Voyages terminés à noter ; la clé le recharge à chaque actualisation.
      BlocAvisADonner(key: ValueKey(_version)),
      for (final r in _liste!) ...[_carte(r), const SizedBox(height: 12)],
    ]);
  }

  Widget _carte(Reservation r) {
    final enCours = _action == r.id;
    final couleur = switch (r.statut) {
      'ACCEPTEE' || 'TERMINEE' => Couleurs.vert,
      'EN_ATTENTE' => Couleurs.orange,
      _ => Couleurs.erreur,
    };
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        InkWell(
          onTap: () => context.push('/trajets/${r.idTrajet}'),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('${r.lieuDepart} → ${r.lieuArrivee}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
              const SizedBox(height: 2),
              Text('${dateHeure(r.dateHeureDepart)} · avec ${r.conducteur.prenom}',
                  style: const TextStyle(color: Couleurs.texte2)),
              const SizedBox(height: 8),
              Wrap(spacing: 8, runSpacing: 6, crossAxisAlignment: WrapCrossAlignment.center, children: [
                Pastille(libellesStatutReservation[r.statut] ?? r.statut, couleur: couleur),
                Text('${r.nombrePlaces} place${r.nombrePlaces > 1 ? 's' : ''} · ${fcfa(r.montantTotal)}'),
                if (r.moyenPaiement != null && r.statutPaiement != null)
                  Text('${libellesMoyen[r.moyenPaiement]} : ${libellesStatutPaiement[r.statutPaiement]}',
                      style: const TextStyle(color: Couleurs.texte2)),
                if (r.embarque) const Pastille('À bord'),
              ]),
              if (r.motifAnnulation != null && (r.statut == 'ANNULEE' || r.statut == 'REFUSEE')) ...[
                const SizedBox(height: 6),
                Text(r.motifAnnulation!, style: const TextStyle(color: Couleurs.texte2)),
              ],
            ]),
          ),
        ),
        if (enCours)
          const LinearProgressIndicator(minHeight: 2)
        else if (r.active && !r.embarque)
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
            child: Wrap(spacing: 4, children: [
              if (r.statut == 'ACCEPTEE')
                TextButton.icon(onPressed: () => _code(r), icon: const Icon(Icons.qr_code_2), label: const Text('Code d\'embarquement')),
              if (r.aPayerEnLigne) ...[
                TextButton.icon(
                    onPressed: () => _payer(r),
                    icon: const Icon(Icons.payments_outlined),
                    label: Text('Payer par ${libellesMoyen[r.moyenPaiement]}')),
                TextButton(onPressed: () => _verifier(r), child: const Text('J\'ai payé : vérifier')),
              ],
              BoutonEcrire(idTrajet: r.idTrajet, prenom: r.conducteur.prenom),
              if (r.statut == 'ACCEPTEE')
                BoutonSignaler(idUtilisateur: r.conducteur.id, prenom: r.conducteur.prenom, idTrajet: r.idTrajet),
              if (r.statut == 'ACCEPTEE' && const ['PUBLIE', 'COMPLET', 'EN_COURS'].contains(r.statutTrajet))
                TextButton.icon(
                  onPressed: () => context.push('/trajets/${r.idTrajet}/suivi'),
                  icon: const Icon(Icons.share_location),
                  label: Text('Suivre ${r.conducteur.prenom} en direct'),
                ),
              TextButton(
                onPressed: () => _annuler(r),
                style: TextButton.styleFrom(foregroundColor: Couleurs.erreur),
                child: const Text('Annuler'),
              ),
            ]),
          )
        else if (r.statut == 'ACCEPTEE' || r.statut == 'TERMINEE')
          // Voyage effectué (ou passager à bord) : on peut encore signaler le conducteur.
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
            child: BoutonSignaler(idUtilisateur: r.conducteur.id, prenom: r.conducteur.prenom, idTrajet: r.idTrajet),
          ),
      ]),
    );
  }
}

/// Code à montrer au conducteur au moment de monter : PIN à 6 chiffres et QR code.
class _FeuilleCode extends StatelessWidget {
  const _FeuilleCode({required this.code});

  final CodeEmbarquement code;

  @override
  Widget build(BuildContext context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text('Donnez ce code au conducteur en montant', style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            Text(code.codePin,
                style: const TextStyle(fontSize: 40, letterSpacing: 10, fontWeight: FontWeight.w900, color: Couleurs.vert)),
            const SizedBox(height: 12),
            QrImageView(data: code.qrContenu, size: 180),
            const SizedBox(height: 12),
            Text(
              code.montantAPayer > 0
                  ? 'À régler en espèces : ${fcfa(code.montantAPayer)}'
                  : 'Déjà payé : rien à régler au conducteur.',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text('Valable jusqu\'au ${dateCourte(code.dateExpiration)}', style: const TextStyle(color: Couleurs.texte2)),
          ]),
        ),
      );
}
