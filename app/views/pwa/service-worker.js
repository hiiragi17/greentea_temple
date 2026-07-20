// キャッシュ名を変えると古いキャッシュは activate 時に削除される
const CACHE_NAME = "matcha-to-jinja-v1"
const OFFLINE_URL = "/offline.html"
const PRECACHE_URLS = [OFFLINE_URL, "/icon-192.png"]

self.addEventListener("install", (event) => {
  event.waitUntil(
    caches.open(CACHE_NAME)
      .then((cache) => cache.addAll(PRECACHE_URLS))
      .then(() => self.skipWaiting())
  )
})

self.addEventListener("activate", (event) => {
  event.waitUntil(
    caches.keys()
      .then((keys) => Promise.all(keys.filter((key) => key !== CACHE_NAME).map((key) => caches.delete(key))))
      .then(() => self.clients.claim())
  )
})

// ページ遷移（navigate）のみ処理する。API（/api/v1）や静的アセットは
// キャッシュせず素通しにして、Turbo・JWT 認証の挙動に影響を与えない。
self.addEventListener("fetch", (event) => {
  if (event.request.mode !== "navigate") return

  event.respondWith(
    fetch(event.request).catch(() => caches.match(OFFLINE_URL))
  )
})

// Web Push 通知を導入する場合はここに push / notificationclick の
// ハンドラを追加する（Rails 8 標準テンプレート参照）
