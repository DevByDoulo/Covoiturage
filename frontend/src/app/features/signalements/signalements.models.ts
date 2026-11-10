import { PersonneResume } from '../avis/avis.models';

/** Types alignés sur les DTO du backend (sn.isep.Convoiturage.signalement). */

export type MotifSignalement =
  | 'COMPORTEMENT'
  | 'CONDUITE_DANGEREUSE'
  | 'NON_PRESENTATION'
  | 'ANNULATION_TARDIVE'
  | 'FRAUDE_DOCUMENTS'
  | 'HARCELEMENT'
  | 'AUTRE';

export type StatutSignalement = 'EN_ATTENTE' | 'EN_COURS' | 'TRAITE' | 'REJETE';

export type Decision = 'PRENDRE_EN_CHARGE' | 'CLASSER_SANS_SUITE' | 'AVERTIR' | 'BLOQUER' | 'BANNIR';

export const LIBELLES_MOTIF: Record<MotifSignalement, string> = {
  COMPORTEMENT: 'Comportement inapproprié',
  CONDUITE_DANGEREUSE: 'Conduite dangereuse',
  NON_PRESENTATION: 'Absence au rendez-vous',
  ANNULATION_TARDIVE: 'Annulation de dernière minute',
  FRAUDE_DOCUMENTS: 'Fausse identité ou faux documents',
  HARCELEMENT: 'Harcèlement',
  AUTRE: 'Autre',
};

export const MOTIFS = Object.keys(LIBELLES_MOTIF) as MotifSignalement[];

export const LIBELLES_STATUT_SIGNALEMENT: Record<StatutSignalement, string> = {
  EN_ATTENTE: 'En attente',
  EN_COURS: 'En cours d’examen',
  TRAITE: 'Traité',
  REJETE: 'Classé sans suite',
};

export const LIBELLES_DECISION: Record<Exclude<Decision, 'PRENDRE_EN_CHARGE'>, string> = {
  CLASSER_SANS_SUITE: 'Classer sans suite',
  AVERTIR: 'Envoyer un avertissement',
  BLOQUER: 'Bloquer le compte',
  BANNIR: 'Bannir le compte',
};

/** Vrai tant que l'administration n'a pas rendu sa décision. */
export function estOuvert(statut: StatutSignalement): boolean {
  return statut === 'EN_ATTENTE' || statut === 'EN_COURS';
}

/** Le motif « Autre » exige une description ; les autres la laissent facultative. */
export function descriptionObligatoire(motif: MotifSignalement | null): boolean {
  return motif === 'AUTRE';
}

export interface SignalementRequete {
  idUtilisateur: number;
  idTrajet: number | null;
  motif: MotifSignalement;
  description: string | null;
}

/** Vue du signaleur : il ne voit que l'avancement, jamais la décision détaillée. */
export interface Signalement {
  id: number;
  signale: PersonneResume;
  motif: MotifSignalement;
  description: string | null;
  statut: StatutSignalement;
  trajet: string | null;
  dateSignalement: string;
  dateTraitement: string | null;
}
