import jsffi
import js_utils

type
  Axios* = JsObject

when defined(nodejs):
  var axios* = require("axios", Axios)
else:
  var axios* {.importc: "axios", nodecl.} : Axios

proc catch*(obj: JsObject, f: proc(obj: JsObject)): JsObject {.importcpp, nodecl.}

# debug(axios)
