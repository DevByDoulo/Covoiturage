import {
  ApplicationConfig,
  LOCALE_ID,
  inject,
  provideAppInitializer,
  provideBrowserGlobalErrorListeners,
} from '@angular/core';
import { registerLocaleData } from '@angular/common';
import localeFr from '@angular/common/locales/fr';
import { provideHttpClient, withFetch, withInterceptors } from '@angular/common/http';
import { provideRouter, withComponentInputBinding } from '@angular/router';

import { routes } from './app.routes';
import { authInterceptor } from './core/auth/auth.interceptor';
import { SessionService } from './core/auth/session.service';
import { Geocodage, GeocodageNominatim } from './core/carte/geocodage';

registerLocaleData(localeFr);

export const appConfig: ApplicationConfig = {
  providers: [
    provideBrowserGlobalErrorListeners(),
    provideHttpClient(withFetch(), withInterceptors([authInterceptor])),
    provideRouter(routes, withComponentInputBinding()),
    // Dates et nombres au format français (« lundi 28 octobre », « 1 650 »).
    { provide: LOCALE_ID, useValue: 'fr' },
    // Géocodage OpenStreetMap ; remplacer par une implémentation Google le jour où une clé est disponible.
    { provide: Geocodage, useClass: GeocodageNominatim },
    // Rouvre la session (refresh token) avant la première navigation, pour que les guards la voient.
    provideAppInitializer(() => inject(SessionService).restaurer()),
  ],
};
