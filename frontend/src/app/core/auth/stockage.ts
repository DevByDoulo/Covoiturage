/**
 * Accès au stockage du navigateur protégé : en navigation privée ou si les cookies sont bloqués,
 * localStorage/sessionStorage peuvent lever une exception. L'application doit alors continuer à fonctionner.
 */
export const stockage = {
  lire(cle: string, session = false): string | null {
    try {
      return (session ? sessionStorage : localStorage).getItem(cle);
    } catch {
      return null;
    }
  },
  ecrire(cle: string, valeur: string, session = false): void {
    try {
      (session ? sessionStorage : localStorage).setItem(cle, valeur);
    } catch {
      /* stockage indisponible : la valeur reste en mémoire seulement */
    }
  },
  supprimer(cle: string, session = false): void {
    try {
      (session ? sessionStorage : localStorage).removeItem(cle);
    } catch {
      /* rien à faire */
    }
  },
};
