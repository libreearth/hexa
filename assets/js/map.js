import maplibregl from "maplibre-gl"
import addH3Source from "./h3t_protocol"
import _ from "lodash"
import {geoToH3, kRing, h3ToGeoBoundary, h3Distance } from "h3-js";

getHostUrl = () => {
  if (window.host.startsWith("https")) {
    return [true, window.host.replace("https://", "")]
  } else {
    return [false, window.host.replace("http://", "")]
  }
}

maphook = {
  userLocation: null,
  map: null,
  mounted(){
    if (navigator.geolocation) {
      navigator.geolocation.getCurrentPosition(
        (position) => this.initMap([position.coords.longitude, position.coords.latitude]),
        (error) => this.initMap([-5.9689314894430465, 37.3281967598058])
      )
    } else {
      this.initMap([-5.9689314894430465, 37.3281967598058])
    }
    this.handleEvent("reload-map", ({}) => this.reloadMap())
  },
  initMap(current_location){
    
    var map = new maplibregl.Map({
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
    )

    map.on("click", (e) => {
      var features = map.queryRenderedFeatures(e.point);
      if (features){
        var properties = 
          features.filter((feature) => feature.sourceLayer == "h3-layer")
          .map((feature) => feature.properties)
          .filter((property) => property.has_image)
        if (properties.length == 0){
          this.pushEvent("map-clicked", {"lat": e.lngLat.lat, "lon": e.lngLat.lng})
        } else {
          this.pushEvent("map-clicked", properties)
        }
      } 
    })


    map.on("load", () => {

      //add the h3t layer
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

      //add a geojson layer 
      map.addSource('location-hexas', {
        type: 'geojson',
        data: {
          "type": "FeatureCollection",
          "features": []
        }
      })

      map.addLayer({
        'id': 'location-hexas-layer',
        'type': 'fill',
        'source': 'location-hexas',
        'layout': {},
        'paint': {
          'fill-color': '#00F',
          'fill-opacity': [
            "interpolate",
            ["linear"],
            ["get", "distance"],
            0,1,
            12,0.1
          ]
        }
      })

      this.map = map

    })

    this.setupLocationWatch()
  },
  setupLocationWatch() {
    if (navigator.geolocation) {
      navigator.geolocation.watchPosition((position) => {
        this.userLocation = {lat: position.coords.latitude, lon: position.coords.longitude}
        this.showNearestHexas(this.userLocation)
        this.pushEvent("user-location", this.userLocation)
      });
    } 
  },
  showNearestHexas(position) {
    data = {
      "type": "FeatureCollection",
      "features": []
    }

    center = geoToH3(position.lat, position.lon, window.h3_level)
    ringHexas = kRing(center, 12)
    data.features = _.map(ringHexas, (h3Index) => this.h3IndexToFeature(h3Index, center))
    this.map.getSource('location-hexas').setData(data)
  },
  h3IndexToFeature(h3Index, h3Center) {
    coords = h3ToGeoBoundary(h3Index)
    return {
      "type": "Feature",
      "geometry": {
        "type": "Polygon",
        "coordinates": [
          _.map(coords, ([lat, lon]) => [lon, lat])
        ]
      },
      "properties": {
        "distance": h3Distance(h3Index, h3Center)
      }
    }
  },
  reloadMap(){
    if (this.map){
      this.map.getSource('h3-source').load()
    }
  }
}

export default maphook
