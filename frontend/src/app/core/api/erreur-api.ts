import { HttpErrorResponse } from '@angular/common/http';

/** Erreur normalisée à partir du ProblemDetail renvoyé par le backend. */
export interface ErreurApi {
  status: number;
  message: string;
  /** Champ du formulaire concerné (ex. « email » quand l'adresse est déjà utilisée). */
  champ?: string;
  /** Erreurs de validation par champ (400). */
  erreurs?: Record<string, string>;
  tentativesRestantes?: number;
  reessayerDansSecondes?: number;
}

export function lireErreur(err: unknown): ErreurApi {
  if (err instanceof HttpErrorResponse) {
    if (err.status === 0) {
      return { status: 0, message: 'Impossible de joindre le serveur. Vérifiez votre connexion.' };
    }
    const corps = (typeof err.error === 'object' && err.error) || {};
    return {
      status: err.status,
      message: corps.detail || messageParDefaut(err.status),
      champ: corps.champ,
      erreurs: corps.erreurs,
      tentativesRestantes: corps.tentativesRestantes,
      reessayerDansSecondes: corps.reessayerDansSecondes,
    };
  }
  return { status: -1, message: 'Une erreur inattendue est survenue.' };
}

function messageParDefaut(status: number): string {
  if (status === 401) return 'Session expirée, veuillez vous reconnecter.';
  if (status === 403) return "Vous n'avez pas accès à cette action.";
  if (status === 429) return 'Trop de tentatives. Réessayez plus tard.';
  if (status >= 500) return 'Le service est momentanément indisponible.';
  return 'La requête a échoué.';
}
