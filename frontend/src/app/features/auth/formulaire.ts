import { AbstractControl, FormGroup, ValidationErrors, ValidatorFn } from '@angular/forms';
import { ErreurApi } from '../../core/api/erreur-api';

/** Même règle que le backend : 8 caractères minimum, au moins une lettre et un chiffre. */
export const REGLE_MOT_DE_PASSE = /^(?=.*[A-Za-z])(?=.*\d).{8,72}$/;

/** Numéro sénégalais saisi sans indicatif (« 77 123 45 67 »), ou avec +221 / 00221. */
export function chiffresTelephone(brut: string): string {
  let c = brut.replace(/\D/g, '');
  if (c.startsWith('00221')) c = c.slice(5);
  else if (c.startsWith('221') && c.length === 12) c = c.slice(3);
  return c;
}

export const telephoneSenegalValidator: ValidatorFn = (c: AbstractControl): ValidationErrors | null =>
  !c.value || /^(7[05678]|33)\d{7}$/.test(chiffresTelephone(c.value)) ? null : { telephone: true };

/** Validateur de groupe : les deux champs doivent être identiques. */
export function champsIdentiques(a: string, b: string): ValidatorFn {
  return (g: AbstractControl): ValidationErrors | null => {
    const confirmation = g.get(b);
    if (!confirmation?.value) return null;
    return g.get(a)?.value === confirmation.value ? null : { differents: true };
  };
}

/** Affiche une erreur seulement après que l'utilisateur a quitté le champ ou tenté d'envoyer. */
export function enErreur(form: FormGroup, nom: string): boolean {
  const c = form.get(nom);
  return !!c && c.invalid && (c.touched || c.dirty);
}

/**
 * Reporte une erreur serveur sur le champ concerné (propriété « champ » ou erreurs de validation).
 * Renvoie true si au moins un champ a été marqué ; sinon l'appelant affiche une alerte générale.
 */
export function appliquerErreurServeur(form: FormGroup, e: ErreurApi): boolean {
  let marque = false;
  const marquer = (nom: string, message: string) => {
    const c = form.get(nom);
    if (!c) return;
    c.setErrors({ ...(c.errors ?? {}), serveur: message });
    c.markAsTouched();
    marque = true;
  };
  if (e.champ) marquer(e.champ, e.message);
  for (const [nom, message] of Object.entries(e.erreurs ?? {})) marquer(nom, message);
  return marque;
}

/** URL de retour interne uniquement (évite les redirections ouvertes). */
export function retourSur(url: string | undefined | null): string | null {
  return url && url.startsWith('/') && !url.startsWith('//') ? url : null;
}
