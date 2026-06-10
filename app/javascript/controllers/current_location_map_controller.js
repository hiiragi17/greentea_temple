import { Controller } from "@hotwired/stimulus"

const DEFAULT_CENTER = { lat: 34.985, lng: 135.758 }
const DEFAULT_ZOOM = 16

const CURRENT_MARKER_STYLE = {
  fillColor: "#008DBD",
  fillOpacity: 0.8,
  scale: 15,
  strokeColor: "#008DBD",
  strokeWeight: 1.0
}

const GREENTEA_MARKER_STYLE = {
  fillColor: "#007E66",
  fillOpacity: 0.8,
  scale: 15,
  strokeColor: "#007E66",
  strokeWeight: 1.0
}

const TEMPLE_MARKER_STYLE = {
  fillColor: "#E9546B",
  fillOpacity: 0.5,
  scale: 15,
  strokeColor: "#E9546B",
  strokeWeight: 1.0
}

let googleMapsLoader = null

function loadGoogleMaps(apiKey) {
  if (window.google && window.google.maps) {
    return Promise.resolve(window.google.maps)
  }
  if (googleMapsLoader) {
    return googleMapsLoader
  }

  googleMapsLoader = new Promise((resolve, reject) => {
    const callbackName = "__matchaInitGoogleMaps"
    window[callbackName] = () => {
      delete window[callbackName]
      resolve(window.google.maps)
    }
    const script = document.createElement("script")
    const params = new URLSearchParams({ key: apiKey, callback: callbackName, v: "3.exp" })
    script.src = `https://maps.googleapis.com/maps/api/js?${params.toString()}`
    script.async = true
    script.defer = true
    script.onerror = (error) => {
      googleMapsLoader = null
      reject(error)
    }
    document.head.appendChild(script)
  })

  return googleMapsLoader
}

export default class extends Controller {
  static values = {
    apiKey: String,
    greenteas: { type: Array, default: [] },
    temples: { type: Array, default: [] }
  }

  connect() {
    if (!this.apiKeyValue) return

    loadGoogleMaps(this.apiKeyValue)
      .then((maps) => this.initMap(maps))
      .catch((error) => console.error("Failed to load Google Maps", error))
  }

  initMap(maps) {
    const map = new maps.Map(this.element, {
      center: DEFAULT_CENTER,
      zoom: DEFAULT_ZOOM
    })

    this.placeSpots(maps, map, this.greenteasValue, GREENTEA_MARKER_STYLE, "茶", "/greenteas")
    this.placeSpots(maps, map, this.templesValue, TEMPLE_MARKER_STYLE, "神", "/temples")

    if (navigator.geolocation) {
      navigator.geolocation.getCurrentPosition((position) => {
        const latLng = new maps.LatLng(position.coords.latitude, position.coords.longitude)
        new maps.Marker({
          map,
          position: latLng,
          icon: { ...CURRENT_MARKER_STYLE, path: maps.SymbolPath.CIRCLE },
          label: { text: "現", color: "#FFFFFF", fontSize: "20px" }
        })
        map.setCenter(latLng)
      })
    }
  }

  placeSpots(maps, map, spots, markerStyle, labelText, urlPrefix) {
    spots.forEach((spot) => {
      const marker = new maps.Marker({
        map,
        position: { lat: Number(spot.latitude), lng: Number(spot.longitude) },
        icon: { ...markerStyle, path: maps.SymbolPath.CIRCLE },
        label: { text: labelText, color: "#FFFFFF", fontSize: "20px" }
      })

      const infoWindow = new maps.InfoWindow({
        content: `<a href="${urlPrefix}/${spot.id}">${spot.name}</a>`
      })

      marker.addListener("click", () => {
        infoWindow.open(map, marker)
      })
    })
  }
}
