import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/api.dart';
import '../../core/session.dart';
import '../../core/theme.dart';
import '../../shared/widgets.dart';

/// Mot de passe oublié, comme sur le site : 1) email ou téléphone où envoyer le code ; 2) code reçu, vérifié par
/// le serveur (5 essais) ; 3) nouveau mot de passe, autorisé par le jeton remis à l'étape 2.
class MotDePasseOubliePage extends StatefulWidget {
  const MotDePasseOubliePage({super.key});

  @override
  State<MotDePasseOubliePage> createState() => _MotDePasseOubliePageState();
}

class _MotDePasseOubliePageState extends State<MotDePasseOubliePage> {
  static final _regleMotDePasse = RegExp(r'^(?=.*[A-Za-z])(?=.*\d).{8,72}$');

  final _etape1 = GlobalKey<FormState>();
  final _etape3 = GlobalKey<FormState>();
  final _contact = TextEditingController();
  final _code = TextEditingController();
  final _motDePasse = TextEditingController();

  int _etape = 1;
  bool _envoi = false;
  bool _masque = true;
  String? _erreur;
  String? _info;
  String? _identifiant;
  String? _destination;
  String? _canal;
  String? _jeton;
  int _attente = 0;
  Timer? _minuteur;

  @override
  void dispose() {
    _minuteur?.cancel();
    _contact.dispose();
    _code.dispose();
    _motDePasse.dispose();
    super.dispose();
  }

  void _demarrerAttente(int secondes) {
    _minuteur?.cancel();
    setState(() => _attente = secondes);
    _minuteur = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_attente <= 1) t.cancel();
      if (mounted) setState(() => _attente = (_attente - 1).clamp(0, 999));
    });
  }

  /// Étape 1 (ou « Renvoyer » à l'étape 2) : envoie le code, puis affiche l'étape 2.
  Future<void> _envoyerCode() async {
    final renvoi = _etape == 2;
    if (!renvoi && !_etape1.currentState!.validate()) return;
    final identifiant = renvoi ? _identifiant! : _contact.text.trim();
    setState(() {
      _envoi = true;
      _erreur = null;
      _info = null;
    });
    try {
      final r = await context.read<Session>().demanderCodeReinitialisation(identifiant);
      if (!mounted) return;
      setState(() {
        _identifiant = identifiant;
        _destination = r.destination;
        _canal = r.canal;
        _etape = 2;
        if (renvoi) _info = 'Un nouveau code a été envoyé.';
      });
      _code.clear();
      _demarrerAttente(r.renvoiDans ?? 60);
    } catch (e) {
      if (mounted) setState(() => _erreur = ErreurApi.messageDe(e));
    } finally {
      if (mounted) setState(() => _envoi = false);
    }
  }

  /// Étape 2 : le serveur vérifie le code ; s'il est bon, on passe au nouveau mot de passe.
  Future<void> _verifierCode() async {
    final code = _code.text.trim();
    if (code.length != 6) {
      setState(() => _erreur = 'Saisissez les 6 chiffres du code.');
      return;
    }
    if (_envoi) return;
    setState(() {
      _envoi = true;
      _erreur = null;
      _info = null;
    });
    try {
      final jeton = await context.read<Session>().verifierCodeReinitialisation(_identifiant!, code);
      if (!mounted) return;
      _minuteur?.cancel();
      setState(() {
        _jeton = jeton;
        _etape = 3;
      });
    } on ErreurApi catch (e) {
      final reste = e.tentativesRestantes;
      _code.clear();
      if (mounted) {
        setState(() => _erreur = reste == null ? e.message : '${e.message} — il vous reste $reste tentative(s).');
      }
    } catch (e) {
      if (mounted) setState(() => _erreur = ErreurApi.messageDe(e));
    } finally {
      if (mounted) setState(() => _envoi = false);
    }
  }

  /// Étape 3 : enregistre le nouveau mot de passe, puis retour à la connexion.
  Future<void> _reinitialiser() async {
    if (!_etape3.currentState!.validate()) return;
    setState(() {
      _envoi = true;
      _erreur = null;
    });
    try {
      await context.read<Session>().reinitialiserMotDePasse(_jeton!, _motDePasse.text);
      if (mounted) context.go('/connexion?reinitialise=1');
    } catch (e) {
      if (mounted) setState(() => _erreur = ErreurApi.messageDe(e));
    } finally {
      if (mounted) setState(() => _envoi = false);
    }
  }

  /// Retour à l'étape 1 pour corriger l'email ou le téléphone (la saisie est conservée).
  void _recommencer() {
    _minuteur?.cancel();
    _code.clear();
    _motDePasse.clear();
    setState(() {
      _etape = 1;
      _identifiant = null;
      _jeton = null;
      _erreur = null;
      _info = null;
      _attente = 0;
    });
  }

  Widget get _chargement => const SizedBox.square(dimension: 22, child: CircularProgressIndicator(strokeWidth: 2.5));

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Mot de passe oublié')),
    body: SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_erreur != null) ...[Bandeau(_erreur!), const SizedBox(height: 12)],
                if (_info != null) ...[Bandeau(_info!, succes: true), const SizedBox(height: 12)],
                switch (_etape) {
                  1 => _vueContact(),
                  2 => _vueCode(),
                  _ => _vueNouveauMotDePasse(),
                },
              ],
            ),
          ),
        ),
      ),
    ),
  );

  Widget _vueContact() => Form(
    key: _etape1,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Icon(Icons.lock_reset, size: 56, color: Couleurs.vert),
        const SizedBox(height: 12),
        const Text(
          'Réinitialiser votre mot de passe',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 6),
        const Text(
          'Indiquez votre email ou votre numéro : nous vous envoyons un code.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Couleurs.texte2),
        ),
        const SizedBox(height: 24),
        TextFormField(
          controller: _contact,
          keyboardType: TextInputType.emailAddress,
          autofillHints: const [AutofillHints.username],
          decoration: const InputDecoration(labelText: 'Email ou téléphone', prefixIcon: Icon(Icons.person_outline)),
          validator: (v) => (v ?? '').trim().isEmpty ? 'Saisissez votre email ou votre numéro' : null,
          onFieldSubmitted: (_) => _envoyerCode(),
        ),
        const SizedBox(height: 20),
        FilledButton(
          onPressed: _envoi ? null : _envoyerCode,
          child: _envoi ? _chargement : const Text('Envoyer le code'),
        ),
      ],
    ),
  );

  Widget _vueCode() {
    final ou = _canal == 'EMAIL' ? 'par email' : 'par SMS';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Icon(Icons.mark_email_read_outlined, size: 56, color: Couleurs.vert),
        const SizedBox(height: 12),
        Text(
          'Saisissez le code reçu $ou',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
        ),
        if (_destination != null) ...[
          const SizedBox(height: 6),
          Text('Envoyé à $_destination', textAlign: TextAlign.center, style: const TextStyle(color: Couleurs.texte2)),
        ],
        const SizedBox(height: 24),
        TextField(
          controller: _code,
          autofocus: true,
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          maxLength: 6,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          style: const TextStyle(fontSize: 28, letterSpacing: 12, fontWeight: FontWeight.w800),
          decoration: const InputDecoration(counterText: '', hintText: '••••••'),
          onChanged: (v) {
            if (v.length == 6) _verifierCode();
          },
        ),
        const SizedBox(height: 16),
        FilledButton(onPressed: _envoi ? null : _verifierCode, child: _envoi ? _chargement : const Text('Vérifier')),
        const SizedBox(height: 8),
        TextButton(
          onPressed: _attente > 0 || _envoi ? null : _envoyerCode,
          child: Text(_attente > 0 ? 'Renvoyer le code dans $_attente s' : 'Renvoyer le code'),
        ),
        TextButton(onPressed: _recommencer, child: const Text("Modifier l'email ou le numéro")),
      ],
    );
  }

  Widget _vueNouveauMotDePasse() => Form(
    key: _etape3,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Icon(Icons.lock_outline, size: 56, color: Couleurs.vert),
        const SizedBox(height: 12),
        const Text(
          'Nouveau mot de passe',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 24),
        TextFormField(
          controller: _motDePasse,
          obscureText: _masque,
          autofocus: true,
          autofillHints: const [AutofillHints.newPassword],
          decoration: InputDecoration(
            labelText: 'Nouveau mot de passe',
            prefixIcon: const Icon(Icons.lock_outline),
            suffixIcon: IconButton(
              icon: Icon(_masque ? Icons.visibility_outlined : Icons.visibility_off_outlined),
              tooltip: _masque ? 'Afficher le mot de passe' : 'Masquer le mot de passe',
              onPressed: () => setState(() => _masque = !_masque),
            ),
          ),
          validator: (v) =>
              _regleMotDePasse.hasMatch(v ?? '') ? null : 'Au moins 8 caractères, dont une lettre et un chiffre',
        ),
        const SizedBox(height: 12),
        TextFormField(
          obscureText: _masque,
          decoration: const InputDecoration(
            labelText: 'Confirmer le mot de passe',
            prefixIcon: Icon(Icons.lock_outline),
          ),
          validator: (v) => v == _motDePasse.text ? null : 'Les deux mots de passe ne correspondent pas',
          onFieldSubmitted: (_) => _reinitialiser(),
        ),
        const SizedBox(height: 20),
        FilledButton(
          onPressed: _envoi ? null : _reinitialiser,
          child: _envoi ? _chargement : const Text('Enregistrer le mot de passe'),
        ),
      ],
    ),
  );
}
