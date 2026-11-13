import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api.dart';
import '../../core/session.dart';
import '../../core/theme.dart';
import '../../shared/widgets.dart';

/// Suppression du compte (droit à l'effacement), confirmée par le mot de passe ou, pour un compte créé avec Google,
/// par un code reçu par email ou SMS. Délai de grâce de 30 jours : se reconnecter annule la suppression.
class SuppressionComptePage extends StatefulWidget {
  const SuppressionComptePage({super.key});

  @override
  State<SuppressionComptePage> createState() => _SuppressionComptePageState();
}

class _SuppressionComptePageState extends State<SuppressionComptePage> {
  final _motDePasse = TextEditingController();
  final _code = TextEditingController();
  bool _compris = false;
  bool _masque = true;
  bool _codeEnvoye = false;
  bool _envoi = false;
  String? _destination;
  String? _erreur;

  @override
  void dispose() {
    _motDePasse.dispose();
    _code.dispose();
    super.dispose();
  }

  bool get _avecMotDePasse => context.read<Session>().utilisateur?.motDePasseDefini ?? true;

  bool get _pret => _compris && (_avecMotDePasse ? _motDePasse.text.isNotEmpty : _code.text.length == 6);

  Future<void> _envoyerCode() async {
    setState(() {
      _envoi = true;
      _erreur = null;
    });
    try {
      final r = await context.read<Session>().envoyerCodeSuppression();
      if (!mounted) return;
      setState(() {
        _codeEnvoye = true;
        _destination = r.destination;
      });
    } catch (e) {
      if (mounted) setState(() => _erreur = ErreurApi.messageDe(e));
    } finally {
      if (mounted) setState(() => _envoi = false);
    }
  }

  Future<void> _supprimer() async {
    setState(() {
      _envoi = true;
      _erreur = null;
    });
    try {
      // Réussie, la session est fermée : le routeur ramène à l'écran de connexion.
      await context.read<Session>().supprimerCompte(
            motDePasse: _avecMotDePasse ? _motDePasse.text : null,
            code: _avecMotDePasse ? null : _code.text.trim(),
          );
    } catch (e) {
      if (mounted) setState(() => _erreur = ErreurApi.messageDe(e));
    } finally {
      if (mounted) setState(() => _envoi = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Supprimer mon compte')),
        body: ListView(padding: const EdgeInsets.all(16), children: [
          Bloc(titre: 'Ce qui va se passer', icone: Icons.info_outline, children: const [
            Text(
              'Votre compte est immédiatement invisible et vous êtes déconnecté de tous vos appareils. '
              'Pendant 30 jours, il vous suffit de vous reconnecter pour annuler la suppression.\n\n'
              'Passé ce délai, vos données personnelles (nom, email, téléphone, photo, documents, alertes) sont '
              'définitivement effacées. Les paiements et les trajets passés sont conservés sans lien avec votre '
              'identité, comme la loi l\'exige.',
            ),
          ]),
          const SizedBox(height: 12),
          if (_avecMotDePasse)
            TextField(
              controller: _motDePasse,
              obscureText: _masque,
              autofillHints: const [AutofillHints.password],
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                labelText: 'Confirmez avec votre mot de passe',
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(_masque ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                  tooltip: _masque ? 'Afficher le mot de passe' : 'Masquer le mot de passe',
                  onPressed: () => setState(() => _masque = !_masque),
                ),
              ),
            )
          else if (!_codeEnvoye)
            OutlinedButton.icon(
              onPressed: _envoi ? null : _envoyerCode,
              icon: const Icon(Icons.mark_email_unread_outlined),
              label: const Text('Recevoir un code de confirmation'),
            )
          else ...[
            Text('Code envoyé${_destination == null ? '' : ' à $_destination'}.', style: const TextStyle(color: Couleurs.texte2)),
            const SizedBox(height: 8),
            TextField(
              controller: _code,
              keyboardType: TextInputType.number,
              maxLength: 6,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(labelText: 'Code à 6 chiffres', prefixIcon: Icon(Icons.pin_outlined)),
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(onPressed: _envoi ? null : _envoyerCode, child: const Text('Renvoyer le code')),
            ),
          ],
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            value: _compris,
            onChanged: (v) => setState(() => _compris = v ?? false),
            title: const Text('Je comprends que mon compte sera supprimé définitivement dans 30 jours.'),
          ),
          if (_erreur != null) ...[const SizedBox(height: 8), Bandeau(_erreur!)],
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: (_pret && !_envoi) ? _supprimer : null,
            style: FilledButton.styleFrom(backgroundColor: Couleurs.erreur),
            icon: _envoi
                ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2.5))
                : const Icon(Icons.delete_outline),
            label: const Text('Supprimer mon compte'),
          ),
        ]),
      );
}
