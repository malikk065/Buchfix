/* BuchFix Service Worker — macht die App offline lauffähig. */
const CACHE = "buchfix-v2";
const DATEIEN = [
  "./", "./index.html", "./manifest.webmanifest", "./config.js",
  "./lib/jspdf.umd.min.js", "./lib/supabase.js",
  "./icons/icon-192.png", "./icons/icon-512.png",
  "./icons/apple-touch-icon.png", "./icons/favicon-32.png"
];

self.addEventListener("install", e => {
  e.waitUntil(
    caches.open(CACHE)
      .then(c => c.addAll(DATEIEN).catch(() => c.addAll(["./index.html"])))
      .then(() => self.skipWaiting())
  );
});

self.addEventListener("activate", e => {
  e.waitUntil(
    caches.keys()
      .then(ks => Promise.all(ks.filter(k => k !== CACHE).map(k => caches.delete(k))))
      .then(() => self.clients.claim())
  );
});

/* Netz zuerst für die App-Datei (damit Updates ankommen),
   Cache als Rückfall, wenn kein Empfang da ist. */
self.addEventListener("fetch", e => {
  const req = e.request;
  if (req.method !== "GET" || !req.url.startsWith(self.location.origin)) return;

  if (req.mode === "navigate" || req.url.endsWith("index.html")) {
    e.respondWith(
      fetch(req)
        .then(res => { const k = res.clone(); caches.open(CACHE).then(c => c.put(req, k)); return res; })
        .catch(() => caches.match(req).then(r => r || caches.match("./index.html")))
    );
    return;
  }
  e.respondWith(
    caches.match(req).then(hit => hit || fetch(req).then(res => {
      const k = res.clone(); caches.open(CACHE).then(c => c.put(req, k)); return res;
    }))
  );
});
