// Офлайн-режим демо-сайта МирСтади: всё нужное хранится на устройстве после первого открытия.
const CACHE = "mirstudy-demo-c688b56638";
const FILES = ["./", "assets/index-D-2-sav5.css", "assets/index-DYDu3sMh.js", "favicon.svg", "icons/apple-touch-icon.png", "icons/icon-192.png", "icons/icon-512.png", "icons/maskable-512.png", "index.html", "manifest.webmanifest"];
self.addEventListener("install", (e) => {
  e.waitUntil(caches.open(CACHE).then((c) => c.addAll(FILES)).then(() => self.skipWaiting()));
});
self.addEventListener("activate", (e) => {
  e.waitUntil(caches.keys().then((keys) => Promise.all(keys.filter((k) => k !== CACHE).map((k) => caches.delete(k)))).then(() => self.clients.claim()));
});
self.addEventListener("fetch", (e) => {
  const req = e.request;
  if (req.method !== "GET" || new URL(req.url).origin !== location.origin) return;
  if (req.mode === "navigate") {
    // страница: сначала сеть (чтобы получать обновления), без сети — из кэша
    e.respondWith(fetch(req).then((r) => { const copy = r.clone(); caches.open(CACHE).then((c) => c.put("./", copy)); return r; })
      .catch(() => caches.match("./").then((r) => r || caches.match("index.html"))));
    return;
  }
  e.respondWith(caches.match(req).then((hit) => hit || fetch(req)));
});
