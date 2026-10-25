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
        title: 'Connexion · YobalemaSn',
        canActivate: [invitesGuard],
        loadComponent: () => import('./features/auth/connexion/connexion').then((m) => m.Connexion),
      },
      {
        path: 'inscription',
        title: 'Créer un compte · YobalemaSn',
        canActivate: [invitesGuard],
        loadComponent: () => import('./features/auth/inscription/inscription').then((m) => m.Inscription),
      },
      {
        path: 'verification',
        title: 'Vérification du numéro · YobalemaSn',
        canActivate: [verificationGuard],
        loadComponent: () => import('./features/auth/verification/verification').then((m) => m.Verification),
      },
      {
        path: 'mot-de-passe-oublie',
        title: 'Mot de passe oublié · YobalemaSn',
        loadComponent: () =>
          import('./features/auth/mot-de-passe-oublie/mot-de-passe-oublie').then((m) => m.MotDePasseOublie),
      },
      {
        path: 'google/telephone',
        title: 'Votre numéro · YobalemaSn',
        loadComponent: () =>
          import('./features/auth/google-telephone/google-telephone').then((m) => m.GoogleTelephone),
      },
    ],
  },
  {
    path: 'accueil',
    title: 'Accueil · YobalemaSn',
    canActivate: [connecteGuard, roleGuard('PASSAGER', 'CONDUCTEUR')],
    loadComponent: () => import('./features/accueil/accueil').then((m) => m.Accueil),
  },
  {
    path: 'admin',
    title: 'Back-office · YobalemaSn',
    canActivate: [roleGuard('ADMIN')],
    loadComponent: () => import('./features/accueil/accueil').then((m) => m.Accueil),
  },
  { path: '**', redirectTo: 'accueil' },
];
