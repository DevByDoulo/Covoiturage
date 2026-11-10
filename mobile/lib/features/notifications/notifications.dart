import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/api.dart';
import '../../core/modeles.dart';
import '../../core/theme.dart';
import '../../shared/widgets.dart';
import '../messages/messages.dart';

/// Nombre de notifications non lues (pastille de l'onglet), rafraîchi toutes les 30 s pendant la session.
class CompteurNotifications extends ChangeNotifier {
  CompteurNotifications(this._api);

  final Api _api;
  Timer? _minuteur;
  int nonLues = 0;

  void suivre(bool actif) {
    _minuteur?.cancel();
    _minuteur = null;
    if (!actif) {
      nonLues = 0;
      notifyListeners();
      return;
    }
    compter();
    _minuteur = Timer.periodic(const Duration(seconds: 30), (_) => compter());
  }

  Future<void> compter() async {
    try {
      final r = await _api.get('/moi/notifications/non-lues') as Map<String, dynamic>;
      nonLues = (r['nombre'] as num).toInt();
      notifyListeners();
    } catch (_) {}
  }

  @override
  void dispose() {
    _minuteur?.cancel();
    super.dispose();
  }
}

const _icones = {
  'RESERVATION_DEMANDEE': Icons.group_outlined,
  'RESERVATION_CONFIRMEE': Icons.check_circle_outline,
  'RESERVATION_REFUSEE': Icons.cancel_outlined,
  'RESERVATION_ANNULEE': Icons.cancel_outlined,
  'TRAJET_MODIFIE': Icons.edit_outlined,
  'TRAJET_ANNULE': Icons.warning_amber_outlined,
  'RAPPEL_TRAJET': Icons.schedule,
  'EMBARQUEMENT_CONFIRME': Icons.directions_car_outlined,
  'ALERTE_TRAJET': Icons.search,
  'AVIS_RECU': Icons.star_outline,
  'MESSAGE_RECU': Icons.chat_bubble_outline,
  'SIGNALEMENT_TRAITE': Icons.flag_outlined,
};

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  List<NotificationApp>? _liste;
  String? _erreur;

  @override
  void initState() {
    super.initState();
    _charger();
  }

  Future<void> _charger() async {
    try {
      final page = await context.read<Api>().get('/moi/notifications', query: {'page': 0, 'taille': 30}) as Map<String, dynamic>;
      setState(() {
        _liste = (page['content'] as List).map((e) => NotificationApp.depuisJson(e as Map<String, dynamic>)).toList();
        _erreur = null;
      });
    } catch (e) {
      setState(() => _erreur = ErreurApi.messageDe(e));
    }
  }

  Future<void> _ouvrir(NotificationApp n) async {
    final api = context.read<Api>();
    final compteur = context.read<CompteurNotifications>();
    if (!n.lu) {
      setState(() => n.lu = true);
      api.post('/moi/notifications/${n.id}/lue').then((_) => compteur.compter(), onError: (_) {});
    }
    // Liens du site : seuls ceux qui existent dans l'application mobile sont suivis.
    final lien = n.lien ?? '';
    if (RegExp(r'^/trajets/\d+(/(suivi|guidage))?$').hasMatch(lien)) {
      context.push(lien);
    } else if (RegExp(r'^/messages(/\d+)?$').hasMatch(lien)) {
      context.push(lien);
    } else if (lien.startsWith('/reservations')) {
      context.go('/reservations');
    }
  }

  Future<void> _toutLire() async {
    try {
      await context.read<Api>().post('/moi/notifications/lues');
      if (!mounted) return;
      context.read<CompteurNotifications>().compter();
      setState(() => _liste?.forEach((n) => n.lu = true));
    } catch (e) {
      if (mounted) afficherMessage(context, ErreurApi.messageDe(e), erreur: true);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Notifications'), actions: [
          const BoutonMessages(),
          if (_liste?.any((n) => !n.lu) ?? false)
            TextButton(onPressed: _toutLire, child: const Text('Tout marquer comme lu')),
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
      return ListView(padding: const EdgeInsets.all(32), children: const [
        Icon(Icons.notifications_none, size: 48, color: Couleurs.texte2),
        SizedBox(height: 8),
        Text('Aucune notification pour le moment.', textAlign: TextAlign.center),
      ]);
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
      itemCount: _liste!.length,
      separatorBuilder: (_, _) => const SizedBox(height: 6),
      itemBuilder: (_, i) {
        final n = _liste![i];
        return Card(
          color: n.lu ? Colors.white : Couleurs.vertClair,
          child: ListTile(
            onTap: () => _ouvrir(n),
            leading: Icon(_icones[n.type] ?? Icons.notifications_outlined, color: Couleurs.vert),
            title: Text(n.titre, style: TextStyle(fontWeight: n.lu ? FontWeight.w500 : FontWeight.w800)),
            subtitle: Text('${n.contenu}\n${DateFormat("d MMM, HH:mm", 'fr_FR').format(n.dateEnvoi)}'),
            isThreeLine: true,
          ),
        );
      },
    );
  }
}
