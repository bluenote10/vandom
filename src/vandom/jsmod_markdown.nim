import jsffi
import js_utils

type
  Showdown* = JsObject

var showdown* = require("../node_modules/showdown/dist/showdown.js", Showdown)

proc newConverter*(showdown: Showdown): JsObject {.importcpp: "new #.Converter()".}
proc newConverter*(showdown: Showdown, options: JsObject): JsObject {.importcpp: "new #.Converter(#)".}

var defaultConverter = showdown.newConverter(JsObject{
  ghCodeBlocks: true,
  tasklists: true,
})

proc convertMarkdown*(t: cstring): cstring =
  defaultConverter.makeHtml(t).to(cstring)
