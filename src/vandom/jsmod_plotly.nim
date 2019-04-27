import jsffi
import js_utils

type
  Plotly* = JsObject

#var plotly* = requireWithCall("plotly", Plotly)

var plotly* {.importc: "Plotly", nodecl.} : Plotly


debug(plotly)
