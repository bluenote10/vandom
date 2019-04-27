# -----------------------------------------------------------------------------
#
# Module inspired by Karax with a few modifications
#
# -----------------------------------------------------------------------------

#[
Note for browser support: Should we use staticRead on something like

    node -e 'console.log(require.resolve("mousetrap"))'

to resolve node module paths at compile time and embed them into the
resulting JS file?
]#

proc require*(lib: cstring, T: typedesc): T {.importcpp: """require(#)""".}

proc debug*[T](x: T) {.importc: "console.log", varargs.}

proc isNil[T](a: openarray[T]): bool {.importcpp: "(# === null)"}


# -----------------------------------------------------------------------------
# Native string utils
# -----------------------------------------------------------------------------

proc split*(s, sep: cstring): seq[cstring] {.importcpp, nodecl.}

proc split*(s, sep: cstring; max: int): seq[cstring] {.importcpp, nodecl.}

proc strip*(s: cstring): cstring {.importcpp: "#.trim()", nodecl.}

proc startsWith*(a, b: cstring): bool {.importcpp: "startsWith", nodecl.}
proc contains*(a, b: cstring): bool {.importcpp: "(#.indexOf(#)>=0)", nodecl.}

proc containsIgnoreCase*(a, b: cstring): bool {.
  importcpp: """(#.search(new RegExp(#.replace(/[\-\[\]\/\{\}\(\)\*\+\?\.\\\^\$$\|]/g, "\\$$&") , "i"))>=0)""", nodecl.}

proc substr*(s: cstring; start: int): cstring {.importcpp: "substr", nodecl.}
proc substr*(s: cstring; start, length: int): cstring {.importcpp: "substr", nodecl.}

proc replace*(s, a, b: cstring): cstring {.importcpp: "#.replace(#, #)", nodecl.}

proc toLowerCase*(s: cstring): cstring {.importcpp: "#.toLowerCase()", nodecl.}
proc toUpperCase*(s: cstring): cstring {.importcpp: "#.toUpperCase()", nodecl.}

#proc len*(s: cstring): int {.importcpp: "#.length", nodecl.}
proc `&`*(a, b: cstring): cstring {.importcpp: "(# + #)", nodecl.}
proc toCstr*(s: int): cstring {.importcpp: "((#)+'')", nodecl.}
proc `&`*(s: int): cstring {.importcpp: "((#)+'')", nodecl.}
proc `&`*(s: bool): cstring {.importcpp: "((#)+'')", nodecl.}
proc `&`*(s: float): cstring {.importcpp: "((#)+'')", nodecl.}

proc `&`*(s: cstring): cstring {.importcpp: "(#)", nodecl.}

proc isInt*(s: cstring): bool {.asmNoStackFrame.} =
  asm """
    return `s`.match(/^[0-9]+$/);
  """

proc parseInt*(s: cstring): int {.importcpp: "parseInt(#, 10)", nodecl.}
proc parseFloat*(s: cstring): BiggestFloat {.importc, nodecl.}


proc joinImpl*(a: openArray[cstring]; sep: cstring = ""): cstring {.importcpp: "#.join(#)".}

proc join*(a: openArray[cstring]; sep: cstring = ""): cstring =
  if a.isNil:
    "".cstring
  else:
    joinImpl(a, sep)

# -----------------------------------------------------------------------------
# JDict
# -----------------------------------------------------------------------------

type
  JDict*[K, V] = ref object

proc `[]`*[K, V](d: JDict[K, V], k: K): V {.importcpp: "#[#]".}
proc `[]=`*[K, V](d: JDict[K, V], k: K, v: V) {.importcpp: "#[#] = #".}

proc newJDict*[K, V](): JDict[K, V] {.importcpp: "{@}".}

proc len*[K, V](d: JDict[K, V]): int {.importcpp: "Object.keys(#).length".}

proc contains*[K, V](d: JDict[K, V], k: K): bool {.importcpp: "#.hasOwnProperty(#)".}

proc del*[K, V](d: JDict[K, V], k: K) {.importcpp: "delete #[#]".}

iterator items*[K, V](d: JDict[K, V]): K =
  var kkk: K
  {.emit: ["for (", kkk, " in ", d, ") {"].}
  yield kkk
  {.emit: ["}"].}

iterator pairs*[K, V](d: JDict[K, V]): (K, V) =
  var kkk: K
  var vvv: V
  {.emit: ["for (", kkk, " in ", d, ") {"].}
  {.emit: [vvv, " = ", d[kkk]].}
  yield (kkk, vvv)
  {.emit: ["}"].}

proc keys*[K, V](d: JDict[K, V]): seq[K] {.importcpp: "Object.keys(#)".}

proc values*[K, V](d: JDict[K, V]): seq[V] {.importcpp: "Object.values(#)".}

proc items*[K, V](d: JDict[K, V]): seq[(K, V)] =
  result = newSeq[(K, V)]()
  for k in d:
    result.add((k, d[k]))

#[
proc values*[K, V](d: JDict[K, V]): seq[V] =
  # TODO: This could be optimized
  result = newSeq[V]()
  for k, v in d.pairs:
    result.add(v)
]#

# TODO: How to solve this?
# proc `toJSStr`*[K, V](d: JDict[K, V]): cstring = cstring"asdf"
# proc `$`*[K, V](d: JDict[K, V]): cstring = toJSStr(d)

# -----------------------------------------------------------------------------
# JSeq
# -----------------------------------------------------------------------------

type
  JSeq*[T] = ref object

proc `[]`*[T](s: JSeq[T], i: int): T {.importcpp: "#[#]", noSideEffect.}
proc `[]=`*[T](s: JSeq[T], i: int, v: T) {.importcpp: "#[#] = #", noSideEffect.}

proc newJSeq*[T](len: int = 0): JSeq[T] {.importcpp: "new Array(#)".}
proc len*[T](s: JSeq[T]): int {.importcpp: "#.length", noSideEffect.}
proc add*[T](s: JSeq[T]; x: T) {.importcpp: "#.push(#)", noSideEffect.}

proc shrink*[T](s: JSeq[T]; shorterLen: int) {.importcpp: "#.length = #", noSideEffect.}

# -----------------------------------------------------------------------------
# seq JS extensions (use with care, violate seq semantics)
# -----------------------------------------------------------------------------

proc sortJS*[T](s: seq[T]): seq[T] {.importcpp: "#.sort()".}
proc sortJS*[T](s: seq[T], compare: proc(a: T, b: T): int): seq[T] {.importcpp: "#.sort(#)".}

