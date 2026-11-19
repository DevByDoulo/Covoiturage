/** Configuration de production : l'API est servie sur le même domaine, derrière /api. */
export const environment = {
  production: true,
  apiUrl: '/api',
  googleClientId: '',
  /**
   * « Se connecter avec Apple » (Apple Developer → Identifiers → Services IDs). clientId : le Services ID ;
   * redirectUri : l'adresse de retour déclarée pour ce Services ID (HTTPS, domaine vérifié ; localhost refusé par
   * Apple). Vide : le bouton Apple indique que la connexion Apple n'est pas activée.
   */
  apple: { clientId: '', redirectUri: '' },
  /** Notifications push du navigateur : mêmes valeurs publiques que environment.ts. */
  firebase: {
    apiKey: '',
    appId: '',
    projectId: 'yobalemasn-9a0a4',
    messagingSenderId: '312494312557',
    vapidKey: '',
  },
};
