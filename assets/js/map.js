import maplibregl from "maplibre-gl"
import addH3Source from "./h3t_protocol"

getHostUrl = () => {
  if (window.host.startsWith("https")) {
    return [true, window.host.replace("https://", "")]
  } else {
    return [false, window.host.replace("http://", "")]
  }
}

maphook = {
  userLocation: null,
  mounted(){
    if (navigator.geolocation) {
      navigator.geolocation.getCurrentPosition(
        (position) => this.initMap([position.coords.longitude, position.coords.latitude]),
        (error) => this.initMap([-5.9689314894430465, 37.3281967598058])
      )
    } else {
      this.initMap([-5.9689314894430465, 37.3281967598058])
    }
  },
  initMap(current_location){
    
    map = new maplibregl.Map({
      "container": 'map',
      "style": 'https://basemaps.cartocdn.com/gl/positron-gl-style/style.json',
      "center": current_location,
      "zoom": 16,
      "minZoom": 0,
      "maxZoom": 21,
      "antialias": true
    })

    map.addControl(
      new maplibregl.GeolocateControl({
        positionOptions: {
          enableHighAccuracy: true
        },
        trackUserLocation: true
      })
    );

    map.on("click", (e) => {
      var features = map.queryRenderedFeatures(e.point);
      if (features){
        var properties = 
          features.filter((feature) => feature.sourceLayer == "h3-layer")
          .map((feature) => feature.properties)
          .filter((property) => property.has_image)
        this.pushEvent("map-clicked", properties)
      }
    })


    map.on("load", () => {

      [https, host_url] = getHostUrl()
      console.log(host_url)
      addH3Source(map, 'h3-source', 'h3-layer', 5, 24, `h3tiles://${host_url}/api/tiles/hexas/h3t/{z}/{x}/{y}`, https)
    
      map.addLayer({
        "id": 'h3-layer',
        "type": 'fill',
        "source": 'h3-source',
        "source-layer": 'h3-layer',
        "paint": {
          "fill-color": {
            "property": 'has_image',
            "stops": [
              [0,"rgba(0, 0, 0, 0)"],
              [1,"#a71f65"]
            ]
            },
          "fill-opacity": 0.25,
          "fill-outline-color": "#000000"
        }
      })
    })

    this.setupLocationWatch()
  },
  setupLocationWatch() {
    if (navigator.geolocation) {
      navigator.geolocation.watchPosition((position) => {
        this.userLocation = {lat: position.coords.latitude, lon: position.coords.longitude}
        this.pushEvent("user-location", this.userLocation)
      });
    } 
  }
}

export default maphook