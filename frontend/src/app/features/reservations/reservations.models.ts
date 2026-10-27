/** Types alignés sur les DTO du backend (sn.isep.Convoiturage.reservation / facturation). */

export type StatutReservation = 'EN_ATTENTE' | 'ACCEPTEE' | 'REFUSEE' | 'ANNULEE' | 'TERMINEE';
export type MoyenPaiement = 'ESPECES' | 'WAVE' | 'ORANGE_MONEY';
export type StatutPaiement = 'EN_ATTENTE' | 'REUSSI' | 'ECHOUE' | 'REMBOURSEMENT_DEMANDE' | 'REMBOURSE';

export interface PersonneResume {
  id: number;
  prenom: string;
  nomInitiale: string;
  photoProfil: string | null;
  noteMoyenne: number | null;
}

export interface Reservation {
  id: number;
  trajet: {
    id: number;
    lieuDepart: string;
    lieuArrivee: string;
    dateHeureDepart: string;
    statut: string;
    conducteur: PersonneResume;
  };
  passager: PersonneResume;
  nombrePlaces: number;
  prixUnitaire: number;
  montantTotal: number;
  statut: StatutReservation;
  pointRamassage: string;
  moyenPaiement: MoyenPaiement | null;
  statutPaiement: StatutPaiement | null;
  embarque: boolean;
  motifAnnulation?: string;
  dateDemande: string;
  dateReponse?: string;
}

export interface CodeEmbarquement {
  idReservation: number;
  codePin: string;
  qrContenu: string;
  statut: 'EN_ATTENTE' | 'CONFIRMEE' | 'EXPIREE' | 'ANNULEE';
  dateExpiration: string;
  /** À régler en espèces au conducteur (0 si déjà payé en ligne). */
  montantAPayer: number;
}

export interface EmbarquementConfirme {
  idReservation: number;
  passager: PersonneResume;
  nombrePlaces: number;
  montantAEncaisser: number;
  moyenPaiement: MoyenPaiement;
}

export interface MoyenDisponible {
  moyen: MoyenPaiement;
  disponible: boolean;
}

export interface SessionPaiement {
  referenceTransaction: string;
  moyen: MoyenPaiement;
  statut: StatutPaiement;
  montant: number;
  /** Page de paiement de l'opérateur (absente pour les espèces). */
  urlPaiement?: string;
}

export interface LignePaiement {
  referenceTransaction: string;
  idReservation: number;
  role: 'PASSAGER' | 'CONDUCTEUR';
  trajet: string;
  dateHeureDepart: string;
  contrepartie: string;
  montant: number;
  moyen: MoyenPaiement;
  statut: StatutPaiement;
  dateInitiation: string;
  dateConfirmation?: string;
  dateRemboursement?: string;
}

export interface Recu {
  referenceTransaction: string;
  referenceOperateur?: string;
  dateConfirmation?: string;
  passager: string;
  conducteur: string;
  trajet: string;
  dateHeureDepart: string;
  nombrePlaces: number;
  prixUnitaire: number;
  montant: number;
  commission: number;
  montantConducteur: number;
  moyen: MoyenPaiement;
  statut: StatutPaiement;
  dateRemboursement?: string;
}

export const LIBELLES_MOYEN: Record<MoyenPaiement, string> = {
  ESPECES: 'Espèces',
  WAVE: 'Wave',
  ORANGE_MONEY: 'Orange Money',
};

export const LIBELLES_STATUT_RESERVATION: Record<StatutReservation, string> = {
  EN_ATTENTE: 'En attente du conducteur',
  ACCEPTEE: 'Confirmée',
  REFUSEE: 'Refusée',
  ANNULEE: 'Annulée',
  TERMINEE: 'Terminée',
};

export const LIBELLES_STATUT_PAIEMENT: Record<StatutPaiement, string> = {
  EN_ATTENTE: 'À payer',
  REUSSI: 'Payé',
  ECHOUE: 'Non abouti',
  REMBOURSEMENT_DEMANDE: 'Remboursement en cours',
  REMBOURSE: 'Remboursé',
};

/** Paiement en ligne à faire (ou à refaire après un échec) pour une réservation confirmée. */
export function paiementEnLigneAttendu(r: Reservation): boolean {
  return r.statut === 'ACCEPTEE' && !r.embarque && !!r.moyenPaiement && r.moyenPaiement !== 'ESPECES'
    && (r.statutPaiement === 'EN_ATTENTE' || r.statutPaiement === 'ECHOUE');
}

/** Total réellement encaissé comme conducteur (les paiements remboursés ou non aboutis ne comptent pas). */
export function totalEncaisse(lignes: LignePaiement[]): number {
  return lignes.filter((l) => l.role === 'CONDUCTEUR' && l.statut === 'REUSSI').reduce((t, l) => t + l.montant, 0);
}
