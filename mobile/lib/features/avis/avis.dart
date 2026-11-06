import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api.dart';
import '../../core/formats.dart';
import '../../core/modeles.dart';
import '../../core/theme.dart';
import '../../shared/widgets.dart';

int _i(Object? v) => (v as num?)?.toInt() ?? 0;

/// Voyage terminé à noter (GET /api/moi/avis-a-donner), avant [dateLimite].
class AvisADonner {
  AvisADonner(this.idReservation, this.trajet, this.dateHeureDepart, this.aNoter, this.role, this.dateLimite);

  final int idReservation;
  final String trajet;
  final DateTime dateHeureDepart;
  final Personne aNoter;

  /// Rôle de la personne à noter : CONDUCTEUR ou PASSAGER.
  final String role;
  final DateTime dateLimite;

  factory AvisADonner.depuisJson(Map<String, dynamic> j) => AvisADonner(
        _i(j['idReservation']),
        j['trajet'] as String,
        DateTime.parse(j['dateHeureDepart'] as String),
        Personne.depuisJson(j['aNoter'] as Map<String, dynamic>),
        j['role'] as String,
        DateTime.parse(j['dateLimite'] as String),
      );
}

class Avis {
  Avis(this.note, this.commentaire, this.date, this.auteur, this.roleEvalue, this.trajet);

  final int note;
  final String? commentaire;
  final DateTime date;
  final Personne auteur;
  final String roleEvalue;
  final String? trajet;

  factory Avis.depuisJson(Map<String, dynamic> j) => Avis(
        _i(j['note']),
        j['commentaire'] as String?,
        DateTime.parse(j['dateEvaluation'] as String),
        Personne.depuisJson(j['auteur'] as Map<String, dynamic>),
        j['roleEvalue'] as String,
        j['trajet'] as String?,
      );
}

/// Réputation publique (GET /api/utilisateurs/{id}/avis) ; [repartition][0] = avis à 1 étoile… [4] = 5 étoiles.
class Reputation {
  Reputation(this.noteMoyenne, this.nombreAvis, this.repartition, this.avis);

  final double? noteMoyenne;
  final int nombreAvis;
  final List<int> repartition;
  final List<Avis> avis;

  factory Reputation.depuisJson(Map<String, dynamic> j) => Reputation(
        (j['noteMoyenne'] as num?)?.toDouble(),
        _i(j['nombreAvis']),
        ((j['repartition'] as List?) ?? const []).map(_i).toList(),
        ((j['avis'] as List?) ?? const []).map((e) => Avis.depuisJson(e as Map<String, dynamic>)).toList(),
      );
}

String noteTexte(double n) => n.toStringAsFixed(1).replaceAll('.', ',');

/// Étoiles en lecture ([note] de 0 à 5, demi-étoiles arrondies).
class Etoiles extends StatelessWidget {
  const Etoiles(this.note, {super.key, this.taille = 16});

  final double note;
  final double taille;

  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [
        for (var i = 1; i <= 5; i++)
          Icon(
            note >= i ? Icons.star : (note >= i - 0.5 ? Icons.star_half : Icons.star_border),
            size: taille,
            color: Couleurs.orange,
          ),
      ]);
}

/// « Donnez votre avis » : voyages terminés à noter. Ne s'affiche que s'il y en a.
/// L'écran parent le recharge en changeant sa clé (ex. après « Actualiser »).
class BlocAvisADonner extends StatefulWidget {
  const BlocAvisADonner({super.key});

  @override
  State<BlocAvisADonner> createState() => _BlocAvisADonnerState();
}

class _BlocAvisADonnerState extends State<BlocAvisADonner> {
  List<AvisADonner> _liste = const [];

  @override
  void initState() {
    super.initState();
    _charger();
  }

  Future<void> _charger() async {
    try {
      final brut = await context.read<Api>().get('/moi/avis-a-donner') as List;
      if (mounted) {
        setState(() => _liste = brut.map((e) => AvisADonner.depuisJson(e as Map<String, dynamic>)).toList());
      }
    } catch (_) {
      // Bloc facultatif : en cas d'erreur, on ne l'affiche pas.
    }
  }

  Future<void> _noter(AvisADonner a) async {
    final envoye = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _FeuilleNote(avis: a),
    );
    if (envoye == true) {
      if (mounted) afficherMessage(context, 'Merci pour votre avis !');
      await _charger();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_liste.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Bloc(titre: 'Donnez votre avis', icone: Icons.star_outline, children: [
        for (final a in _liste)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Avatar(nom: '${a.aNoter.prenom} ${a.aNoter.nomInitiale}', photo: a.aNoter.photoProfil),
            title: Text('${a.aNoter.prenom} ${a.aNoter.nomInitiale}', style: const TextStyle(fontWeight: FontWeight.w700)),
            subtitle: Text('${a.trajet} · ${dateCourte(a.dateHeureDepart)}', maxLines: 2, overflow: TextOverflow.ellipsis),
            trailing: FilledButton(
              style: FilledButton.styleFrom(minimumSize: const Size(0, 38)),
              onPressed: () => _noter(a),
              child: const Text('Noter'),
            ),
          ),
      ]),
    );
  }
}

/// Note de 1 à 5 étoiles et commentaire facultatif, envoyés à POST /api/reservations/{id}/evaluation.
class _FeuilleNote extends StatefulWidget {
  const _FeuilleNote({required this.avis});

  final AvisADonner avis;

  @override
  State<_FeuilleNote> createState() => _FeuilleNoteState();
}

class _FeuilleNoteState extends State<_FeuilleNote> {
  int _note = 0;
  final _commentaire = TextEditingController();
  bool _envoi = false;
  String? _erreur;

  static const _libelles = ['', 'Très décevant', 'Décevant', 'Correct', 'Bien', 'Excellent'];

  @override
  void dispose() {
    _commentaire.dispose();
    super.dispose();
  }

  Future<void> _envoyer() async {
    setState(() {
      _envoi = true;
      _erreur = null;
    });
    try {
      final commentaire = _commentaire.text.trim();
      await context.read<Api>().post('/reservations/${widget.avis.idReservation}/evaluation', {
        'note': _note,
        'commentaire': commentaire.isEmpty ? null : commentaire,
      });
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      setState(() {
        _erreur = ErreurApi.messageDe(e);
        _envoi = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final a = widget.avis;
    return Padding(
      padding: EdgeInsets.fromLTRB(24, 0, 24, 24 + MediaQuery.viewInsetsOf(context).bottom),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text(
          a.role == 'CONDUCTEUR' ? 'Comment s\'est passé le trajet avec ${a.aNoter.prenom} ?' : 'Notez votre passager ${a.aNoter.prenom}',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 4),
        Text(a.trajet, textAlign: TextAlign.center, style: const TextStyle(color: Couleurs.texte2)),
        const SizedBox(height: 12),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          for (var i = 1; i <= 5; i++)
            IconButton(
              tooltip: '$i étoile${i > 1 ? 's' : ''}',
              iconSize: 40,
              onPressed: _envoi ? null : () => setState(() => _note = i),
              icon: Icon(_note >= i ? Icons.star : Icons.star_border, color: Couleurs.orange),
            ),
        ]),
        Text(_libelles[_note], textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        TextField(
          controller: _commentaire,
          maxLength: 500,
          minLines: 2,
          maxLines: 4,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(labelText: 'Commentaire (facultatif)'),
        ),
        if (_erreur != null) ...[const SizedBox(height: 8), Bandeau(_erreur!)],
        const SizedBox(height: 12),
        FilledButton(
          onPressed: _note == 0 || _envoi ? null : _envoyer,
          child: _envoi
              ? const SizedBox.square(dimension: 22, child: CircularProgressIndicator(strokeWidth: 2.5))
              : const Text('Publier mon avis'),
        ),
        const SizedBox(height: 4),
        Text('À donner avant le ${dateCourte(a.dateLimite)}.',
            textAlign: TextAlign.center, style: const TextStyle(color: Couleurs.texte2, fontSize: 12)),
      ]),
    );
  }
}

/// Réputation d'une personne : moyenne, nombre d'avis, répartition et derniers avis.
class BlocReputation extends StatefulWidget {
  const BlocReputation({super.key, required this.idUtilisateur, required this.titre});

  final int idUtilisateur;
  final String titre;

  @override
  State<BlocReputation> createState() => _BlocReputationState();
}

class _BlocReputationState extends State<BlocReputation> {
  Reputation? _reputation;
  bool _tout = false;

  @override
  void initState() {
    super.initState();
    _charger();
  }

  Future<void> _charger() async {
    try {
      final r = Reputation.depuisJson(
          await context.read<Api>().get('/utilisateurs/${widget.idUtilisateur}/avis') as Map<String, dynamic>);
      if (mounted) setState(() => _reputation = r);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final r = _reputation;
    if (r == null) return const SizedBox.shrink();
    final visibles = _tout ? r.avis : r.avis.take(3).toList();
    return Bloc(titre: widget.titre, icone: Icons.star_outline, children: [
      if (r.nombreAvis == 0 || r.noteMoyenne == null)
        const Text('Pas encore d\'avis.', style: TextStyle(color: Couleurs.texte2))
      else ...[
        Row(children: [
          Text(noteTexte(r.noteMoyenne!), style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900)),
          const SizedBox(width: 10),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Etoiles(r.noteMoyenne!, taille: 18),
            Text('${r.nombreAvis} avis', style: const TextStyle(color: Couleurs.texte2)),
          ]),
          const SizedBox(width: 16),
          Expanded(child: _repartition(r)),
        ]),
        const Divider(height: 24),
        for (final a in visibles) _avis(a),
        if (r.avis.length > 3)
          TextButton(
            onPressed: () => setState(() => _tout = !_tout),
            child: Text(_tout ? 'Voir moins' : 'Voir les ${r.avis.length} avis'),
          ),
      ],
    ]);
  }

  Widget _repartition(Reputation r) {
    final max = r.repartition.fold<int>(0, (m, n) => n > m ? n : m);
    return Column(children: [
      for (var etoiles = 5; etoiles >= 1; etoiles--)
        Row(children: [
          SizedBox(width: 14, child: Text('$etoiles', style: const TextStyle(fontSize: 11, color: Couleurs.texte2))),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: max == 0 || r.repartition.length < etoiles ? 0 : r.repartition[etoiles - 1] / max,
                minHeight: 5,
                color: Couleurs.orange,
                backgroundColor: Couleurs.vertClair,
              ),
            ),
          ),
        ]),
    ]);
  }

  Widget _avis(Avis a) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Etoiles(a.note.toDouble(), taille: 14),
            const SizedBox(width: 8),
            Expanded(
              child: Text('${a.auteur.prenom} ${a.auteur.nomInitiale} · ${dateCourte(a.date).split(' ').first}',
                  style: const TextStyle(color: Couleurs.texte2, fontSize: 12)),
            ),
          ]),
          if (a.commentaire != null && a.commentaire!.isNotEmpty)
            Padding(padding: const EdgeInsets.only(top: 4), child: Text(a.commentaire!)),
          if (a.trajet != null)
            Text(a.trajet!, style: const TextStyle(color: Couleurs.texte2, fontSize: 12)),
        ]),
      );
}
