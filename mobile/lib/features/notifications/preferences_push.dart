import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api.dart';
import '../../core/push.dart';
import '../../core/theme.dart';
import '../../shared/widgets.dart';

/// Interrupteur « Notifications push » (Profil) : préférence du compte (`/moi/notifications/preferences`), valable
/// sur tous ses appareils. Les notifications restent visibles dans l'onglet Notifications.
class InterrupteurPush extends StatefulWidget {
  const InterrupteurPush({super.key});

  @override
  State<InterrupteurPush> createState() => _InterrupteurPushState();
}

class _InterrupteurPushState extends State<InterrupteurPush> {
  bool? _actif;
  bool _envoi = false;

  @override
  void initState() {
    super.initState();
    _charger();
  }

  Future<void> _charger() async {
    try {
      final r = await context.read<Api>().get('/moi/notifications/preferences') as Map<String, dynamic>;
      if (mounted) setState(() => _actif = r['pushActive'] as bool? ?? true);
    } catch (_) {
      if (mounted) setState(() => _actif = true);
    }
  }

  Future<void> _changer(bool valeur) async {
    final api = context.read<Api>();
    final push = context.read<ServicePush>();
    setState(() {
      _actif = valeur;
      _envoi = true;
    });
    try {
      final r = await api.put('/moi/notifications/preferences', {'pushActive': valeur}) as Map<String, dynamic>;
      if (!mounted) return;
      setState(() => _actif = r['pushActive'] as bool? ?? valeur);
      if (valeur && push.disponible && !await push.activer() && mounted) {
        afficherMessage(context,
            'Les notifications sont bloquées sur ce téléphone : autorisez-les dans les réglages de l\'application.',
            erreur: true);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _actif = !valeur);
      afficherMessage(context, ErreurApi.messageDe(e), erreur: true);
    } finally {
      if (mounted) setState(() => _envoi = false);
    }
  }

  @override
  Widget build(BuildContext context) => Card(
        child: SwitchListTile(
          secondary: const Icon(Icons.notifications_active_outlined, color: Couleurs.vert),
          title: const Text('Notifications push', style: TextStyle(fontWeight: FontWeight.w700)),
          subtitle: const Text('Réservations, messages et trajets, même appli fermée'),
          value: _actif ?? true,
          onChanged: _actif == null || _envoi ? null : _changer,
        ),
      );
}
