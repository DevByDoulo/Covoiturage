import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/api.dart';
import '../../core/formats.dart';
import '../../core/google.dart';
import '../../core/session.dart';
import '../../core/theme.dart';
import '../../shared/widgets.dart';
import 'verification.dart';

/// Bouton « Continuer avec Google » des écrans de connexion et d'inscription.
/// [surErreur] reçoit le message à afficher (null pour effacer le précédent) ; une annulation n'affiche rien.
class BoutonGoogle extends StatefulWidget {
  const BoutonGoogle({super.key, required this.surErreur});

  final ValueChanged<String?> surErreur;

  @override
  State<BoutonGoogle> createState() => _BoutonGoogleState();
}

class _BoutonGoogleState extends State<BoutonGoogle> {
  bool _envoi = false;

  Future<void> _continuer() async {
    widget.surErreur(null);
    setState(() => _envoi = true);
    final issue = await continuerAvecGoogle(context.read<ServiceGoogle>(), context.read<Session>());
    if (!mounted) return;
    setState(() => _envoi = false);
    switch (issue) {
      case GoogleAnnule() || GoogleConnecte():
        break; // connecté : le routeur ouvre l'application
      case GoogleTelephoneRequis(:final idToken):
        context.push('/google/telephone', extra: idToken);
      case GoogleErreur(:final message):
        widget.surErreur(message);
    }
  }

  @override
  Widget build(BuildContext context) => OutlinedButton.icon(
        onPressed: _envoi ? null : _continuer,
        style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
        icon: _envoi
            ? const SizedBox.square(dimension: 20, child: CircularProgressIndicator(strokeWidth: 2.5))
            : const Text('G', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF4285F4))),
        label: const Text('Continuer avec Google'),
      );
}

/// Séparateur « ou » entre le formulaire et le bouton Google.
class SeparateurOu extends StatelessWidget {
  const SeparateurOu({super.key});

  @override
  Widget build(BuildContext context) => const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Row(children: [
          Expanded(child: Divider()),
          Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: Text('ou', style: TextStyle(color: Couleurs.texte2))),
          Expanded(child: Divider()),
        ]),
      );
}

/// Premier passage par Google : le numéro (vérifié par un code) est obligatoire sur YOBALEMAsn, comme sur le site.
class GoogleTelephonePage extends StatefulWidget {
  const GoogleTelephonePage({super.key, required this.idToken});

  final String idToken;

  @override
  State<GoogleTelephonePage> createState() => _GoogleTelephonePageState();
}

class _GoogleTelephonePageState extends State<GoogleTelephonePage> {
  final _formulaire = GlobalKey<FormState>();
  final _telephone = TextEditingController();
  String? _sexe;
  bool _envoi = false;
  String? _erreur;
  String? _erreurTelephone;

  @override
  void dispose() {
    _telephone.dispose();
    super.dispose();
  }

  Future<void> _envoyer() async {
    setState(() {
      _erreur = null;
      _erreurTelephone = null;
    });
    if (!_formulaire.currentState!.validate()) return;
    final numero = numeroSenegal(_telephone.text);
    setState(() => _envoi = true);
    try {
      final r = await context.read<Session>().connexionGoogle(widget.idToken, telephone: numero, sexe: _sexe);
      if (!mounted) return;
      if (!r.connecte) {
        context.push('/verification', extra: DemandeVerification(numero, r.canal ?? 'SMS', r.destination, r.renvoiDans));
      }
    } on ErreurApi catch (e) {
      setState(() {
        if (e.champ == 'telephone') {
          _erreurTelephone = e.message;
        } else {
          _erreur = e.status == 401 ? 'Votre connexion Google a expiré. Revenez en arrière et recommencez.' : e.message;
        }
      });
    } catch (e) {
      setState(() => _erreur = ErreurApi.messageDe(e));
    } finally {
      if (mounted) setState(() => _envoi = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Votre numéro')),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formulaire,
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                const Text('Encore une étape', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                const SizedBox(height: 6),
                const Text(
                  'Pour la sécurité des trajets, chaque compte est relié à un numéro de téléphone vérifié par un code.',
                  style: TextStyle(color: Couleurs.texte2),
                ),
                const SizedBox(height: 20),
                if (_erreur != null) ...[Bandeau(_erreur!), const SizedBox(height: 12)],
                TextFormField(
                  controller: _telephone,
                  keyboardType: TextInputType.phone,
                  autofillHints: const [AutofillHints.telephoneNumberNational],
                  decoration: InputDecoration(
                    labelText: 'Téléphone (77 123 45 67)',
                    prefixIcon: const Icon(Icons.phone_outlined),
                    errorText: _erreurTelephone,
                  ),
                  validator: (v) => numeroSenegalValide(v ?? '') ? null : 'Numéro sénégalais à 9 chiffres, commençant par 7',
                  onFieldSubmitted: (_) => _envoyer(),
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
                const SizedBox(height: 16),
                const Text('En continuant, vous acceptez les conditions d\'utilisation et la politique de confidentialité.',
                    style: TextStyle(color: Couleurs.texte2, fontSize: 13)),
                const LiensLegaux(),
                const SizedBox(height: 8),
                FilledButton(
                  onPressed: _envoi ? null : _envoyer,
                  child: _envoi
                      ? const SizedBox.square(dimension: 22, child: CircularProgressIndicator(strokeWidth: 2.5))
                      : const Text('Recevoir le code'),
                ),
              ]),
            ),
          ),
        ),
      );
}
