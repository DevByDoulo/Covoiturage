import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/api.dart';
import '../../core/formats.dart';
import '../../core/modeles.dart';
import '../../core/theme.dart';
import '../../shared/widgets.dart';

/// Nombre de messages non lus (pastille de l'icône Messages), rafraîchi toutes les 30 s pendant la session.
class CompteurMessages extends ChangeNotifier {
  CompteurMessages(this._api);

  final Api _api;
  Timer? _minuteur;
  int nonLus = 0;

  void suivre(bool actif) {
    _minuteur?.cancel();
    _minuteur = null;
    if (!actif) {
      nonLus = 0;
      notifyListeners();
      return;
    }
    compter();
    _minuteur = Timer.periodic(const Duration(seconds: 30), (_) => compter());
  }

  Future<void> compter() async {
    try {
      final r = await _api.get('/moi/conversations/non-lus') as Map<String, dynamic>;
      final n = (r['nombre'] as num).toInt();
      if (n != nonLus) {
        nonLus = n;
        notifyListeners();
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _minuteur?.cancel();
    super.dispose();
  }
}

/// Icône Messages des barres de titre, avec le nombre de messages non lus.
class BoutonMessages extends StatelessWidget {
  const BoutonMessages({super.key});

  @override
  Widget build(BuildContext context) {
    final n = context.watch<CompteurMessages>().nonLus;
    return IconButton(
      tooltip: 'Messages',
      onPressed: () => context.push('/messages'),
      icon: Badge(isLabelVisible: n > 0, label: Text('$n'), child: const Icon(Icons.chat_bubble_outline)),
    );
  }
}

/// Ouvre (ou crée) la conversation d'un trajet puis l'affiche. Le conducteur indique le passager.
Future<void> ecrire(BuildContext context, int idTrajet, {int? idPassager}) async {
  try {
    final r = await context.read<Api>().post(
        '/trajets/$idTrajet/conversation', idPassager == null ? null : {'idPassager': idPassager}) as Map<String, dynamic>;
    if (context.mounted) await context.push('/messages/${r['id']}');
  } catch (e) {
    if (context.mounted) afficherMessage(context, ErreurApi.messageDe(e), erreur: true);
  }
}

/// Bouton « Écrire à … » placé sur un trajet, une réservation ou un passager.
class BoutonEcrire extends StatelessWidget {
  const BoutonEcrire({super.key, required this.idTrajet, required this.prenom, this.idPassager});

  final int idTrajet;
  final String prenom;
  final int? idPassager;

  @override
  Widget build(BuildContext context) => TextButton.icon(
        onPressed: () => ecrire(context, idTrajet, idPassager: idPassager),
        icon: const Icon(Icons.chat_bubble_outline, size: 18),
        label: Text('Écrire à $prenom'),
      );
}

String _quand(DateTime d) {
  final maintenant = DateTime.now();
  if (d.year == maintenant.year && d.month == maintenant.month && d.day == maintenant.day) {
    return DateFormat("HH'h'mm", 'fr_FR').format(d);
  }
  return DateFormat('d MMM', 'fr_FR').format(d);
}

/// Liste des conversations, la plus récente en haut.
class MessagesPage extends StatefulWidget {
  const MessagesPage({super.key});

  @override
  State<MessagesPage> createState() => _MessagesPageState();
}

class _MessagesPageState extends State<MessagesPage> {
  List<ConversationResume>? _liste;
  String? _erreur;

  @override
  void initState() {
    super.initState();
    _charger();
  }

  Future<void> _charger() async {
    try {
      final brut = await context.read<Api>().get('/moi/conversations') as List;
      setState(() {
        _liste = brut.map((e) => ConversationResume.depuisJson(e as Map<String, dynamic>)).toList();
        _erreur = null;
      });
    } catch (e) {
      setState(() => _erreur = ErreurApi.messageDe(e));
    }
  }

  Future<void> _ouvrir(ConversationResume c) async {
    final compteur = context.read<CompteurMessages>();
    await context.push('/messages/${c.id}');
    compteur.compter();
    if (mounted) _charger();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(leading: retourAccueil(context), title: const Text('Messages'), actions: [
          IconButton(onPressed: _charger, icon: const Icon(Icons.refresh), tooltip: 'Actualiser'),
        ]),
        body: RefreshIndicator(onRefresh: _charger, child: _corps()),
      );

  Widget _corps() {
    final liste = _liste;
    if (liste == null) {
      return ListView(padding: const EdgeInsets.all(24), children: [
        if (_erreur != null) Bandeau(_erreur!) else const Center(child: CircularProgressIndicator()),
      ]);
    }
    if (liste.isEmpty) {
      return ListView(padding: const EdgeInsets.all(32), children: const [
        Icon(Icons.forum_outlined, size: 48, color: Couleurs.texte2),
        SizedBox(height: 8),
        Text(
          'Aucune conversation. Écrivez au conducteur depuis le détail d\'un trajet, ou à un passager depuis vos trajets.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Couleurs.texte2),
        ),
      ]);
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
      itemCount: liste.length,
      separatorBuilder: (_, _) => const SizedBox(height: 6),
      itemBuilder: (_, i) {
        final c = liste[i];
        final nom = '${c.interlocuteur.prenom} ${c.interlocuteur.nomInitiale}';
        final nonLu = c.nonLus > 0;
        return Card(
          color: nonLu ? Couleurs.vertClair : Colors.white,
          child: ListTile(
            onTap: () => _ouvrir(c),
            leading: Avatar(nom: nom, photo: c.interlocuteur.photoProfil),
            title: Row(children: [
              Expanded(
                child: Text(nom, style: TextStyle(fontWeight: nonLu ? FontWeight.w800 : FontWeight.w600)),
              ),
              if (c.dateDernierMessage != null)
                Text(_quand(c.dateDernierMessage!), style: const TextStyle(color: Couleurs.texte2, fontSize: 12)),
            ]),
            subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('${c.trajet.lieuDepart} → ${c.trajet.lieuArrivee} · ${dateCourte(c.trajet.dateHeureDepart)}',
                  maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12)),
              Text(
                c.dernierMessage == null ? 'Pas encore de message' : '${c.dernierDeMoi ? 'Vous : ' : ''}${c.dernierMessage}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: Couleurs.texte, fontWeight: nonLu ? FontWeight.w700 : FontWeight.w400),
              ),
            ]),
            trailing: nonLu ? Badge(label: Text('${c.nonLus}')) : null,
          ),
        );
      },
    );
  }
}

/// Une conversation : messages du plus ancien au plus récent, rafraîchis toutes les 5 s, et zone de saisie.
class ConversationPage extends StatefulWidget {
  const ConversationPage({super.key, required this.id});

  final int id;

  @override
  State<ConversationPage> createState() => _ConversationPageState();
}

class _ConversationPageState extends State<ConversationPage> {
  ConversationDetail? _conversation;
  String? _erreur;
  bool _envoi = false;
  Timer? _minuteur;
  final _texte = TextEditingController();
  final _defilement = ScrollController();

  @override
  void initState() {
    super.initState();
    _charger();
    _minuteur = Timer.periodic(const Duration(seconds: 5), (_) => _charger());
  }

  @override
  void dispose() {
    _minuteur?.cancel();
    _texte.dispose();
    _defilement.dispose();
    super.dispose();
  }

  Future<void> _charger() async {
    try {
      final c = ConversationDetail.depuisJson(
          await context.read<Api>().get('/moi/conversations/${widget.id}') as Map<String, dynamic>);
      if (!mounted) return;
      final nouveaux = c.messages.length != (_conversation?.messages.length ?? -1);
      setState(() {
        _conversation = c;
        _erreur = null;
      });
      if (nouveaux) _enBas();
    } catch (e) {
      if (mounted && _conversation == null) setState(() => _erreur = ErreurApi.messageDe(e));
    }
  }

  /// La liste est inversée : la position 0 est le message le plus récent.
  void _enBas() => WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_defilement.hasClients) {
          _defilement.animateTo(0, duration: const Duration(milliseconds: 200), curve: Curves.easeOut);
        }
      });

  Future<void> _envoyer() async {
    final contenu = _texte.text.trim();
    if (contenu.isEmpty || _envoi) return;
    setState(() => _envoi = true);
    try {
      await context.read<Api>().post('/moi/conversations/${widget.id}/messages', {'contenu': contenu});
      _texte.clear();
      await _charger();
    } catch (e) {
      if (mounted) afficherMessage(context, ErreurApi.messageDe(e), erreur: true);
    } finally {
      if (mounted) setState(() => _envoi = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = _conversation;
    return Scaffold(
      appBar: AppBar(
        leading: retourAccueil(context),
        titleSpacing: 0,
        title: c == null
            ? const Text('Conversation')
            : Row(children: [
                Avatar(nom: '${c.interlocuteur.prenom} ${c.interlocuteur.nomInitiale}', photo: c.interlocuteur.photoProfil, rayon: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('${c.interlocuteur.prenom} ${c.interlocuteur.nomInitiale}',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                    Text(
                      '${c.jeSuisConducteur ? 'Passager' : 'Conducteur'} · ${c.trajet.lieuDepart} → ${c.trajet.lieuArrivee}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12, color: Couleurs.texte2),
                    ),
                  ]),
                ),
              ]),
        actions: [
          if (c != null)
            IconButton(
              tooltip: 'Voir le trajet',
              icon: const Icon(Icons.route_outlined),
              onPressed: () => context.push(c.jeSuisConducteur ? '/conduite/${c.trajet.id}' : '/trajets/${c.trajet.id}'),
            ),
        ],
      ),
      body: c == null
          ? Center(child: _erreur != null ? Padding(padding: const EdgeInsets.all(24), child: Bandeau(_erreur!)) : const CircularProgressIndicator())
          : Column(children: [
              Expanded(child: _fil(c)),
              if (c.fermeture != null)
                Padding(padding: const EdgeInsets.all(12), child: Bandeau(c.fermeture!))
              else
                _saisie(c),
            ]),
    );
  }

  Widget _fil(ConversationDetail c) {
    if (c.messages.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            'Écrivez votre premier message à ${c.interlocuteur.prenom} : point de rendez-vous, bagages, retard…',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Couleurs.texte2),
          ),
        ),
      );
    }
    final messages = c.messages.reversed.toList();
    return ListView.builder(
      controller: _defilement,
      reverse: true,
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      itemCount: messages.length,
      itemBuilder: (_, i) => _bulle(messages[i]),
    );
  }

  Widget _bulle(MessageApp m) => Align(
        alignment: m.deMoi ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.78),
          margin: const EdgeInsets.symmetric(vertical: 3),
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
          decoration: BoxDecoration(
            color: m.deMoi ? Couleurs.vert : Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(16),
              topRight: const Radius.circular(16),
              bottomLeft: Radius.circular(m.deMoi ? 16 : 4),
              bottomRight: Radius.circular(m.deMoi ? 4 : 16),
            ),
            boxShadow: const [BoxShadow(color: Color(0x14000000), blurRadius: 3, offset: Offset(0, 1))],
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.end, mainAxisSize: MainAxisSize.min, children: [
            Align(
              alignment: Alignment.centerLeft,
              widthFactor: 1,
              child: Text(m.contenu, style: TextStyle(color: m.deMoi ? Colors.white : Couleurs.texte, fontSize: 15)),
            ),
            const SizedBox(height: 2),
            Text(
              '${_quand(m.dateEnvoi)}${m.deMoi && m.lu ? ' · lu' : ''}',
              style: TextStyle(color: m.deMoi ? Colors.white70 : Couleurs.texte2, fontSize: 11),
            ),
          ]),
        ),
      );

  Widget _saisie(ConversationDetail c) => SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
          color: Colors.white,
          child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Expanded(
              child: TextField(
                controller: _texte,
                minLines: 1,
                maxLines: 4,
                maxLength: 1000,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(hintText: 'Message à ${c.interlocuteur.prenom}', counterText: ''),
              ),
            ),
            const SizedBox(width: 6),
            ListenableBuilder(
              listenable: _texte,
              builder: (_, _) => IconButton.filled(
                tooltip: 'Envoyer',
                onPressed: _envoi || _texte.text.trim().isEmpty ? null : _envoyer,
                icon: _envoi
                    ? const SizedBox.square(dimension: 20, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                    : const Icon(Icons.send),
              ),
            ),
          ]),
        ),
      );
}
