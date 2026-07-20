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

// ページ系リクエストのみ処理する。通常のナビゲーション（navigate）に加え、
// Turbo Drive のページ遷移は fetch（mode: "cors"）になるため、同一オリジン
// かつ Accept: text/html の GET も対象にする。API（/api/v1、Accept: JSON）や
// 静的アセットは素通しにして、JWT 認証やアセット配信の挙動に影響を与えない。
const isPageRequest = (request) => {
  if (request.method !== "GET") return false
  if (request.mode === "navigate") return true

  const accept = request.headers.get("Accept") || ""
  return new URL(request.url).origin === self.location.origin && accept.includes("text/html")
}

self.addEventListener("fetch", (event) => {
  if (!isPageRequest(event.request)) return

  event.respondWith(
    fetch(event.request).catch(() => caches.match(OFFLINE_URL))
  )
})

// Web Push 通知を導入する場合はここに push / notificationclick の
// ハンドラを追加する（Rails 8 標準テンプレート参照）
