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

/** PROFIL_REQUIS : numéro inconnu dont le code est bon ; le compte est créé avec le jeton d'inscription. */
export type EtapeAuth = 'CONNECTE' | 'OTP_ENVOYE' | 'TELEPHONE_REQUIS' | 'PROFIL_REQUIS';
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
  /** Vrai quand cette connexion a annulé une suppression de compte en cours (délai de grâce de 30 jours). */
  suppressionAnnulee?: boolean;
  /** PROFIL_REQUIS : autorise pendant 15 minutes la création du compte avec le numéro vérifié. */
  jetonInscription?: string;
}

/** Fin de l'inscription par téléphone : informations manquantes ; mot de passe facultatif. */
export interface FinInscriptionTelephone {
  prenom: string;
  nom: string;
  sexe: Sexe | null;
  motDePasse?: string;
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
  /** 'telephone' : connexion ou inscription par numéro (/api/auth/telephone/...). */
  mode?: 'telephone';
  /** Code demandé depuis l'inscription par numéro (« Retour » et habillage de l'écran du code). */
  inscription?: boolean;
  canal: CanalOtp;
  telephoneMasque: string | null;
  emailMasque: string | null;
  /** Instants (epoch ms) d'expiration du code et de possibilité de renvoi. */
  expireA: number;
  renvoiPossibleA: number;
}
