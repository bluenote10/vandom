import jsffi
import js_utils

type
  Leaflet* = JsObject

#var plotly* = requireWithCall("plotly", Leaftlet)

var leaflet* {.importc: "L", nodecl.} : Leaflet


debug(leaflet)
