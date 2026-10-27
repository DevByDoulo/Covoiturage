/** Types alignés sur les DTO du backend (sn.isep.Convoiturage.auth / utilisateur). */

export type Role = 'PASSAGER' | 'CONDUCTEUR' | 'ADMIN';
export type Sexe = 'HOMME' | 'FEMME';
export type StatutCompte = 'EN_ATTENTE_OTP' | 'ACTIF' | 'BLOQUE' | 'BANNI' | 'DESACTIVE';

export interface Preferences {
  fumeurAccepte: boolean;
  musiqueAcceptee: boolean;
  animauxAcceptes: boolean;
  discussionAcceptee: boolean;
}

export interface Profil {
  id: number;
  prenom: string;
  nom: string;
  email: string | null;
  telephone: string | null;
  telephoneVerifie: boolean;
  emailVerifie: boolean;
  sexe: Sexe | null;
  photoProfil: string | null;
  bio: string | null;
  role: Role;
  statut: StatutCompte;
  conducteurValide: boolean;
  noteMoyenne: number | null;
  preferences: Preferences;
  /** Faux pour un compte créé avec Google : l'ancien mot de passe n'est alors pas demandé. */
  motDePasseDefini: boolean;
  dateCreation: string;
}

export type EtapeAuth = 'CONNECTE' | 'OTP_ENVOYE' | 'TELEPHONE_REQUIS';
export type CanalOtp = 'EMAIL' | 'SMS';

export interface AuthReponse {
  etape: EtapeAuth;
  accessToken?: string;
  refreshToken?: string;
  expiresIn?: number;
  canal?: CanalOtp;
  telephoneMasque?: string;
  emailMasque?: string;
  otpValiditeSecondes?: number;
  renvoiPossibleDansSecondes?: number;
  utilisateur?: Profil;
}

/** Code de « mot de passe oublié » accepté : le jeton autorise le nouveau mot de passe pendant validiteSecondes. */
export interface CodeVerifie {
  jeton: string;
  validiteSecondes: number;
}

export interface InscriptionRequete {
  prenom: string;
  nom: string;
  email: string;
  telephone: string;
  motDePasse: string;
  sexe: Sexe | null;
}

/** Vérification OTP en cours (conservée en sessionStorage pour survivre à un rechargement). */
export interface VerificationEnCours {
  /** Téléphone ou email permettant au backend de retrouver le compte. */
  identifiant: string;
  canal: CanalOtp;
  telephoneMasque: string | null;
  emailMasque: string | null;
  /** Instants (epoch ms) d'expiration du code et de possibilité de renvoi. */
  expireA: number;
  renvoiPossibleA: number;
}
