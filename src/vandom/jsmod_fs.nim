import jsffi
import js_utils

type
  FS* = JsObject

var fs* = require("fs", FS)