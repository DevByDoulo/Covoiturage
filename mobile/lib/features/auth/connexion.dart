import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/api.dart';
import '../../core/session.dart';
import '../../core/theme.dart';
import '../../shared/widgets.dart';
import 'verification.dart';

/// Connexion par email ou numéro de téléphone (le compte doit être vérifié ; sinon un code est renvoyé).
class ConnexionPage extends StatefulWidget {
  const ConnexionPage({super.key});

  @override
  State<ConnexionPage> createState() => _ConnexionPageState();
}

class _ConnexionPageState extends State<ConnexionPage> {
  final _formulaire = GlobalKey<FormState>();
  final _identifiant = TextEditingController();
  final _motDePasse = TextEditingController();
  bool _envoi = false;
  bool _masque = true;
  String? _erreur;

  @override
  void dispose() {
    _identifiant.dispose();
    _motDePasse.dispose();
    super.dispose();
  }

  Future<void> _connecter() async {
    if (!_formulaire.currentState!.validate()) return;
    setState(() {
      _envoi = true;
      _erreur = null;
    });
    try {
      final r = await context.read<Session>().connexion(_identifiant.text, _motDePasse.text);
      if (!mounted) return;
      if (!r.connecte) {
        // Compte pas encore vérifié : un code vient d'être envoyé.
        context.push('/verification',
            extra: DemandeVerification(_identifiant.text.trim(), r.canal ?? 'SMS', r.destination, r.renvoiDans));
      }
    } catch (e) {
      setState(() => _erreur = ErreurApi.messageDe(e));
    } finally {
      if (mounted) setState(() => _envoi = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Form(
                  key: _formulaire,
                  child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                    const Center(child: Logo(taille: 34)),
                    const SizedBox(height: 8),
                    const Text('Teranga & mobilité au Sénégal',
                        textAlign: TextAlign.center, style: TextStyle(color: Couleurs.texte2)),
                    const SizedBox(height: 32),
                    const Text('Connexion', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 16),
                    if (_erreur != null) ...[Bandeau(_erreur!), const SizedBox(height: 12)],
                    TextFormField(
                      controller: _identifiant,
                      keyboardType: TextInputType.emailAddress,
                      autofillHints: const [AutofillHints.username],
                      decoration: const InputDecoration(
                          labelText: 'Email ou téléphone', prefixIcon: Icon(Icons.person_outline)),
                      validator: (v) => (v ?? '').trim().isEmpty ? 'Saisissez votre email ou votre numéro' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _motDePasse,
                      obscureText: _masque,
                      autofillHints: const [AutofillHints.password],
                      decoration: InputDecoration(
                        labelText: 'Mot de passe',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(_masque ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                          tooltip: _masque ? 'Afficher le mot de passe' : 'Masquer le mot de passe',
                          onPressed: () => setState(() => _masque = !_masque),
                        ),
                      ),
                      validator: (v) => (v ?? '').isEmpty ? 'Saisissez votre mot de passe' : null,
                      onFieldSubmitted: (_) => _connecter(),
                    ),
                    const SizedBox(height: 20),
                    FilledButton(
                      onPressed: _envoi ? null : _connecter,
                      child: _envoi
                          ? const SizedBox.square(dimension: 22, child: CircularProgressIndicator(strokeWidth: 2.5))
                          : const Text('Se connecter'),
                    ),
                    const SizedBox(height: 16),
                    Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      const Text('Pas encore de compte ?'),
                      TextButton(onPressed: () => context.push('/inscription'), child: const Text("S'inscrire")),
                    ]),
                  ]),
                ),
              ),
            ),
          ),
        ),
      );
}
