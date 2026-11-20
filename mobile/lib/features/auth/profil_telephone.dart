import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api.dart';
import '../../core/session.dart';
import '../../shared/widgets.dart';

/// Nouveau numéro vérifié par code : informations manquantes (prénom, nom, sexe), mot de passe facultatif et
/// conditions ; le compte est alors créé et connecté (le routeur ouvre l'application). [jeton] : remis par le serveur
/// après le code, valable 15 minutes.
class ProfilTelephonePage extends StatefulWidget {
  const ProfilTelephonePage({super.key, required this.jeton});

  final String jeton;

  @override
  State<ProfilTelephonePage> createState() => _ProfilTelephonePageState();
}

class _ProfilTelephonePageState extends State<ProfilTelephonePage> {
  final _formulaire = GlobalKey<FormState>();
  final _prenom = TextEditingController();
  final _nom = TextEditingController();
  final _motDePasse = TextEditingController();
  String? _sexe;
  bool _cgu = false;
  bool _envoi = false;
  String? _erreur;

  static final _regleMotDePasse = RegExp(r'^(?=.*[A-Za-z])(?=.*\d).{8,72}$');

  @override
  void dispose() {
    for (final c in [_prenom, _nom, _motDePasse]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _creer() async {
    setState(() => _erreur = null);
    if (!_formulaire.currentState!.validate()) return;
    if (_sexe == null) {
      setState(() => _erreur = 'Indiquez si vous êtes une femme ou un homme.');
      return;
    }
    if (!_cgu) {
      setState(() => _erreur = "Vous devez accepter les conditions d'utilisation.");
      return;
    }
    setState(() => _envoi = true);
    try {
      await context.read<Session>().terminerInscriptionTelephone(
            widget.jeton,
            prenom: _prenom.text,
            nom: _nom.text,
            sexe: _sexe,
            motDePasse: _motDePasse.text.isEmpty ? null : _motDePasse.text,
          );
    } catch (e) {
      setState(() => _erreur = ErreurApi.messageDe(e));
    } finally {
      if (mounted) setState(() => _envoi = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Créer votre compte')),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
            child: Form(
              key: _formulaire,
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                const Text('Votre numéro est vérifié. Encore quelques informations.'),
                const SizedBox(height: 16),
                if (_erreur != null) ...[Bandeau(_erreur!), const SizedBox(height: 12)],
                TextFormField(
                  key: const Key('prenom'),
                  controller: _prenom,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(labelText: 'Prénom', prefixIcon: Icon(Icons.badge_outlined)),
                  validator: (v) => (v ?? '').trim().isEmpty ? 'Obligatoire' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  key: const Key('nom'),
                  controller: _nom,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(labelText: 'Nom', prefixIcon: Icon(Icons.badge_outlined)),
                  validator: (v) => (v ?? '').trim().isEmpty ? 'Obligatoire' : null,
                ),
                const SizedBox(height: 16),
                const Text('Vous êtes… (pour les trajets « femmes uniquement »)'),
                const SizedBox(height: 8),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'FEMME', label: Text('Une femme')),
                    ButtonSegment(value: 'HOMME', label: Text('Un homme')),
                  ],
                  selected: {?_sexe},
                  emptySelectionAllowed: true,
                  onSelectionChanged: (s) => setState(() => _sexe = s.isEmpty ? null : s.first),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  key: const Key('motDePasse'),
                  controller: _motDePasse,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Mot de passe (facultatif)',
                    prefixIcon: Icon(Icons.lock_outline),
                    helperText: 'Sans mot de passe, vous vous connectez avec un code reçu par SMS.',
                    helperMaxLines: 2,
                  ),
                  validator: (v) => (v ?? '').isEmpty || _regleMotDePasse.hasMatch(v!)
                      ? null
                      : 'Au moins 8 caractères, dont une lettre et un chiffre',
                ),
                const SizedBox(height: 8),
                CheckboxListTile(
                  value: _cgu,
                  onChanged: (v) => setState(() => _cgu = v ?? false),
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  title: const Text("J'ai 18 ans ou plus et j'accepte les conditions d'utilisation et la politique de confidentialité"),
                ),
                const LiensLegaux(),
                const SizedBox(height: 8),
                FilledButton(
                  onPressed: _envoi ? null : _creer,
                  child: _envoi
                      ? const SizedBox.square(dimension: 22, child: CircularProgressIndicator(strokeWidth: 2.5))
                      : const Text('Créer mon compte'),
                ),
              ]),
            ),
          ),
        ),
      );
}
