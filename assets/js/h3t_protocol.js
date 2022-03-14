import maplibregl from "maplibre-gl"
import {h3ToGeoBoundary} from "h3-js"
import geojsonvt from "geojson-vt"
import vtpbf from "vt-pbf"

addH3Source = function(map, source_name, layer_name,  minzoom, maxzoom){
    const lname =  layer_name
    const mz = maxzoom
    h3Protocol = (params, callback) => {
      splitted_url = params.url.split(/\/|\./i)
      l = splitted_url.length
      let tileIndex = splitted_url.slice(l - 3, l - 0).map(k => k * 1)
      console.log(tileIndex)
      fetch(`http://${params.url.split("://")[1]}`).then(response => {
          if (response.status == 200) {
            return response.json()
          } else {
            callback(new Error(`Tile fetch error: ${t.statusText}`));
          }
        }).then((content) => {
          features = content.cells.map((cell) => {
            return {
              "id": cell.id,
              "properties": cell,
              "geometry": {
                "type": "Polygon",
                "coordinates": [h3ToGeoBoundary(cell.h3id, true)]
              }
            }
          });
          featCol = {"type": "FeatureCollection", "features": features}
          tile = geojsonvt(featCol, {maxZoom: mz}).getTile(...tileIndex)
          if (tile == null){
            callback(new Error("No data"))
          } else {
            til = {}
            til[lname] = tile
            pbf = vtpbf.fromGeojsonVt(til, { "version": 2 })
            callback(null, pbf, null, null);
          }
        }).catch(e => {
          callback(new Error(e));
        });
      return { cancel: () => { } };
    }
  

  maplibregl.addProtocol("h3tiles", h3Protocol)
  map.addSource(source_name,
    {
      "type": 'vector', 
      "format": 'pbf',
      "tiles": ['h3tiles://localhost:4000/api/tiles/hexas/h3t/{z}/{x}/{y}'],
      "minzoom": minzoom,
      "maxzoom": maxzoom,
    }
  )

}



export default addH3Source;
