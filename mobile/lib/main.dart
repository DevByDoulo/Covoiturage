import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'core/api.dart';
import 'core/localisation.dart';
import 'core/session.dart';
import 'core/theme.dart';
import 'features/notifications/notifications.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('fr_FR');
  final api = Api();
  final session = Session(api);
  final compteur = CompteurNotifications(api);
  session.restaurer();
  runApp(
    MultiProvider(
      providers: [
        Provider.value(value: api),
        ChangeNotifierProvider.value(value: session),
        ChangeNotifierProvider.value(value: compteur),
        Provider(create: (_) => Geocodage()),
        Provider(create: (_) => PositionActuelle()),
      ],
      child: YobalemaApp(session: session, compteur: compteur),
    ),
  );
}

class YobalemaApp extends StatefulWidget {
  const YobalemaApp({super.key, required this.session, required this.compteur});

  final Session session;
  final CompteurNotifications compteur;

  @override
  State<YobalemaApp> createState() => _YobalemaAppState();
}

class _YobalemaAppState extends State<YobalemaApp> {
  late final routeur = creerRouteur(widget.session);

  @override
  void initState() {
    super.initState();
    // Le compteur de la cloche ne tourne que si quelqu'un est connecté.
    widget.session.addListener(_suivreSession);
  }

  void _suivreSession() => widget.compteur.suivre(widget.session.connecte);

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
