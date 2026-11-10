import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'core/api.dart';
import 'core/localisation.dart';
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
  session.restaurer();
  runApp(
    MultiProvider(
      providers: [
        Provider.value(value: api),
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
      child: YobalemaApp(session: session, compteur: compteur, messages: messages),
    ),
  );
}

class YobalemaApp extends StatefulWidget {
  const YobalemaApp({super.key, required this.session, required this.compteur, required this.messages});

  final Session session;
  final CompteurNotifications compteur;
  final CompteurMessages messages;

  @override
  State<YobalemaApp> createState() => _YobalemaAppState();
}

class _YobalemaAppState extends State<YobalemaApp> {
  late final routeur = creerRouteur(widget.session);

  @override
  void initState() {
    super.initState();
    // Les compteurs (cloche, messages) ne tournent que si quelqu'un est connecté.
    widget.session.addListener(_suivreSession);
  }

  void _suivreSession() {
    widget.compteur.suivre(widget.session.connecte);
    widget.messages.suivre(widget.session.connecte);
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
