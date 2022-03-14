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


    map.on("load", () => {

      addH3Source(map, 'test-source', 'test-layer', 5, 24)
    
      map.addLayer({
        "id": 'test-layer',
        "type": 'fill',
        "source": 'test-source',
        "source-layer": 'test-layer',
        "paint": {
          "fill-color": {
            "property": 'value',
            "stops": [
              [1,"#fdc7b7"],
              [2,"#fe9699"],
              [3,"#f16580"],
              [4,"#d9316c"],
              [5,"#a71f65"],
              [6,"#760e5d"],
              [7,"#430254"]
            ]
            },
          "fill-opacity": 0.25,
        }
      })
    })
  }
}

export default maphook