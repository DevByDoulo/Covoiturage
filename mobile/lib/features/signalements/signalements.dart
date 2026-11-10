import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/api.dart';
import '../../core/modeles.dart';
import '../../core/theme.dart';
import '../../shared/widgets.dart';

/// 10 — Motifs de signalement, dans l'ordre d'affichage (mêmes valeurs que l'API).
const libellesMotifSignalement = <String, String>{
  'COMPORTEMENT': 'Comportement inapproprié',
  'CONDUITE_DANGEREUSE': 'Conduite dangereuse',
  'NON_PRESENTATION': 'Absence au rendez-vous',
  'ANNULATION_TARDIVE': 'Annulation de dernière minute',
  'FRAUDE_DOCUMENTS': 'Fausse identité ou faux documents',
  'HARCELEMENT': 'Harcèlement',
  'AUTRE': 'Autre',
};

const libellesStatutSignalement = <String, String>{
  'EN_ATTENTE': 'En attente',
  'EN_COURS': 'En cours d\'examen',
  'TRAITE': 'Traité',
  'REJETE': 'Classé sans suite',
};

/// Le motif « Autre » exige une description ; les autres la laissent facultative.
bool descriptionObligatoire(String? motif) => motif == 'AUTRE';

/// Signalement fait par l'utilisateur (`/api/signalements/mes`) : il ne voit que l'avancement.
class Signalement {
  Signalement({
    required this.id,
    required this.signale,
    required this.motif,
    this.description,
    required this.statut,
    this.trajet,
    required this.dateSignalement,
    this.dateTraitement,
  });

  final int id;
  final Personne signale;
  final String motif;
  final String? description;
  final String statut;
  final String? trajet;
  final DateTime dateSignalement;
  final DateTime? dateTraitement;

  bool get ouvert => statut == 'EN_ATTENTE' || statut == 'EN_COURS';

  factory Signalement.depuisJson(Map<String, dynamic> j) => Signalement(
        id: (j['id'] as num).toInt(),
        signale: Personne.depuisJson(j['signale'] as Map<String, dynamic>),
        motif: j['motif'] as String,
        description: j['description'] as String?,
        statut: j['statut'] as String,
        trajet: j['trajet'] as String?,
        dateSignalement: DateTime.parse(j['dateSignalement'] as String),
        dateTraitement: j['dateTraitement'] == null ? null : DateTime.parse(j['dateTraitement'] as String),
      );
}

/// Bouton « Signaler … » à poser près d'une personne rencontrée lors d'un trajet.
class BoutonSignaler extends StatelessWidget {
  const BoutonSignaler({super.key, required this.idUtilisateur, required this.prenom, this.idTrajet});

  final int idUtilisateur;
  final String prenom;
  final int? idTrajet;

  @override
  Widget build(BuildContext context) => TextButton.icon(
        onPressed: () => context.push(Uri(
          path: '/signaler/$idUtilisateur',
          queryParameters: {if (idTrajet != null) 'trajet': '$idTrajet', 'nom': prenom},
        ).toString()),
        icon: const Icon(Icons.flag_outlined, size: 18),
        label: Text('Signaler $prenom'),
        style: TextButton.styleFrom(foregroundColor: Couleurs.texte2),
      );
}

/// Formulaire de signalement : motif et description.
class SignalerPage extends StatefulWidget {
  const SignalerPage({super.key, required this.idUtilisateur, this.idTrajet, this.prenom});

  final int idUtilisateur;
  final int? idTrajet;
  final String? prenom;

  @override
  State<SignalerPage> createState() => _SignalerPageState();
}

class _SignalerPageState extends State<SignalerPage> {
  final _description = TextEditingController();
  String _motif = 'COMPORTEMENT';
  bool _envoi = false;
  bool _envoye = false;
  String? _erreur;

  @override
  void dispose() {
    _description.dispose();
    super.dispose();
  }

  Future<void> _envoyer() async {
    final texte = _description.text.trim();
    if (descriptionObligatoire(_motif) && texte.isEmpty) {
      setState(() => _erreur = 'Décrivez la situation.');
      return;
    }
    setState(() {
      _envoi = true;
      _erreur = null;
    });
    try {
      await context.read<Api>().post('/signalements', {
        'idUtilisateur': widget.idUtilisateur,
        if (widget.idTrajet != null) 'idTrajet': widget.idTrajet,
        'motif': _motif,
        if (texte.isNotEmpty) 'description': texte,
      });
      if (mounted) setState(() => _envoye = true);
    } catch (e) {
      if (mounted) setState(() => _erreur = ErreurApi.messageDe(e));
    } finally {
      if (mounted) setState(() => _envoi = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final nom = widget.prenom ?? 'cette personne';
    return Scaffold(
      appBar: AppBar(title: Text('Signaler $nom'), leading: retourAccueil(context)),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        if (_envoye) ...[
          const Bandeau(
            'Signalement envoyé. L\'équipe YOBALEMAsn va l\'examiner et vous informera de la suite. '
            'La personne signalée ne verra pas votre identité.',
            succes: true,
          ),
          const SizedBox(height: 16),
          FilledButton(onPressed: () => context.pushReplacement('/signalements'), child: const Text('Voir mes signalements')),
        ] else ...[
          const Text(
            'Un signalement est examiné par l\'équipe. Il ne concerne que les personnes avec qui vous avez partagé un trajet.',
            style: TextStyle(color: Couleurs.texte2),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue: _motif,
            decoration: const InputDecoration(labelText: 'Motif'),
            items: [
              for (final m in libellesMotifSignalement.entries) DropdownMenuItem(value: m.key, child: Text(m.value)),
            ],
            onChanged: (v) => setState(() => _motif = v ?? _motif),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _description,
            maxLines: 5,
            maxLength: 500,
            decoration: InputDecoration(
              labelText: descriptionObligatoire(_motif) ? 'Description (obligatoire)' : 'Description (facultatif)',
              hintText: 'Que s\'est-il passé ?',
              alignLabelWithHint: true,
            ),
          ),
          if (_erreur != null) ...[const SizedBox(height: 8), Bandeau(_erreur!)],
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _envoi ? null : _envoyer,
            child: Text(_envoi ? 'Envoi…' : 'Envoyer le signalement'),
          ),
        ],
      ]),
    );
  }
}

/// « Mes signalements » : ce que j'ai signalé et où en est le traitement.
class MesSignalementsPage extends StatefulWidget {
  const MesSignalementsPage({super.key});

  @override
  State<MesSignalementsPage> createState() => _MesSignalementsPageState();
}

class _MesSignalementsPageState extends State<MesSignalementsPage> {
  List<Signalement>? _liste;
  String? _erreur;

  @override
  void initState() {
    super.initState();
    _charger();
  }

  Future<void> _charger() async {
    try {
      final l = await context.read<Api>().get('/signalements/mes') as List;
      if (!mounted) return;
      setState(() {
        _liste = l.map((e) => Signalement.depuisJson(e as Map<String, dynamic>)).toList();
        _erreur = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _liste = const [];
        _erreur = ErreurApi.messageDe(e);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final liste = _liste;
    return Scaffold(
      appBar: AppBar(title: const Text('Mes signalements'), leading: retourAccueil(context)),
      body: liste == null
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _charger,
              child: ListView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 24), children: [
                if (_erreur != null) ...[Bandeau(_erreur!), const SizedBox(height: 12)],
                if (liste.isEmpty && _erreur == null)
                  const Padding(
                    padding: EdgeInsets.only(top: 24),
                    child: Text('Vous n\'avez fait aucun signalement.',
                        textAlign: TextAlign.center, style: TextStyle(color: Couleurs.texte2)),
                  ),
                for (final s in liste) _CarteSignalement(s),
              ]),
            ),
    );
  }
}

class _CarteSignalement extends StatelessWidget {
  const _CarteSignalement(this.s);

  final Signalement s;

  @override
  Widget build(BuildContext context) {
    final date = DateFormat('d MMM y', 'fr_FR');
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(
              child: Text('${s.signale.prenom} ${s.signale.nomInitiale}',
                  style: const TextStyle(fontWeight: FontWeight.w700)),
            ),
            Pastille(libellesStatutSignalement[s.statut] ?? s.statut,
                couleur: s.ouvert ? Couleurs.orange : Couleurs.vert),
          ]),
          const SizedBox(height: 4),
          Text('${libellesMotifSignalement[s.motif] ?? s.motif}${s.trajet == null ? '' : ' · ${s.trajet}'}'),
          if (s.description != null) ...[
            const SizedBox(height: 4),
            Text(s.description!, style: const TextStyle(color: Couleurs.texte2)),
          ],
          const SizedBox(height: 4),
          Text(
            'Envoyé le ${date.format(s.dateSignalement)}'
            '${s.dateTraitement == null ? '' : ' · examiné le ${date.format(s.dateTraitement!)}'}',
            style: const TextStyle(color: Couleurs.texte2, fontSize: 12),
          ),
        ]),
      ),
    );
  }
}
