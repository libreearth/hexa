import "aframe"

arhook = {
  mounted() {
    var aSceneEl = document.createElement("a-scene")
    aSceneEl.setAttribute("embedded", true)

    var boxEl = document.createElement("a-box")
    boxEl.setAttribute("position", "-1 0.5 -3")
    boxEl.setAttribute("rotation", "0 45 0")
    boxEl.setAttribute("color", "#4CC3D9")
    aSceneEl.appendChild(boxEl)

    var arEl = document.querySelector("#ar-frame")
    arEl.appendChild(aSceneEl)
  }
}

export default arhook;