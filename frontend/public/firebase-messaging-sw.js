/*
 * YOBALEMAsn — service worker des notifications push du navigateur (module 06, Firebase Cloud Messaging).
 * Le backend envoie des messages « données seules » (titre, contenu, lien) : ce fichier les affiche quand aucun
 * onglet du site n'est visible, et ouvre l'écran de la notification au clic. Onglet visible : le message est
 * transmis à la page (PushService), qui met à jour la cloche.
 */
self.addEventListener('install', () => self.skipWaiting());
self.addEventListener('activate', (e) => e.waitUntil(self.clients.claim()));

self.addEventListener('push', (evenement) => {
  let charge = {};
  try {
    charge = evenement.data ? evenement.data.json() : {};
  } catch (_) {
    charge = {};
  }
  const donnees = charge.data || {};
  evenement.waitUntil(
    self.clients.matchAll({ type: 'window', includeUncontrolled: true }).then((onglets) => {
      if (onglets.some((o) => o.visibilityState === 'visible')) {
        onglets.forEach((o) => o.postMessage({ type: 'yobalema-push', lien: donnees.lien || null }));
        return undefined;
      }
      return self.registration.showNotification(donnees.titre || 'YOBALEMAsn', {
        body: donnees.contenu || '',
        icon: 'favicon.ico',
        tag: donnees.notificationId || undefined,
        data: { lien: donnees.lien || '/notifications' },
      });
    }),
  );
});

self.addEventListener('notificationclick', (evenement) => {
  evenement.notification.close();
  const lien = (evenement.notification.data && evenement.notification.data.lien) || '/notifications';
  const adresse = new URL(lien.replace(/^\//, ''), self.registration.scope).href;
  evenement.waitUntil(
    self.clients.matchAll({ type: 'window', includeUncontrolled: true }).then((onglets) => {
      const onglet = onglets.find((o) => o.url.startsWith(self.registration.scope));
      if (onglet) {
        onglet.postMessage({ type: 'yobalema-ouvrir', lien });
        return onglet.focus();
      }
      return self.clients.openWindow(adresse);
    }),
  );
});
