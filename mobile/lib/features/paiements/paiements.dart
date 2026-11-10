import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/api.dart';
import '../../core/formats.dart';
import '../../core/modeles.dart';
import '../../core/theme.dart';
import '../../shared/widgets.dart';

/// 04 — Ligne de l'historique (`/api/moi/paiements`) : role = PASSAGER (j'ai payé) ou CONDUCTEUR (j'ai encaissé).
class LignePaiement {
  LignePaiement({
    required this.referenceTransaction,
    required this.role,
    required this.trajet,
    required this.dateHeureDepart,
    required this.contrepartie,
    required this.montant,
    required this.moyen,
    required this.statut,
  });

  final String referenceTransaction;
  final String role;
  final String trajet;
  final DateTime dateHeureDepart;
  final String contrepartie;
  final double montant;
  final String moyen;
  final String statut;

  bool get encaissement => role == 'CONDUCTEUR';

  /// Un reçu n'existe que pour un paiement abouti (éventuellement remboursé depuis).
  bool get recuDisponible => statut == 'REUSSI' || statut == 'REMBOURSE';

  factory LignePaiement.depuisJson(Map<String, dynamic> j) => LignePaiement(
        referenceTransaction: j['referenceTransaction'] as String,
        role: j['role'] as String,
        trajet: j['trajet'] as String,
        dateHeureDepart: DateTime.parse(j['dateHeureDepart'] as String),
        contrepartie: j['contrepartie'] as String,
        montant: (j['montant'] as num).toDouble(),
        moyen: j['moyen'] as String,
        statut: j['statut'] as String,
      );
}

/// Total encaissé comme conducteur (paiements réussis seulement), comme sur le site.
double totalEncaisse(List<LignePaiement> lignes) =>
    lignes.where((l) => l.encaissement && l.statut == 'REUSSI').fold(0, (t, l) => t + l.montant);

/// 04 — Reçu d'un paiement (`/api/paiements/{reference}/recu`).
class Recu {
  Recu({
    required this.referenceTransaction,
    this.referenceOperateur,
    this.dateConfirmation,
    required this.passager,
    required this.conducteur,
    required this.trajet,
    required this.dateHeureDepart,
    required this.nombrePlaces,
    required this.prixUnitaire,
    required this.montant,
    required this.commission,
    required this.moyen,
    required this.statut,
    this.dateRemboursement,
  });

  final String referenceTransaction;
  final String? referenceOperateur;
  final DateTime? dateConfirmation;
  final String passager;
  final String conducteur;
  final String trajet;
  final DateTime dateHeureDepart;
  final int nombrePlaces;
  final double prixUnitaire;
  final double montant;
  final double commission;
  final String moyen;
  final String statut;
  final DateTime? dateRemboursement;

  static DateTime? _date(Object? v) => v == null ? null : DateTime.parse(v as String);

  factory Recu.depuisJson(Map<String, dynamic> j) => Recu(
        referenceTransaction: j['referenceTransaction'] as String,
        referenceOperateur: j['referenceOperateur'] as String?,
        dateConfirmation: _date(j['dateConfirmation']),
        passager: j['passager'] as String,
        conducteur: j['conducteur'] as String,
        trajet: j['trajet'] as String,
        dateHeureDepart: DateTime.parse(j['dateHeureDepart'] as String),
        nombrePlaces: (j['nombrePlaces'] as num).toInt(),
        prixUnitaire: (j['prixUnitaire'] as num).toDouble(),
        montant: (j['montant'] as num).toDouble(),
        commission: (j['commission'] as num?)?.toDouble() ?? 0,
        moyen: j['moyen'] as String,
        statut: j['statut'] as String,
        dateRemboursement: _date(j['dateRemboursement']),
      );

  /// Lignes « intitulé : valeur » du reçu, partagées par l'écran et le texte copié.
  List<(String, String)> get lignes => [
        if (dateConfirmation != null) ('Date du paiement', _dateLongue(dateConfirmation!)),
        ('Trajet', '$trajet, le ${_dateLongue(dateHeureDepart)}'),
        ('Passager', passager),
        ('Conducteur', conducteur),
        ('Places', '$nombrePlaces × ${fcfa(prixUnitaire)}'),
        (
          'Moyen de paiement',
          '${libellesMoyen[moyen] ?? moyen}${referenceOperateur != null ? ' (réf. $referenceOperateur)' : ''}'
        ),
        ('Commission YOBALEMAsn', fcfa(commission)),
        ('Montant payé', fcfa(montant)),
        ('Statut', libellesStatutPaiement[statut] ?? statut),
      ];

  /// Texte brut du reçu (copié dans le presse-papiers pour l'envoyer par message ou l'archiver).
  String enTexte() => [
        'YOBALEMAsn — Reçu de paiement',
        'N° $referenceTransaction',
        if (statut == 'REMBOURSE' && dateRemboursement != null)
          'Remboursé intégralement le ${_dateLongue(dateRemboursement!)}',
        for (final (intitule, valeur) in lignes) '$intitule : $valeur',
        _mention,
      ].join('\n');
}

const _mention = 'Covoiturage entre particuliers : le montant correspond au partage des frais du trajet.';

String _dateLongue(DateTime d) => DateFormat("d MMMM y 'à' HH:mm", 'fr_FR').format(d);

/// Historique : paiements effectués (passager) et encaissements (conducteur), avec accès aux reçus.
class MesPaiementsPage extends StatefulWidget {
  const MesPaiementsPage({super.key});

  @override
  State<MesPaiementsPage> createState() => _MesPaiementsPageState();
}

class _MesPaiementsPageState extends State<MesPaiementsPage> {
  List<LignePaiement>? _lignes;
  String? _erreur;

  @override
  void initState() {
    super.initState();
    _charger();
  }

  Future<void> _charger() async {
    try {
      final l = await context.read<Api>().get('/moi/paiements') as List;
      if (!mounted) return;
      setState(() {
        _lignes = l.map((e) => LignePaiement.depuisJson(e as Map<String, dynamic>)).toList();
        _erreur = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _lignes = const [];
        _erreur = ErreurApi.messageDe(e);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final lignes = _lignes;
    return Scaffold(
      appBar: AppBar(title: const Text('Mes paiements'), leading: retourAccueil(context)),
      body: lignes == null
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _charger,
              child: ListView(padding: const EdgeInsets.fromLTRB(16, 0, 16, 24), children: [
                if (_erreur != null) ...[Bandeau(_erreur!), const SizedBox(height: 12)],
                if (totalEncaisse(lignes) > 0) ...[
                  Text.rich(TextSpan(children: [
                    const TextSpan(text: 'Encaissé comme conducteur : '),
                    TextSpan(text: fcfa(totalEncaisse(lignes)), style: const TextStyle(fontWeight: FontWeight.w800)),
                  ])),
                  const SizedBox(height: 12),
                ],
                if (lignes.isEmpty && _erreur == null)
                  const Padding(
                    padding: EdgeInsets.only(top: 24),
                    child: Text('Aucun paiement pour l\'instant.',
                        textAlign: TextAlign.center, style: TextStyle(color: Couleurs.texte2)),
                  ),
                for (final l in lignes) _CartePaiement(l),
              ]),
            ),
    );
  }
}

class _CartePaiement extends StatelessWidget {
  const _CartePaiement(this.l);

  final LignePaiement l;

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(l.trajet, style: const TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(
                  '${DateFormat('d MMM y, HH:mm', 'fr_FR').format(l.dateHeureDepart)} · '
                  '${l.encaissement ? 'Passager' : 'Conducteur'} : ${l.contrepartie}',
                  style: const TextStyle(color: Couleurs.texte2, fontSize: 12),
                ),
                Text(
                  '${libellesMoyen[l.moyen] ?? l.moyen} · ${libellesStatutPaiement[l.statut] ?? l.statut} · '
                  'réf. ${l.referenceTransaction}',
                  style: const TextStyle(color: Couleurs.texte2, fontSize: 12),
                ),
              ]),
            ),
            const SizedBox(width: 12),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text(
                '${l.encaissement ? '+' : '−'} ${fcfa(l.montant)}',
                style: TextStyle(fontWeight: FontWeight.w800, color: l.encaissement ? Couleurs.vert : Couleurs.texte),
              ),
              if (l.recuDisponible)
                TextButton(
                  style: TextButton.styleFrom(minimumSize: const Size(0, 36), padding: EdgeInsets.zero),
                  onPressed: () => context.push('/paiements/${Uri.encodeComponent(l.referenceTransaction)}/recu'),
                  child: const Text('Reçu'),
                ),
            ]),
          ]),
        ),
      );
}

/// Reçu d'un paiement, avec copie du texte (à coller dans un message ou une note).
class RecuPage extends StatefulWidget {
  const RecuPage({super.key, required this.reference});

  final String reference;

  @override
  State<RecuPage> createState() => _RecuPageState();
}

class _RecuPageState extends State<RecuPage> {
  Recu? _recu;
  String? _erreur;

  @override
  void initState() {
    super.initState();
    _charger();
  }

  Future<void> _charger() async {
    try {
      final r = await context.read<Api>().get('/paiements/${Uri.encodeComponent(widget.reference)}/recu');
      if (mounted) setState(() => _recu = Recu.depuisJson(r as Map<String, dynamic>));
    } catch (e) {
      if (mounted) setState(() => _erreur = ErreurApi.messageDe(e));
    }
  }

  Future<void> _copier(Recu r) async {
    await Clipboard.setData(ClipboardData(text: r.enTexte()));
    if (mounted) afficherMessage(context, 'Reçu copié');
  }

  @override
  Widget build(BuildContext context) {
    final r = _recu;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reçu'),
        leading: context.canPop()
            ? null
            : IconButton(
                tooltip: 'Mes paiements',
                icon: const Icon(Icons.arrow_back),
                onPressed: () => context.go('/paiements'),
              ),
      ),
      body: _erreur != null
          ? Padding(padding: const EdgeInsets.all(16), child: Bandeau(_erreur!))
          : r == null
              ? const Center(child: CircularProgressIndicator())
              : ListView(padding: const EdgeInsets.fromLTRB(16, 0, 16, 24), children: [
                  Bloc(children: [
                    Row(children: [
                      const Logo(taille: 20),
                      const Spacer(),
                      Flexible(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                          const Text('Reçu de paiement', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
                          Text('N° ${r.referenceTransaction}',
                              textAlign: TextAlign.end, style: const TextStyle(color: Couleurs.texte2, fontSize: 12)),
                        ]),
                      ),
                    ]),
                    const SizedBox(height: 16),
                    if (r.statut == 'REMBOURSE' && r.dateRemboursement != null) ...[
                      Bandeau('Remboursé intégralement le ${_dateLongue(r.dateRemboursement!)}', succes: true),
                      const SizedBox(height: 12),
                    ],
                    for (final (intitule, valeur) in r.lignes) _ligne(intitule, valeur, total: intitule == 'Montant payé'),
                    const SizedBox(height: 12),
                    const Text(_mention, style: TextStyle(color: Couleurs.texte2, fontSize: 12)),
                  ]),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: () => _copier(r),
                    icon: const Icon(Icons.copy),
                    label: const Text('Copier le reçu'),
                  ),
                ]),
    );
  }

  Widget _ligne(String intitule, String valeur, {bool total = false}) {
    final style = total ? const TextStyle(fontSize: 17, fontWeight: FontWeight.w800) : null;
    return Container(
      padding: EdgeInsets.only(top: total ? 10 : 4, bottom: 4),
      margin: EdgeInsets.only(top: total ? 6 : 0),
      decoration: total ? const BoxDecoration(border: Border(top: BorderSide(color: Color(0xFFE5E7EB)))) : null,
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(child: Text(intitule, style: style ?? const TextStyle(color: Couleurs.texte2))),
        const SizedBox(width: 12),
        Expanded(child: Text(valeur, textAlign: TextAlign.end, style: style)),
      ]),
    );
  }
}
