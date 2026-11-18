/** URL de retour interne uniquement (évite les redirections ouvertes). */
export function retourSur(url: string | undefined | null): string | null {
  return url && url.startsWith('/') && !url.startsWith('//') && !url.startsWith('/\\') ? url : null;
}
