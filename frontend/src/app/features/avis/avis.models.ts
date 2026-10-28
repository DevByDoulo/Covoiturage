/** Types alignés sur les DTO du backend (sn.isep.Convoiturage.avis). */

export type RoleEvalue = 'CONDUCTEUR' | 'PASSAGER';

export interface PersonneResume {
  id: number;
  prenom: string;
  nomInitiale: string;
  photoProfil: string | null;
  noteMoyenne: number | null;
}

/** Voyage terminé que l'utilisateur peut encore noter. */
export interface AvisADonner {
  idReservation: number;
  idTrajet: number;
  trajet: string;
  dateHeureDepart: string;
  aNoter: PersonneResume;
  role: RoleEvalue;
  dateLimite: string;
}

export interface Avis {
  id: number;
  note: number;
  commentaire?: string;
  dateEvaluation: string;
  auteur: PersonneResume;
  /** Rôle de la personne notée sur ce trajet. */
  roleEvalue: RoleEvalue;
  trajet: string;
}

export interface Reputation {
  idUtilisateur: number;
  noteMoyenne: number | null;
  nombreAvis: number;
  /** Nombre d'avis à 1, 2, 3, 4 et 5 étoiles. */
  repartition: number[];
  avis: Avis[];
}

export const LIBELLES_NOTE = ['', 'Très décevant', 'Décevant', 'Correct', 'Bien', 'Excellent'];

/** Part (0 à 100) des avis ayant cette note, pour les barres de répartition. */
export function pourcentage(reputation: Reputation, note: number): number {
  if (!reputation.nombreAvis) return 0;
  return Math.round(((reputation.repartition[note - 1] ?? 0) * 100) / reputation.nombreAvis);
}
