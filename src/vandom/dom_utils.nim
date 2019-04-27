#include karax/prelude

import karax/kdom
import karax/jstrutils
import karax/jdict
import karax/karax # for kout -- TODO move to own utils
import strformat
import jsffi
import sugar


proc setInterval*(ms: int, action: proc()): ref Interval =
  ## setInterval overload with arguments switched for nicer syntax
  window.setInterval(action, ms)


proc setTimeout*(ms: int, action: proc()): Timeout =
  ## setTimeout overload with arguments switched for nicer syntax
  setTimeout(action, ms)


proc appendChildren*(el: Element, children: seq[Node]) =
  for child in children:
    el.appendChild(child)

proc addClasses*(el: Element, class: openarray[cstring]) =
  for c in class:
    el.classList.add(c)


proc removeAllChildren*(el: Element) =
  # Lots of discussion/confusion about the most efficient way to remove
  # all elements at once:
  # - https://stackoverflow.com/questions/3955229/remove-all-child-elements-of-a-dom-node-in-javascript
  # Using node.innerHTML = '' looks atomic, but apparently it is slower
  # than iterating and using removeChild (I'm wondering if the benchmarks
  # properly account for reflow/redraws, this could change the results
  # entirely).
  # According to https://jsperf.com/innerhtml-vs-removechild/457 the fastest
  # solution is to use firstChild, but make sure there is only one call
  # to firstChild per iteration.
  var child: Node
  while true:
    child = el.firstChild
    if child.isNil:
      break
    el.removeChild(child)


type
  # Somehow missing in kdom
  EventHandler* = proc(ev: Event)


proc textNode*(text: cstring): Node =
  document.createTextNode(text)


proc h*(
    tagName: cstring,
    id: cstring = "",
    class: openarray[cstring] = @[],
    attrs: openarray[(cstring, cstring)] = [],
    events: openarray[(cstring, EventHandler)] = [],
    #children: openarray[Node] = @[],
    text="".cstring): Element =

  var element = document.createElement(tagName)

  #for child in children:
  #  element.appendChild(child)

  if text.len > 0:
    var textnode = document.createTextNode(text)
    element.appendChild(textnode)

  for c in class:
    element.classList.add(c)

  for attr in attrs:
    element.setAttribute(attr[0], attr[1])

  for kv in events:
    let (k, v) = kv
    element.addEventListener(k, v)

  return element


proc onclick*(handler: proc (e: Event)): (cstring, EventHandler) =
  # Making this a template results in illformed AST, why?
  ("click".cstring, EventHandler(handler))

proc oninput*(handler: proc (e: Event)): (cstring, EventHandler) =
  # Making this a template results in illformed AST, why?
  ("input".cstring, EventHandler(handler))
