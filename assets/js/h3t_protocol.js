import maplibregl from "maplibre-gl"
import {h3ToGeoBoundary} from "h3-js"
import geojsonvt from "geojson-vt"
import vtpbf from "vt-pbf"

addH3Source = function(map, source_name, layer_name,  minzoom, maxzoom, tile_call, uses_https){
    const lname =  layer_name
    const mz = maxzoom
    const https = uses_https
    h3Protocol = (params, callback) => {
      let splitted_url = params.url.split(/\/|\./i)
      let l = splitted_url.length
      let tileIndex = splitted_url.slice(l - 3, l - 0).map(k => k * 1)
      let url = null
      if (https)  
        url = `https://${params.url.split("://")[1]}`
      else
        url = `http://${params.url.split("://")[1]}`
      fetch(url).then(response => {
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
      "tiles": [tile_call],
      "minzoom": minzoom,
      "maxzoom": maxzoom,
    }
  )

}



export default addH3Source;
