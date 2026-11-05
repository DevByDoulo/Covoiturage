import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/api.dart';
import '../../core/session.dart';
import '../../shared/widgets.dart';
import 'verification.dart';

/// Inscription : un code est ensuite envoyé par email (ou SMS) pour vérifier le compte.
class InscriptionPage extends StatefulWidget {
  const InscriptionPage({super.key});

  @override
  State<InscriptionPage> createState() => _InscriptionPageState();
}

class _InscriptionPageState extends State<InscriptionPage> {
  final _formulaire = GlobalKey<FormState>();
  final _prenom = TextEditingController();
  final _nom = TextEditingController();
  final _email = TextEditingController();
  final _telephone = TextEditingController();
  final _motDePasse = TextEditingController();
  String? _sexe;
  bool _cgu = false;
  bool _envoi = false;
  String? _erreur;
  Map<String, String> _erreursChamps = const {};

  static final _regleMotDePasse = RegExp(r'^(?=.*[A-Za-z])(?=.*\d).{8,72}$');

  @override
  void dispose() {
    for (final c in [_prenom, _nom, _email, _telephone, _motDePasse]) {
      c.dispose();
    }
    super.dispose();
  }

  /// 77 123 45 67 → 771234567 (9 chiffres) ; le backend ajoute l'indicatif +221.
  String get _numero => _telephone.text.replaceAll(RegExp(r'\D'), '').replaceFirst(RegExp(r'^221(?=\d{9}$)'), '');

  Future<void> _inscrire() async {
    setState(() {
      _erreur = null;
      _erreursChamps = const {};
    });
    if (!_formulaire.currentState!.validate()) return;
    if (!_cgu) {
      setState(() => _erreur = "Vous devez accepter les conditions d'utilisation.");
      return;
    }
    setState(() => _envoi = true);
    try {
      final r = await context.read<Session>().inscription({
        'prenom': _prenom.text.trim(),
        'nom': _nom.text.trim(),
        'email': _email.text.trim(),
        'telephone': _numero,
        'motDePasse': _motDePasse.text,
        'sexe': _sexe,
      });
      if (!mounted) return;
      if (!r.connecte) {
        context.push('/verification', extra: DemandeVerification(_numero, r.canal ?? 'EMAIL', r.destination, r.renvoiDans));
      }
    } on ErreurApi catch (e) {
      setState(() {
        _erreur = e.message;
        _erreursChamps = {...e.erreurs, if (e.champ != null) e.champ!: e.message};
      });
    } catch (e) {
      setState(() => _erreur = ErreurApi.messageDe(e));
    } finally {
      if (mounted) setState(() => _envoi = false);
    }
  }

  InputDecoration _deco(String libelle, String champ, IconData icone) =>
      InputDecoration(labelText: libelle, prefixIcon: Icon(icone), errorText: _erreursChamps[champ]);

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Créer un compte')),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
            child: Form(
              key: _formulaire,
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                if (_erreur != null) ...[Bandeau(_erreur!), const SizedBox(height: 12)],
                Row(children: [
                  Expanded(
                    child: TextFormField(
                      controller: _prenom,
                      textCapitalization: TextCapitalization.words,
                      decoration: _deco('Prénom', 'prenom', Icons.badge_outlined),
                      validator: (v) => (v ?? '').trim().isEmpty ? 'Obligatoire' : null,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      controller: _nom,
                      textCapitalization: TextCapitalization.words,
                      decoration: _deco('Nom', 'nom', Icons.badge_outlined),
                      validator: (v) => (v ?? '').trim().isEmpty ? 'Obligatoire' : null,
                    ),
                  ),
                ]),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  decoration: _deco('Email', 'email', Icons.mail_outline),
                  validator: (v) => RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch((v ?? '').trim())
                      ? null
                      : 'Adresse email invalide',
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _telephone,
                  keyboardType: TextInputType.phone,
                  decoration: _deco('Téléphone (77 123 45 67)', 'telephone', Icons.phone_outlined),
                  validator: (_) => RegExp(r'^7\d{8}$').hasMatch(_numero)
                      ? null
                      : 'Numéro sénégalais à 9 chiffres, commençant par 7',
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _motDePasse,
                  obscureText: true,
                  decoration: _deco('Mot de passe', 'motDePasse', Icons.lock_outline),
                  validator: (v) => _regleMotDePasse.hasMatch(v ?? '')
                      ? null
                      : 'Au moins 8 caractères, dont une lettre et un chiffre',
                ),
                const SizedBox(height: 12),
                TextFormField(
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Confirmer le mot de passe', prefixIcon: Icon(Icons.lock_outline)),
                  validator: (v) => v == _motDePasse.text ? null : 'Les deux mots de passe ne correspondent pas',
                ),
                const SizedBox(height: 16),
                const Text('Sexe (pour les trajets « femmes uniquement »)'),
                const SizedBox(height: 8),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'FEMME', label: Text('Femme')),
                    ButtonSegment(value: 'HOMME', label: Text('Homme')),
                  ],
                  selected: {?_sexe},
                  emptySelectionAllowed: true,
                  onSelectionChanged: (s) => setState(() => _sexe = s.isEmpty ? null : s.first),
                ),
                const SizedBox(height: 8),
                CheckboxListTile(
                  value: _cgu,
                  onChanged: (v) => setState(() => _cgu = v ?? false),
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  title: const Text("J'accepte les conditions d'utilisation"),
                ),
                const SizedBox(height: 8),
                FilledButton(
                  onPressed: _envoi ? null : _inscrire,
                  child: _envoi
                      ? const SizedBox.square(dimension: 22, child: CircularProgressIndicator(strokeWidth: 2.5))
                      : const Text("S'inscrire"),
                ),
              ]),
            ),
          ),
        ),
      );
}
