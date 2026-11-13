import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'core/api.dart';
import 'core/google.dart';
import 'core/localisation.dart';
import 'core/push.dart';
import 'core/session.dart';
import 'core/voix.dart';
import 'core/theme.dart';
import 'features/alertes/alertes.dart';
import 'features/messages/messages.dart';
import 'features/notifications/notifications.dart';
import 'features/suivi/partage.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('fr_FR');
  final api = Api();
  final session = Session(api);
  final compteur = CompteurNotifications(api);
  final messages = CompteurMessages(api);
  final positions = PositionActuelle();
  final push = ServicePush(api);
  session.avantDeconnexion = push.desactiver;
  session.restaurer();
  // Firebase (notifications push) ; sans google-services.json, le push est simplement désactivé.
  await push.demarrer();
  runApp(
    MultiProvider(
      providers: [
        Provider.value(value: api),
        Provider.value(value: push),
        Provider<ServiceGoogle>(create: (_) => ServiceGooglePlugin(ConfigGoogle.environnement)),
        ChangeNotifierProvider.value(value: session),
        ChangeNotifierProvider.value(value: compteur),
        ChangeNotifierProvider.value(value: messages),
        ChangeNotifierProvider(create: (_) => AlertesService(api)),
        Provider(create: (_) => Geocodage()),
        Provider.value(value: positions),
        ChangeNotifierProvider(create: (_) => Voix()),
        // Partage de position du conducteur : global, il continue d'un écran à l'autre.
        ChangeNotifierProvider(create: (_) => PartagePosition(api, positions)),
      ],
      child: YobalemaApp(session: session, compteur: compteur, messages: messages, push: push),
    ),
  );
}

class YobalemaApp extends StatefulWidget {
  const YobalemaApp(
      {super.key, required this.session, required this.compteur, required this.messages, required this.push});

  final Session session;
  final CompteurNotifications compteur;
  final CompteurMessages messages;
  final ServicePush push;

  @override
  State<YobalemaApp> createState() => _YobalemaAppState();
}

class _YobalemaAppState extends State<YobalemaApp> {
  late final routeur = creerRouteur(widget.session);
  final _messagerie = GlobalKey<ScaffoldMessengerState>();
  bool _connecte = false;

  @override
  void initState() {
    super.initState();
    widget.push
      ..surOuverture = _ouvrirPush
      ..surPremierPlan = _afficherPush;
    // Les compteurs (cloche, messages) et le push ne tournent que si quelqu'un est connecté.
    widget.session.addListener(_suivreSession);
  }

  void _suivreSession() {
    final connecte = widget.session.connecte;
    widget.compteur.suivre(connecte);
    widget.messages.suivre(connecte);
    if (connecte == _connecte) return;
    _connecte = connecte;
    if (connecte) {
      widget.push.activer();
      // Application lancée en touchant une notification : son écran, une fois la session restaurée.
      final initial = widget.push.prendreMessageInitial();
      if (initial != null) WidgetsBinding.instance.addPostFrameCallback((_) => _ouvrirPush(initial));
    } else {
      widget.push.oublier();
    }
  }

  void _ouvrirPush(MessagePush m) {
    if (!widget.session.connecte) return;
    widget.compteur.compter();
    final destination = destinationPour(m.lien);
    if (destination.empiler) {
      routeur.push(destination.chemin);
    } else {
      routeur.go(destination.chemin);
    }
  }

  /// Application à l'écran : le système n'affiche pas la notification, on la montre en bas de l'écran.
  void _afficherPush(MessagePush m) {
    widget.compteur.compter();
    widget.messages.compter();
    _messagerie.currentState?.showSnackBar(SnackBar(
      content: Text(m.contenu.isEmpty ? m.titre : '${m.titre}\n${m.contenu}'),
      duration: const Duration(seconds: 6),
      action: SnackBarAction(label: 'Ouvrir', onPressed: () => _ouvrirPush(m)),
    ));
  }

  @override
  void dispose() {
    widget.session.removeListener(_suivreSession);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MaterialApp.router(
        title: 'YOBALEMAsn',
        debugShowCheckedModeBanner: false,
        scaffoldMessengerKey: _messagerie,
        theme: themeYobalema(),
        routerConfig: routeur,
        locale: const Locale('fr', 'FR'),
        supportedLocales: const [Locale('fr', 'FR')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
      );
}
