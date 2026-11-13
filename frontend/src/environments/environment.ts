/** Configuration de développement (ng serve). */
export const environment = {
  production: false,
  apiUrl: 'http://localhost:8080/api',
  /** ID client OAuth Google (console Google Cloud). Vide : bouton Google désactivé. */
  googleClientId: '520088419510-nu738k1cpi6s20k5fkqupu0nfbsgautv.apps.googleusercontent.com',
  /**
   * Notifications push du navigateur (Firebase Cloud Messaging, projet yobalemasn-9a0a4). Valeurs publiques de
   * l'application Web de la console Firebase (Paramètres du projet → Vos applications) ; clé VAPID : Cloud Messaging
   * → Certificats push Web. Une valeur vide : le bloc « Notifications push » indique qu'elles ne sont pas configurées.
   */
  firebase: {
    apiKey: '',
    appId: '',
    projectId: 'yobalemasn-9a0a4',
    messagingSenderId: '312494312557',
    vapidKey: '',
  },
};
