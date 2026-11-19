/**
 * Prénom lu dans l'idToken Google (champ `given_name` de la charge utile), pour saluer la personne pendant
 * l'inscription. Affichage seulement : le jeton n'est pas vérifié ici (le backend le vérifie auprès de Google).
 */
export function prenomDuJeton(idToken: string | null | undefined): string | null {
  const charge = idToken?.split('.')[1];
  if (!charge) return null;
  try {
    const base64 = charge.replace(/-/g, '+').replace(/_/g, '/').padEnd(Math.ceil(charge.length / 4) * 4, '=');
    const octets = Uint8Array.from(atob(base64), (c) => c.charCodeAt(0));
    const prenom = (JSON.parse(new TextDecoder().decode(octets)) as { given_name?: unknown }).given_name;
    return typeof prenom === 'string' && prenom.trim() ? prenom.trim() : null;
  } catch {
    return null;
  }
}
