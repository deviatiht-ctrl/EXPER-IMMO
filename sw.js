// ============================================================
// EXPER IMMO - Service Worker
// Version 1.0.0
// ============================================================

const CACHE_NAME = 'experImmo-v2';
const STATIC_CACHE = 'experImmo-static-v2';

// App shell : fichiers à mettre en cache pour le mode hors-ligne
const APP_SHELL = [
    '/',
    '/index.html',
    '/proprietes.html',
    '/login.html',
    '/inscription.html',
    '/contact.html',
    '/a-propos.html',
    '/agents.html',
    '/manifest.json',
    '/assets/EXPER IMMO LOGO.png',
    '/assets/icons/icon-192.png',
    '/assets/icons/icon-512.png',
    '/css/global.css',
    '/css/components.css',
    '/css/navbar-modern.css',
    '/css/animations.css',
    '/css/footer.css',
    '/css/mobile-nav-modern.css',
    '/css/bottom-nav.css',
    '/js/config.js',
    'https://fonts.googleapis.com/css2?family=Playfair+Display:ital,wght@0,400;0,600;0,700;1,400&family=Inter:wght@300;400;500;600;700&display=swap'
];

// ============================================================
// INSTALL : mise en cache de l'app shell
// ============================================================
self.addEventListener('install', event => {
    event.waitUntil(
        caches.open(STATIC_CACHE)
            .then(cache => cache.addAll(APP_SHELL.map(url => {
                return new Request(url, { mode: 'no-cors' });
            })))
            .then(() => self.skipWaiting())
            .catch(err => console.log('[SW] Install cache error:', err))
    );
});

// ============================================================
// ACTIVATE : nettoyage des anciens caches
// ============================================================
self.addEventListener('activate', event => {
    event.waitUntil(
        caches.keys()
            .then(keys => Promise.all(
                keys
                    .filter(key => key !== STATIC_CACHE && key !== CACHE_NAME)
                    .map(key => caches.delete(key))
            ))
            .then(() => self.clients.claim())
    );
});

// ============================================================
// FETCH : stratégie Cache-First pour statiques,
//         Network-First pour API Supabase
// ============================================================
self.addEventListener('fetch', event => {
    const { request } = event;
    const url = new URL(request.url);

    // Ignorer les requêtes non-GET et les requêtes Supabase (toujours fraîches)
    if (request.method !== 'GET') return;
    if (url.hostname.includes('supabase.co')) return;
    if (url.hostname.includes('supabase.io')) return;
    if (url.protocol === 'chrome-extension:') return;

    // Ressources statiques (CSS, JS, images, polices) → Cache First
    if (
        url.pathname.startsWith('/css/')      ||
        url.pathname.startsWith('/js/')       ||
        url.pathname.startsWith('/assets/')   ||
        url.hostname.includes('fonts.gstatic.com') ||
        url.hostname.includes('fonts.googleapis.com') ||
        url.hostname.includes('unpkg.com')
    ) {
        event.respondWith(
            caches.match(request)
                .then(cached => cached || fetch(request).then(response => {
                    if (!response || response.status !== 200) return response;
                    return caches.open(STATIC_CACHE).then(cache => {
                        cache.put(request, response.clone());
                        return response;
                    });
                }))
                .catch(() => caches.match('/offline.html'))
        );
        return;
    }

    // Pages HTML → Network First avec fallback cache
    if (request.headers.get('accept') && request.headers.get('accept').includes('text/html')) {
        event.respondWith(
            fetch(request)
                .then(response => {
                    if (!response || response.status !== 200) return response;
                    return caches.open(CACHE_NAME).then(cache => {
                        cache.put(request, response.clone());
                        return response;
                    });
                })
                .catch(() => caches.match(request)
                    .then(cached => cached || caches.match('/index.html'))
                )
        );
        return;
    }

    // Défaut → Network with cache fallback
    event.respondWith(
        fetch(request)
            .then(response => {
                if (!response || response.status !== 200 || response.type !== 'basic') return response;
                const clone = response.clone();
                caches.open(CACHE_NAME).then(cache => cache.put(request, clone));
                return response;
            })
            .catch(() => caches.match(request))
    );
});

// ============================================================
// PUSH NOTIFICATIONS (futur)
// ============================================================
self.addEventListener('push', event => {
    if (!event.data) return;
    const data = event.data.json();
    self.registration.showNotification(data.title || 'EXPER IMMO', {
        body:    data.body    || 'Nouvelle notification',
        icon:    '/assets/icons/icon-192.png',
        badge:   '/assets/icons/icon-96.png',
        data:    { url: data.url || '/' },
        vibrate: [200, 100, 200]
    });
});

self.addEventListener('notificationclick', event => {
    event.notification.close();
    event.waitUntil(
        clients.openWindow(event.notification.data.url || '/')
    );
});
