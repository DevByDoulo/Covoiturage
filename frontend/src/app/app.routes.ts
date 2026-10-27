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
      {
        path: 'admin',
        title: 'Back-office · YOBALEMAsn',
        canActivate: [roleGuard('ADMIN')],
        loadComponent: () => import('./features/accueil/accueil').then((m) => m.Accueil),
      },
    ],
  },
  { path: '**', redirectTo: 'accueil' },
];
