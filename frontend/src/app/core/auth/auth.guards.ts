import { inject } from '@angular/core';
import { CanActivateFn, CanMatchFn, Router } from '@angular/router';
import { Role } from './auth.models';
import { retourSur } from './retour';
import { SessionService } from './session.service';

/** Réservé aux utilisateurs connectés ; sinon redirection vers la connexion avec retour prévu. */
export const connecteGuard: CanActivateFn = (_route, state) => {
  const session = inject(SessionService);
  if (session.estConnecte()) return true;
  return inject(Router).createUrlTree(['/auth/connexion'], { queryParams: { retour: state.url } });
};

/** Pages d'authentification : inutile d'y aller une fois connecté (on rejoint le retour prévu, sinon l'accueil). */
export const invitesGuard: CanActivateFn = (route) => {
  const session = inject(SessionService);
  return session.estConnecte()
    ? inject(Router).parseUrl(retourSur(route.queryParamMap.get('retour')) ?? session.pageAccueil())
    : true;
};

/**
 * Page publique réservée aux visiteurs : un utilisateur connecté passe à la route suivante (même chemin, version
 * de l'espace connecté). À utiliser avec `canMatch`.
 */
export const visiteurMatch: CanMatchFn = () => !inject(SessionService).estConnecte();

/** `/trajets/<nombre>` seulement : laisse `/trajets/publier` et `/trajets/mes-trajets` aux routes qui les gèrent. */
export const idTrajetMatch: CanMatchFn = (_route, segments) => /^\d+$/.test(segments[1]?.path ?? '');

/** Exige l'un des rôles donnés (le backend vérifie aussi à chaque requête). */
export function roleGuard(...roles: Role[]): CanActivateFn {
  return (_route, state) => {
    const session = inject(SessionService);
    const router = inject(Router);
    const role = session.utilisateur()?.role;
    if (!role) return router.createUrlTree(['/auth/connexion'], { queryParams: { retour: state.url } });
    return roles.includes(role) ? true : router.parseUrl(session.pageAccueil());
  };
}

/** L'écran OTP n'a de sens que si une vérification est en cours. */
export const verificationGuard: CanActivateFn = () =>
  inject(SessionService).verification() ? true : inject(Router).parseUrl('/auth/connexion');
