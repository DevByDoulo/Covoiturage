import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/api.dart';
import '../../core/formats.dart';
import '../../core/session.dart';
import '../../core/theme.dart';
import '../../shared/widgets.dart';
import 'google.dart';
import 'verification.dart';

/// Écran de départ, pour se connecter comme pour créer un compte (comme le site) : numéro de téléphone et
/// « Continuer » (code par SMS), puis « ou », Google, puis « Autres options » (e-mail et mot de passe).
/// Un numéro déjà connu connecte son compte ; un nouveau numéro mène à quelques informations.
class ConnexionPage extends StatefulWidget {
  const ConnexionPage({super.key, this.reinitialise = false});

  /// Vrai juste après un changement de mot de passe : affiche un message de confirmation.
  final bool reinitialise;

  @override
  State<ConnexionPage> createState() => _ConnexionPageState();
}

class _ConnexionPageState extends State<ConnexionPage> {
  final _formulaire = GlobalKey<FormState>();
  final _telephone = TextEditingController();
  bool _envoi = false;
  String? _erreur;
  String? _erreurTelephone;

  @override
  void dispose() {
    _telephone.dispose();
    super.dispose();
  }

  Future<void> _continuer() async {
    setState(() {
      _erreur = null;
      _erreurTelephone = null;
    });
    if (!_formulaire.currentState!.validate()) return;
    final telephone = '+221${numeroSenegal(_telephone.text)}';
    setState(() => _envoi = true);
    try {
      final r = await context.read<Session>().codeTelephone(telephone);
      if (!mounted) return;
      context.push('/verification',
          extra: DemandeVerification(telephone, 'SMS', r.destination, r.renvoiDans, parTelephone: true));
    } on ErreurApi catch (e) {
      setState(() => e.champ == 'telephone' ? _erreurTelephone = e.message : _erreur = e.message);
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
                    const Text('Quel est votre numéro de téléphone ?',
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 16),
                    if (context.read<Session>().suppressionDemandee) ...[
                      const Bandeau(
                          "Suppression demandée : votre compte sera supprimé dans 30 jours. Reconnectez-vous avant pour l'annuler.",
                          succes: true),
                      const SizedBox(height: 12),
                    ],
                    if (widget.reinitialise) ...[
                      const Bandeau(
                          'Mot de passe modifié. Connectez-vous avec le nouveau dans « Autres options », ou avec votre numéro.',
                          succes: true),
                      const SizedBox(height: 12),
                    ],
                    if (_erreur != null) ...[Bandeau(_erreur!), const SizedBox(height: 12)],
                    TextFormField(
                      key: const Key('telephone'),
                      controller: _telephone,
                      keyboardType: TextInputType.phone,
                      autofillHints: const [AutofillHints.telephoneNumberNational],
                      decoration: InputDecoration(
                        labelText: 'Numéro de téléphone',
                        hintText: '77 123 45 67',
                        prefixText: '+221 ',
                        prefixIcon: const Icon(Icons.phone_outlined),
                        helperText: 'Vous recevrez un code par SMS.',
                        errorText: _erreurTelephone,
                      ),
                      validator: (_) => numeroSenegalValide(_telephone.text)
                          ? null
                          : 'Numéro sénégalais à 9 chiffres, commençant par 7',
                      onFieldSubmitted: (_) => _continuer(),
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: _envoi ? null : _continuer,
                      child: _envoi
                          ? const SizedBox.square(dimension: 22, child: CircularProgressIndicator(strokeWidth: 2.5))
                          : const Text('Continuer'),
                    ),
                    const SeparateurOu(),
                    BoutonGoogle(surErreur: (m) => setState(() => _erreur = m)),
                    const SizedBox(height: 8),
                    ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                      leading: const Icon(Icons.mail_outline),
                      title: const Text('Autres options', style: TextStyle(fontWeight: FontWeight.w700)),
                      subtitle: const Text('E-mail et mot de passe'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => context.push('/autres-options'),
                    ),
                    const SizedBox(height: 8),
                    const Text('Nouveau numéro : votre compte est créé après le code.',
                        textAlign: TextAlign.center, style: TextStyle(color: Couleurs.texte2, fontSize: 13)),
                  ]),
                ),
              ),
            ),
          ),
        ),
      );
}
