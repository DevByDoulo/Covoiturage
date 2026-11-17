/** Configuration de production : l'API est servie sur le même domaine, derrière /api. */
export const environment = {
  production: true,
  apiUrl: '/api',
  googleClientId: '',
  /** Notifications push du navigateur : mêmes valeurs publiques que environment.ts. */
  firebase: {
    apiKey: '',
    appId: '',
    projectId: 'yobalemasn-9a0a4',
    messagingSenderId: '312494312557',
    vapidKey: '',
  },
};
