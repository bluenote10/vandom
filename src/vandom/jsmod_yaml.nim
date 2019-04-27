import jsffi
import js_utils

import jsmod_fs

type
  Yaml* = JsObject

var yaml* = require("js-yaml", Yaml)


#var doc = yaml.safeLoad(fs.readFileSync('/home/ixti/example.yml', 'utf8'))

#var yamlStr = yaml.safeDump(JsObject{test: "value".cstring}).to(cstring)
#echo yamlStr

#fs.writeFileSync("test.yaml", yamlStr)