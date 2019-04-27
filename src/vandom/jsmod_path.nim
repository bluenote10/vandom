import jsffi
import js_utils

type
  PathModule* = JsObject

var path* = require("path", PathModule)

proc dirname*(pathMod: PathModule, path: cstring): cstring {.importcpp: "#.dirname(#)".}

proc basename*(pathMod: PathModule, path: cstring): cstring {.importcpp: "#.basename(#)".}

#proc join*(pathMod: PathModule, paths: varargs[cstring]): cstring {.importcpp: "#.join(@)".}
proc join*(pathMod: PathModule, p1: cstring): cstring {.importcpp: "#.join(#)".}
proc join*(pathMod: PathModule, p1, p2: cstring): cstring {.importcpp: "#.join(#, #)".}
proc join*(pathMod: PathModule, p1, p2, p3: cstring): cstring {.importcpp: "#.join(#, #, #)".}
