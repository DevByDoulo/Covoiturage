import { HttpErrorResponse, HttpInterceptorFn, HttpRequest } from '@angular/common/http';
import { inject } from '@angular/core';
import { catchError, switchMap, throwError } from 'rxjs';
import { environment } from '../../../environments/environment';
import { SessionService } from './session.service';

/**
 * Ajoute « Authorization: Bearer » aux appels de notre API. Sur un 401, renouvelle le jeton
 * une seule fois puis rejoue la requête ; si le renouvellement échoue, la session est fermée.
 * Un visiteur sans session qui reçoit un 401 (appel réservé aux connectés) n'est pas renvoyé vers la connexion.
 */
export const authInterceptor: HttpInterceptorFn = (req, next) => {
  if (!req.url.startsWith(environment.apiUrl) || req.url.startsWith(`${environment.apiUrl}/auth/`)) {
    return next(req);
  }
  const session = inject(SessionService);
  const jetonEnvoye = session.accessToken;
  return next(avecJeton(req, jetonEnvoye)).pipe(
    catchError((err: unknown) => {
      if (!(err instanceof HttpErrorResponse) || err.status !== 401) return throwError(() => err);
      return session.rafraichir().pipe(
        catchError(() => {
          session.sessionExpiree();
          return throwError(() => err);
        }),
        switchMap((jeton) => {
          if (!jeton) {
            // Un visiteur (ni jeton envoyé ni session à rouvrir) n'a pas de session à fermer : l'erreur suffit.
            if (jetonEnvoye) session.sessionExpiree();
            return throwError(() => err);
          }
          return next(avecJeton(req, jeton));
        }),
      );
    }),
  );
};

function avecJeton(req: HttpRequest<unknown>, jeton: string | null): HttpRequest<unknown> {
  return jeton ? req.clone({ setHeaders: { Authorization: `Bearer ${jeton}` } }) : req;
}
