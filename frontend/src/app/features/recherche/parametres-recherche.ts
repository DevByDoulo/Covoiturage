import { Lieu } from '../../core/carte/geocodage';

/** Date du jour au format « 2026-11-18 » (valeur d'un champ date). */
export function aujourdhui(): string {
  return new Date().toISOString().slice(0, 10);
}

/**
 * Paramètres d'URL de la page Rechercher pour un départ, une arrivée, une date et un nombre de passagers.
 * Les valeurs par défaut (1 passager) sont omises, comme le fait la page Rechercher.
 */
export function parametresRecherche(depart: Lieu, arrivee: Lieu, date: string, passagers: number) {
  return {
    de: depart.libelle,
    dlat: depart.latitude.toFixed(6),
    dlng: depart.longitude.toFixed(6),
    a: arrivee.libelle,
    alat: arrivee.latitude.toFixed(6),
    alng: arrivee.longitude.toFixed(6),
    date: date || aujourdhui(),
    places: passagers > 1 ? passagers : null,
  };
}
