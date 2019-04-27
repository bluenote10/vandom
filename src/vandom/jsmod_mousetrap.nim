import jsffi
import js_utils

type
  Mousetrap* = JsObject

var mousetrap* = require("mousetrap", Mousetrap)

proc bindKey*(mousetrap: Mousetrap, pattern: cstring, callback: proc()) {.importcpp: "#.bind(#, #)".}
proc bindKey*(mousetrap: Mousetrap, pattern: openarray[cstring], callback: proc()) {.importcpp: "#.bind(#, #)".}

# https://stackoverflow.com/questions/21013866/mousetrap-bind-is-not-working-when-field-is-in-focus
proc fixInputFocus() =
  asm """
  `mousetrap`.prototype.stopCallback = function () {
      return false;
  }
  """

fixInputFocus()