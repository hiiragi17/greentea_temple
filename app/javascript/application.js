// Entry point for the build script in your package.json
import "@hotwired/turbo-rails"
import "./controllers"

// PWA: Service Worker を登録する（app/views/pwa/service-worker.js を配信）
if ("serviceWorker" in navigator) {
  window.addEventListener("load", () => {
    navigator.serviceWorker.register("/service-worker.js").catch((error) => {
      console.error("Service Worker registration failed:", error)
    })
  })
}
