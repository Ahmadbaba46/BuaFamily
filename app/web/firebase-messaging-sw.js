// Shows Bua Family notifications in the browser when the app isn't open, and
// opens the right page when one is tapped. Firebase registers this file when a
// member turns on notifications; it needs no Firebase settings of its own.

self.addEventListener('install', () => self.skipWaiting());
self.addEventListener('activate', (event) => event.waitUntil(self.clients.claim()));

self.addEventListener('push', (event) => {
  let payload = {};
  try {
    payload = event.data ? event.data.json() : {};
  } catch (_) {
    payload = { notification: { body: event.data && event.data.text() } };
  }
  const n = payload.notification || {};
  const data = payload.data || {};
  event.waitUntil(
    self.registration.showNotification(n.title || 'Bua Family', {
      body: n.body || '',
      icon: '/icons/Icon-192.png',
      badge: '/icons/Icon-192.png',
      tag: data.id || undefined,
      data: { link: data.link || '/notifications' },
    }),
  );
});

self.addEventListener('notificationclick', (event) => {
  event.notification.close();
  const link = (event.notification.data && event.notification.data.link) || '/notifications';
  const url = new URL(link.startsWith('/') ? link : '/notifications', self.location.origin).href;
  event.waitUntil(
    self.clients.matchAll({ type: 'window', includeUncontrolled: true }).then((windows) => {
      for (const w of windows) {
        if (new URL(w.url).origin === self.location.origin && 'focus' in w) {
          return w.focus().then((c) => (c && 'navigate' in c ? c.navigate(url) : c));
        }
      }
      return self.clients.openWindow(url);
    }),
  );
});
