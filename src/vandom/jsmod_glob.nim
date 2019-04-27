import jsffi
import js_utils

import jsmod_fs

type
  Glob* = JsObject

var glob* = require("glob", Glob)
