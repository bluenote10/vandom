import jsffi
import js_utils

type
  Axios* = JsObject

when defined(nodejs):
  var axios* = require("axios", Axios)
else:
  #var axios* {.importc: "axios", nodecl.} : Axios
  var axios* = requireBrowser("axios", Axios)
  debug("Axios:", axios)
validateModule(axios)

proc catch*(obj: JsObject, f: proc(obj: JsObject)): JsObject {.importcpp, nodecl.}

# debug(axios)
