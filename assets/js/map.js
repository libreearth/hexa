import maplibregl from "maplibre-gl"
import addH3Source from "./h3t_protocol"


maphook = {
  mounted(){
    
    map = new maplibregl.Map({
      "container": 'map',
      "style": 'https://basemaps.cartocdn.com/gl/positron-gl-style/style.json',
      "center": [-5.9689314894430465, 37.3281967598058],
      "zoom": 16,
      "minZoom": 0,
      "maxZoom": 21,
      "antialias": true
    })

    map.on("click", (e) => {
      var features = map.queryRenderedFeatures(e.point);
      console.log(features)
    })


    map.on("load", () => {

      addH3Source(map, 'h3-source', 'h3-layer', 5, 24)
    
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
  }
}

export default maphook