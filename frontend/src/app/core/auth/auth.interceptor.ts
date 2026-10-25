import { HttpErrorResponse, HttpInterceptorFn, HttpRequest } from '@angular/common/http';
import { inject } from '@angular/core';
import { catchError, switchMap, throwError } from 'rxjs';
import { environment } from '../../../environments/environment';
import { SessionService } from './session.service';

/**
 * Ajoute « Authorization: Bearer » aux appels de notre API. Sur un 401, renouvelle le jeton
 * une seule fois puis rejoue la requête ; si le renouvellement échoue, la session est fermée.
 */
export const authInterceptor: HttpInterceptorFn = (req, next) => {
  if (!req.url.startsWith(environment.apiUrl) || req.url.startsWith(`${environment.apiUrl}/auth/`)) {
    return next(req);
  }
  const session = inject(SessionService);
  return next(avecJeton(req, session.accessToken)).pipe(
    catchError((err: unknown) => {
      if (!(err instanceof HttpErrorResponse) || err.status !== 401) return throwError(() => err);
      return session.rafraichir().pipe(
        catchError(() => {
          session.sessionExpiree();
          return throwError(() => err);
        }),
        switchMap((jeton) => {
          if (!jeton) {
            session.sessionExpiree();
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
