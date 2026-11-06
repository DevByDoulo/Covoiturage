import { PointTrajet, Trajet } from './trajets.models';

/**
 * Point de rendez-vous d'un passager : l'escale choisie comme point de prise en charge (la réservation n'en donne
 * que le nom), sinon le départ du trajet. Le conducteur, lui, va au départ.
 */
export function pointDeRendezVous(t: Trajet, pointRamassage: string | null | undefined): PointTrajet {
  const escale = pointRamassage ? t.escales.find((e) => e.lieu === pointRamassage) : undefined;
  return escale ? { lieu: escale.lieu, latitude: escale.latitude, longitude: escale.longitude } : t.depart;
}
