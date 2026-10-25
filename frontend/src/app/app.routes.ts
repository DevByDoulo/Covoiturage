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
        title: 'Connexion · CoVoitIA',
        canActivate: [invitesGuard],
        loadComponent: () => import('./features/auth/connexion/connexion').then((m) => m.Connexion),
      },
      {
        path: 'inscription',
        title: 'Créer un compte · CoVoitIA',
        canActivate: [invitesGuard],
        loadComponent: () => import('./features/auth/inscription/inscription').then((m) => m.Inscription),
      },
      {
        path: 'verification',
        title: 'Vérification du numéro · CoVoitIA',
        canActivate: [verificationGuard],
        loadComponent: () => import('./features/auth/verification/verification').then((m) => m.Verification),
      },
      {
        path: 'mot-de-passe-oublie',
        title: 'Mot de passe oublié · CoVoitIA',
        loadComponent: () =>
          import('./features/auth/mot-de-passe-oublie/mot-de-passe-oublie').then((m) => m.MotDePasseOublie),
      },
      {
        path: 'google/telephone',
        title: 'Votre numéro · CoVoitIA',
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
      {
        path: 'accueil',
        title: 'Accueil · CoVoitIA',
        canActivate: [roleGuard('PASSAGER', 'CONDUCTEUR')],
        loadComponent: () => import('./features/accueil/accueil').then((m) => m.Accueil),
      },
      {
        path: 'admin',
        title: 'Back-office · CoVoitIA',
        canActivate: [roleGuard('ADMIN')],
        loadComponent: () => import('./features/accueil/accueil').then((m) => m.Accueil),
      },
      // F4 — Trajets
      {
        path: 'trajets/publier',
        title: 'Publier un trajet · CoVoitIA',
        canActivate: [roleGuard('PASSAGER', 'CONDUCTEUR')],
        loadComponent: () => import('./features/trajets/publier/publier').then((m) => m.Publier),
      },
      {
        path: 'trajets/mes-trajets',
        title: 'Mes trajets · CoVoitIA',
        canActivate: [roleGuard('CONDUCTEUR')],
        loadComponent: () => import('./features/trajets/mes-trajets/mes-trajets').then((m) => m.MesTrajets),
      },
      {
        path: 'trajets/:id',
        title: 'Trajet · CoVoitIA',
        loadComponent: () => import('./features/trajets/detail/detail-trajet').then((m) => m.DetailTrajet),
      },
    ],
  },
  { path: '**', redirectTo: 'accueil' },
];
