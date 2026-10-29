import { Routes } from '@angular/router';
import { connecteGuard, invitesGuard, roleGuard, verificationGuard } from './core/auth/auth.guards';

export const routes: Routes = [
  { path: '', pathMatch: 'full', redirectTo: 'accueil' },
  {
    path: 'auth',
    loadComponent: () => import('./features/auth/auth-layout').then((m) => m.AuthLayout),
    children: [
      { path: '', pathMatch: 'full', redirectTo: 'connexion' },
      {
        path: 'connexion',
        title: 'Connexion · YOBALEMAsn',
        canActivate: [invitesGuard],
        loadComponent: () => import('./features/auth/connexion/connexion').then((m) => m.Connexion),
      },
      {
        path: 'inscription',
        title: 'Créer un compte · YOBALEMAsn',
        canActivate: [invitesGuard],
        loadComponent: () => import('./features/auth/inscription/inscription').then((m) => m.Inscription),
      },
      {
        path: 'verification',
        title: 'Vérification · YOBALEMAsn',
        canActivate: [verificationGuard],
        loadComponent: () => import('./features/auth/verification/verification').then((m) => m.Verification),
      },
      {
        path: 'mot-de-passe-oublie',
        title: 'Mot de passe oublié · YOBALEMAsn',
        loadComponent: () =>
          import('./features/auth/mot-de-passe-oublie/mot-de-passe-oublie').then((m) => m.MotDePasseOublie),
      },
      {
        path: 'google/telephone',
        title: 'Votre numéro · YOBALEMAsn',
        loadComponent: () =>
          import('./features/auth/google-telephone/google-telephone').then((m) => m.GoogleTelephone),
      },
    ],
  },
  {
    // 07 — Administration : back-office avec son propre cadre (menu latéral).
    path: 'admin',
    canActivate: [connecteGuard, roleGuard('ADMIN')],
    loadComponent: () => import('./features/admin/admin-layout').then((m) => m.AdminLayout),
    children: [
      {
        path: '',
        title: 'Tableau de bord · YOBALEMAsn',
        loadComponent: () => import('./features/admin/tableau-de-bord').then((m) => m.TableauDeBord),
      },
      {
        path: 'documents',
        title: 'Validation des documents · YOBALEMAsn',
        loadComponent: () => import('./features/admin/validation-documents').then((m) => m.ValidationDocuments),
      },
      {
        path: 'utilisateurs',
        title: 'Utilisateurs · YOBALEMAsn',
        loadComponent: () => import('./features/admin/utilisateurs').then((m) => m.AdminUtilisateurs),
      },
      {
        path: 'utilisateurs/:id',
        title: 'Fiche utilisateur · YOBALEMAsn',
        loadComponent: () => import('./features/admin/fiche-utilisateur').then((m) => m.FicheUtilisateurPage),
      },
    ],
  },
  {
    // Espace connecté : barre de navigation commune.
    path: '',
    canActivate: [connecteGuard],
    loadComponent: () => import('./features/espace/espace-layout').then((m) => m.EspaceLayout),
    children: [
      // Chaque fonctionnalité ajoute ici ses écrans (fichier partagé : modifications courtes).
      {
        path: 'accueil',
        title: 'Accueil · YOBALEMAsn',
        canActivate: [roleGuard('PASSAGER', 'CONDUCTEUR')],
        loadComponent: () => import('./features/accueil/accueil').then((m) => m.Accueil),
      },
      // 01 — Gestion des utilisateurs
      {
        path: 'profil',
        title: 'Mon profil · YOBALEMAsn',
        loadComponent: () => import('./features/profil/profil').then((m) => m.ProfilPage),
      },
      {
        path: 'profil/mot-de-passe',
        title: 'Mot de passe · YOBALEMAsn',
        loadComponent: () => import('./features/profil/changer-mot-de-passe').then((m) => m.ChangerMotDePasse),
      },
      {
        path: 'profil/desactivation',
        title: 'Désactiver mon compte · YOBALEMAsn',
        canActivate: [roleGuard('PASSAGER', 'CONDUCTEUR')],
        loadComponent: () => import('./features/profil/desactivation').then((m) => m.Desactivation),
      },
      // 09 — Messagerie
      {
        path: 'messages',
        title: 'Messages · YOBALEMAsn',
        canActivate: [roleGuard('PASSAGER', 'CONDUCTEUR')],
        loadComponent: () => import('./features/messages/messages').then((m) => m.MessagesPage),
      },
      {
        path: 'messages/:id',
        title: 'Conversation · YOBALEMAsn',
        canActivate: [roleGuard('PASSAGER', 'CONDUCTEUR')],
        loadComponent: () => import('./features/messages/conversation').then((m) => m.ConversationPage),
      },
      // 06 — Notifications
      {
        path: 'notifications',
        title: 'Notifications · YOBALEMAsn',
        loadComponent: () => import('./features/notifications/notifications').then((m) => m.NotificationsPage),
      },
      // 02 — Gestion des véhicules
      {
        path: 'vehicules',
        title: 'Véhicules et documents · YOBALEMAsn',
        canActivate: [roleGuard('PASSAGER', 'CONDUCTEUR')],
        loadComponent: () => import('./features/vehicules/vehicules').then((m) => m.VehiculesPage),
      },
      {
        path: 'vehicules/:id',
        title: 'Véhicule · YOBALEMAsn',
        canActivate: [roleGuard('PASSAGER', 'CONDUCTEUR')],
        loadComponent: () => import('./features/vehicules/formulaire-vehicule').then((m) => m.FormulaireVehicule),
      },
      // 03 — Gestion des trajets
      {
        path: 'rechercher',
        title: 'Rechercher un trajet · YOBALEMAsn',
        canActivate: [roleGuard('PASSAGER', 'CONDUCTEUR')],
        loadComponent: () => import('./features/recherche/recherche').then((m) => m.Recherche),
      },
      {
        path: 'trajets/publier',
        title: 'Publier un trajet · YOBALEMAsn',
        canActivate: [roleGuard('PASSAGER', 'CONDUCTEUR')],
        loadComponent: () => import('./features/trajets/publier/publier').then((m) => m.Publier),
      },
      {
        path: 'trajets/mes-trajets',
        title: 'Mes trajets · YOBALEMAsn',
        canActivate: [roleGuard('CONDUCTEUR')],
        loadComponent: () => import('./features/trajets/mes-trajets/mes-trajets').then((m) => m.MesTrajets),
      },
      {
        path: 'trajets/:id',
        title: 'Trajet · YOBALEMAsn',
        loadComponent: () => import('./features/trajets/detail/detail-trajet').then((m) => m.DetailTrajet),
      },
      // 04 — Facturation (réservations, paiements, reçus)
      {
        path: 'reservations',
        title: 'Mes réservations · YOBALEMAsn',
        canActivate: [roleGuard('PASSAGER', 'CONDUCTEUR')],
        loadComponent: () => import('./features/reservations/mes-reservations').then((m) => m.MesReservations),
      },
      {
        path: 'paiements',
        title: 'Mes paiements · YOBALEMAsn',
        canActivate: [roleGuard('PASSAGER', 'CONDUCTEUR')],
        loadComponent: () => import('./features/facturation/mes-paiements').then((m) => m.MesPaiements),
      },
      {
        path: 'paiements/:reference/recu',
        title: 'Reçu · YOBALEMAsn',
        canActivate: [roleGuard('PASSAGER', 'CONDUCTEUR')],
        loadComponent: () => import('./features/facturation/recu').then((m) => m.RecuPage),
      },
    ],
  },
  { path: '**', redirectTo: 'accueil' },
];
