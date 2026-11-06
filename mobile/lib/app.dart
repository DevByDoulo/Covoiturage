import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'core/session.dart';
import 'core/theme.dart';
import 'features/auth/connexion.dart';
import 'features/auth/inscription.dart';
import 'features/auth/verification.dart';
import 'features/conducteur/mes_trajets.dart';
import 'features/conducteur/publier.dart';
import 'features/conducteur/trajet_conducteur.dart';
import 'features/notifications/notifications.dart';
import 'features/profil/profil.dart';
import 'features/recherche/recherche.dart';
import 'features/reservations/reservations.dart';
import 'features/trajet/detail_trajet.dart';

/// Écrans accessibles sans être connecté.
const _publics = {'/connexion', '/inscription', '/verification'};

GoRouter creerRouteur(Session session) => GoRouter(
  initialLocation: '/rechercher',
  refreshListenable: session,
  redirect: (context, etat) {
    final chemin = etat.matchedLocation;
    if (!session.pret) return chemin == '/demarrage' ? null : '/demarrage';
    final public = _publics.contains(chemin);
    if (!session.connecte && !public) return '/connexion';
    if (session.connecte && (public || chemin == '/demarrage')) return '/rechercher';
    return null;
  },
  routes: [
    GoRoute(path: '/demarrage', builder: (_, _) => const _Demarrage()),
    GoRoute(path: '/connexion', builder: (_, _) => const ConnexionPage()),
    GoRoute(path: '/inscription', builder: (_, _) => const InscriptionPage()),
    GoRoute(
      path: '/verification',
      builder: (_, etat) => VerificationPage(demande: etat.extra as DemandeVerification),
    ),
    GoRoute(
      path: '/trajets/:id',
      builder: (_, etat) => DetailTrajetPage(id: int.parse(etat.pathParameters['id']!)),
    ),
    // Avant l'onglet « /conduite » : écrans plein écran du conducteur.
    GoRoute(path: '/conduite/publier', builder: (_, _) => const PublierPage()),
    GoRoute(
      path: '/conduite/:id',
      builder: (_, etat) => TrajetConducteurPage(id: int.parse(etat.pathParameters['id']!)),
    ),
    StatefulShellRoute.indexedStack(
      builder: (_, _, navigation) => _Cadre(navigation: navigation),
      branches: [
        StatefulShellBranch(
          routes: [GoRoute(path: '/rechercher', builder: (_, _) => const RecherchePage())],
        ),
        StatefulShellBranch(
          routes: [GoRoute(path: '/reservations', builder: (_, _) => const ReservationsPage())],
        ),
        StatefulShellBranch(
          routes: [GoRoute(path: '/conduite', builder: (_, _) => const MesTrajetsPage())],
        ),
        StatefulShellBranch(
          routes: [GoRoute(path: '/notifications', builder: (_, _) => const NotificationsPage())],
        ),
        StatefulShellBranch(
          routes: [GoRoute(path: '/profil', builder: (_, _) => const ProfilPage())],
        ),
      ],
    ),
  ],
);

/// Barre d'onglets du bas, avec le nombre de notifications non lues.
class _Cadre extends StatelessWidget {
  const _Cadre({required this.navigation});

  final StatefulNavigationShell navigation;

  @override
  Widget build(BuildContext context) {
    final nonLues = context.watch<CompteurNotifications>().nonLues;
    return Scaffold(
      body: navigation,
      // Cinq onglets : libellés plus petits pour tenir sur une ligne (« Réservations », « Notifications »).
      bottomNavigationBar: NavigationBarTheme(
        data: const NavigationBarThemeData(
          labelTextStyle: WidgetStatePropertyAll(TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
        ),
        child: NavigationBar(
          selectedIndex: navigation.currentIndex,
          onDestinationSelected: (i) => navigation.goBranch(i, initialLocation: i == navigation.currentIndex),
          destinations: [
            const NavigationDestination(icon: Icon(Icons.search), label: 'Rechercher'),
            const NavigationDestination(
              icon: Icon(Icons.confirmation_number_outlined),
              selectedIcon: Icon(Icons.confirmation_number),
              label: 'Réservations',
            ),
            const NavigationDestination(
              icon: Icon(Icons.directions_car_outlined),
              selectedIcon: Icon(Icons.directions_car),
              label: 'Conduire',
            ),
            NavigationDestination(
              icon: Badge(
                isLabelVisible: nonLues > 0,
                label: Text('$nonLues'),
                child: const Icon(Icons.notifications_outlined),
              ),
              selectedIcon: const Icon(Icons.notifications),
              label: 'Notifications',
            ),
            const NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person),
              label: 'Profil',
            ),
          ],
        ),
      ),
    );
  }
}

class _Demarrage extends StatelessWidget {
  const _Demarrage();

  @override
  Widget build(BuildContext context) => const Scaffold(
    body: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [Logo(taille: 32), SizedBox(height: 24), CircularProgressIndicator()],
      ),
    ),
  );
}
