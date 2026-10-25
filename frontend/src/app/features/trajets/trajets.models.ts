/** Types alignés sur les DTO du backend (sn.isep.Convoiturage.trajet / tarification / vehicule). */

export type ModeReservation = 'AUTOMATIQUE' | 'MANUELLE';
export type TailleBagage = 'PETIT' | 'MOYEN' | 'GRAND';
export type TypeRoute = 'AUTOROUTE' | 'NATIONALE' | 'VILLE' | 'MIXTE';
export type StatutTrajet = 'PUBLIE' | 'COMPLET' | 'EN_COURS' | 'TERMINE' | 'ANNULE';
export type TypeEnergie = 'ESSENCE' | 'DIESEL' | 'HYBRIDE' | 'ELECTRIQUE';

export interface PointTrajet {
  lieu: string;
  latitude: number;
  longitude: number;
}

export interface EstimationPrix {
  prixRecommande: number;
  prixMin: number;
  prixMax: number;
  prixCarburantUtilise: number;
  consommationUtilisee: number;
  consommationEstimee: boolean;
  heureDePointe: boolean;
  versionModele: string;
  coutCarburant: number;
  coutUsure: number;
  coutPeages: number;
  coutTotal: number;
  nombreOccupants: number;
}

export interface EstimationReponse {
  distanceKm: number;
  dureeEstimeeMin: number;
  typeRoute: TypeRoute;
  montantPeages: number;
  sourceItineraire: 'GOOGLE' | 'ESTIMATION';
  itinerairePolyline: string;
  tarif: EstimationPrix;
}

export interface DemandeEstimation {
  idVehicule: number;
  depart: PointTrajet;
  arrivee: PointTrajet;
  escales: PointTrajet[];
  dateHeureDepart: string;
  nombrePlaces: number;
}

export interface PublicationTrajet extends DemandeEstimation {
  flexibiliteMinutes: number;
  modeReservation: ModeReservation;
  tailleBagage: TailleBagage;
  femmesUniquement: boolean;
  prixParPlace: number | null;
}

/** Champs modifiables d'un trajet publié (seuls ceux fournis changent). */
export interface ModificationTrajet {
  dateHeureDepart?: string;
  flexibiliteMinutes?: number;
  nombrePlaces?: number;
  modeReservation?: ModeReservation;
  tailleBagage?: TailleBagage;
  prixParPlace?: number;
}

export interface Escale {
  id: number;
  ordre: number;
  lieu: string;
  latitude: number;
  longitude: number;
}

export interface Tarification {
  prixIa: number;
  prixMin: number;
  prixMax: number;
  prixFinal: number;
  prixCarburantUtilise: number;
  heureDePointe: boolean;
  versionModele: string;
  datePrediction: string;
}

export interface Correspondance {
  distanceRamassageM: number;
  distanceDeposeM: number;
  latitudeRamassage: number;
  longitudeRamassage: number;
  latitudeDepose: number;
  longitudeDepose: number;
}

export interface Trajet {
  id: number;
  conducteur: { id: number; prenom: string; nomInitiale: string; photoProfil: string | null; noteMoyenne: number | null };
  preferencesConducteur: {
    fumeurAccepte: boolean;
    musiqueAcceptee: boolean;
    animauxAcceptes: boolean;
    discussionAcceptee: boolean;
  };
  vehicule: { id: number; marque: string; modele: string; annee: number; typeEnergie: TypeEnergie };
  depart: PointTrajet;
  arrivee: PointTrajet;
  escales: Escale[];
  dateHeureDepart: string;
  flexibiliteMinutes: number;
  nombrePlacesTotal: number;
  nombrePlacesDisponibles: number;
  modeReservation: ModeReservation;
  tailleBagage: TailleBagage;
  femmesUniquement: boolean;
  distanceKm: number;
  dureeEstimeeMin: number;
  typeRoute: TypeRoute;
  prixParPlace: number;
  statut: StatutTrajet;
  motifAnnulation?: string;
  itinerairePolyline: string;
  /** Présent uniquement pour le conducteur du trajet. */
  tarification?: Tarification;
  /** Présent uniquement dans les résultats de recherche. */
  correspondance?: Correspondance;
}

/** Véhicule tel que renvoyé par GET /api/moi/vehicules (module F2). */
export interface VehiculeConducteur {
  id: number;
  immatriculation: string;
  marque: string;
  modele: string;
  annee: number;
  nombrePlaces: number;
  typeEnergie: TypeEnergie;
  statutValidation: 'EN_ATTENTE' | 'VALIDE' | 'REFUSE';
  actif: boolean;
}

export const LIBELLES_STATUT: Record<StatutTrajet, string> = {
  PUBLIE: 'Publié',
  COMPLET: 'Complet',
  EN_COURS: 'En cours',
  TERMINE: 'Terminé',
  ANNULE: 'Annulé',
};

export const LIBELLES_BAGAGE: Record<TailleBagage, string> = {
  PETIT: 'Petit bagage',
  MOYEN: 'Bagage moyen',
  GRAND: 'Grand bagage',
};

export const LIBELLES_ROUTE: Record<TypeRoute, string> = {
  AUTOROUTE: 'Autoroute',
  NATIONALE: 'Nationale',
  VILLE: 'En ville',
  MIXTE: 'Mixte',
};

/** Critères de GET /api/trajets/recherche (F5). Seuls les champs renseignés sont envoyés. */
export interface CriteresRecherche {
  latDepart: number;
  lngDepart: number;
  latArrivee: number;
  lngArrivee: number;
  date: string;
  places?: number;
  heureMin?: string;
  heureMax?: string;
  rayonKm?: number;
  prixMax?: number;
  noteMin?: number;
  femmesUniquement?: boolean;
  conducteur?: string;
}

/** Alerte de recherche (F5) : prévenu quand un trajet correspondant est publié. */
export interface AlerteRecherche {
  id: number;
  depart: PointTrajet;
  arrivee: PointTrajet;
  date: string;
  rayonKm: number;
  prixMax: number | null;
  dateCreation: string;
}

export interface CreationAlerte {
  depart: PointTrajet;
  arrivee: PointTrajet;
  date: string;
  rayonKm?: number;
  prixMax?: number | null;
}
