import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/api.dart';
import '../../core/session.dart';
import '../../core/theme.dart';
import '../../shared/widgets.dart';

/// Où le code a été envoyé, pour l'écran de vérification.
class DemandeVerification {
  DemandeVerification(this.identifiant, this.canal, this.destination, this.renvoiDans);

  /// Numéro de téléphone (ou email) du compte à vérifier.
  final String identifiant;

  /// EMAIL ou SMS.
  final String canal;
  final String? destination;
  final int? renvoiDans;
}

/// Saisie du code à 6 chiffres reçu par email ou SMS. Une fois vérifié, l'utilisateur est connecté.
class VerificationPage extends StatefulWidget {
  const VerificationPage({super.key, required this.demande});

  final DemandeVerification demande;

  @override
  State<VerificationPage> createState() => _VerificationPageState();
}

class _VerificationPageState extends State<VerificationPage> {
  final _code = TextEditingController();
  bool _envoi = false;
  String? _erreur;
  String? _info;
  int _attente = 0;
  Timer? _minuteur;

  @override
  void initState() {
    super.initState();
    _demarrerAttente(widget.demande.renvoiDans ?? 60);
  }

  @override
  void dispose() {
    _minuteur?.cancel();
    _code.dispose();
    super.dispose();
  }

  void _demarrerAttente(int secondes) {
    _minuteur?.cancel();
    setState(() => _attente = secondes);
    _minuteur = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_attente <= 1) t.cancel();
      setState(() => _attente = (_attente - 1).clamp(0, 999));
    });
  }

  Future<void> _verifier() async {
    final code = _code.text.trim();
    if (code.length != 6) {
      setState(() => _erreur = 'Saisissez les 6 chiffres du code.');
      return;
    }
    setState(() {
      _envoi = true;
      _erreur = null;
    });
    try {
      // Connecté : le routeur ouvre l'application.
      await context.read<Session>().verifierCode(widget.demande.identifiant, code);
    } on ErreurApi catch (e) {
      final reste = e.tentativesRestantes;
      setState(() => _erreur = reste == null ? e.message : '${e.message} — il vous reste $reste tentative(s).');
    } catch (e) {
      setState(() => _erreur = ErreurApi.messageDe(e));
    } finally {
      if (mounted) setState(() => _envoi = false);
    }
  }

  Future<void> _renvoyer() async {
    setState(() {
      _erreur = null;
      _info = null;
    });
    try {
      final r = await context.read<Session>().renvoyerCode(widget.demande.identifiant);
      setState(() => _info = 'Un nouveau code a été envoyé.');
      _demarrerAttente(r.renvoiDans ?? 60);
    } catch (e) {
      setState(() => _erreur = ErreurApi.messageDe(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.demande;
    final ou = d.canal == 'EMAIL' ? 'par email' : 'par SMS';
    return Scaffold(
      appBar: AppBar(title: const Text('Vérification')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            const Icon(Icons.mark_email_read_outlined, size: 56, color: Couleurs.vert),
            const SizedBox(height: 12),
            Text('Saisissez le code reçu $ou', textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
            if (d.destination != null) ...[
              const SizedBox(height: 6),
              Text('Envoyé à ${d.destination}', textAlign: TextAlign.center, style: const TextStyle(color: Couleurs.texte2)),
            ],
            const SizedBox(height: 24),
            if (_erreur != null) ...[Bandeau(_erreur!), const SizedBox(height: 12)],
            if (_info != null) ...[Bandeau(_info!, succes: true), const SizedBox(height: 12)],
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
                if (v.length == 6) _verifier();
              },
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _envoi ? null : _verifier,
              child: _envoi
                  ? const SizedBox.square(dimension: 22, child: CircularProgressIndicator(strokeWidth: 2.5))
                  : const Text('Vérifier'),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: _attente > 0 ? null : _renvoyer,
              child: Text(_attente > 0 ? 'Renvoyer le code dans $_attente s' : 'Renvoyer le code'),
            ),
          ]),
        ),
      ),
    );
  }
}
