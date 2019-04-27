
import strformat
import sugar
import typetraits
import better_options

import oop_utils/standard_class

import dom
import dom_utils
import js_utils


# -----------------------------------------------------------------------------
# Context definition
# -----------------------------------------------------------------------------

type
  ElementProps* = ref object
    id: cstring
    tag: cstring
    classes: seq[cstring]
    attrs: seq[(cstring, cstring)]

let ep* = ElementProps()

proc getId*(ep: ElementProps): cstring =
  ep.id

proc getTag*(ep: ElementProps): cstring =
  ep.tag

proc getClasses*(ep: ElementProps): seq[cstring] =
  ep.classes

proc getAttrs*(ep: ElementProps): seq[(cstring, cstring)] =
  ep.attrs

proc getTagOrDefault*(ep: ElementProps, default: cstring): cstring =
  if ep.tag.isNil: default else: ep.tag

proc with*(
    ep: ElementProps,
    id: cstring = nil,
    tag: cstring = nil,
    classes: openarray[cstring] = [],
    attrs: openarray[(cstring, cstring)] = [],
  ): ElementProps =
  ElementProps(
    id: if id.isNil: ep.id else: id,
    tag: if tag.isNil: ep.tag else: tag,
    classes: if classes == []: ep.classes else: @classes,
    attrs: if attrs == []: ep.attrs else: @attrs,
  )

proc id*(ep: ElementProps, id: cstring): ElementProps =
  ElementProps(
    id: id,
    tag: ep.tag,
    classes: ep.classes,
    attrs: ep.attrs,
  )

proc tag*(ep: ElementProps, tag: cstring): ElementProps =
  ElementProps(
    id: ep.id,
    tag: tag,
    classes: ep.classes,
    attrs: ep.attrs,
  )

proc classes*(ep: ElementProps, classes: varargs[cstring]): ElementProps =
  ElementProps(
    id: ep.id,
    tag: ep.tag,
    classes: @classes,
    attrs: ep.attrs,
  )

proc attrs*(ep: ElementProps, attrs: varargs[(cstring, cstring)]): ElementProps =
  ElementProps(
    id: ep.id,
    tag: ep.tag,
    classes: ep.classes,
    attrs: @attrs,
  )

# -----------------------------------------------------------------------------
# Unit base class
# -----------------------------------------------------------------------------

class(Unit):
  ctor(newUnit) proc(node: DomNode) =
    self:
      domNode`+` = node

  method activate*() {.base.} = discard
  method deactivate*() {.base.} = discard
  method setFocus*() {.base.} = discard


# -----------------------------------------------------------------------------
# Helpers
# -----------------------------------------------------------------------------

proc getDomNodes*(children: openarray[Unit]): seq[DomNode] =
  result = newSeq[DomNode](children.len)
  for i in 0 ..< children.len:
    result[i] = children[i].domNode

# Missing in kdom?
proc createDocumentFragment*(d: Document): DomNode {.importcpp.}

proc getDomFragment(children: openarray[Unit]): DomNode =
  # https://coderwall.com/p/o9ws2g/why-you-should-always-append-dom-elements-using-documentfragments
  let fragment = document.createDocumentFragment()
  for child in children:
    fragment.appendChild(child.domNode)
  fragment


# -----------------------------------------------------------------------------
# TextNode
# -----------------------------------------------------------------------------

class(TextNode of Unit):
  ctor(textNode) proc(text: cstring) =
    let node = document.createTextNode(text)
    self:
      base(node)

  method setText*(text: cstring) {.base.} =
    self.domNode.nodeValue = text

# -----------------------------------------------------------------------------
# Dom elements
# -----------------------------------------------------------------------------

type
  DomEvent* = dom.Event
  DomKeyboardEvent* = dom.KeyboardEvent

  ClickCallback* = proc(e: DomEvent)
  InputCallback* = proc(e: DomEvent, s: cstring)
  KeydownCallback* = proc(e: DomKeyboardEvent)
  BlurCallback* = proc(e: DomEvent)

type
  EventHandlerBase = ref object of RootObj

  OnClick = ref object of EventHandlerBase
    dispatch: ClickCallback
  OnInput = ref object of EventHandlerBase
    dispatch: InputCallback
  OnKeydown = ref object of EventHandlerBase
    dispatch: KeydownCallback
  OnBlur = ref object of EventHandlerBase
    dispatch: BlurCallback


class(Element of Unit):
  ctor(newElement) proc(el: DomElement) =
    self:
      base(el)
      eventHandlers = newJDict[cstring, EventHandlerBase]()
      nativeHandlers = newJDict[cstring, EventHandler]()

  template domElement*(): DomElement =
    # From the constructor we know that self.domNode has to be type Element
    self.domNode.DomElement

  method setFocus*() =
    self.domElement.focus()

  method activate*() =
    echo &"activating with {self.eventHandlers.len} event handlers."
    for eventHandlerLoop in self.eventHandlers.values():
      closureScope:
        let eventHandler = eventHandlerLoop
        matchInstance:
          case eventHandler:
          of OnClick:
            proc onClick(e: Event) =
              eventHandler.dispatch(e)
            self.domElement.addEventListener("click", onClick)
            self.nativeHandlers["click"] = onClick
          of OnInput:
            proc onInput(e: Event) =
              eventHandler.dispatch(e, e.target.value)
            self.domElement.addEventListener("input", onInput)
            self.nativeHandlers["input"] = onInput
          of OnKeydown:
            proc onKeydown(e: Event) =
              eventHandler.dispatch(e.DomKeyboardEvent)
            self.domElement.addEventListener("keydown", onKeydown)
            self.nativeHandlers["keydown"] = onKeydown
          of OnBlur:
            proc onBlur(e: Event) =
              eventHandler.dispatch(e)
            self.domElement.addEventListener("blur", onBlur)
            self.nativeHandlers["blur"] = onBlur

  method deactivate*() =
    for nativeHandlerCode, nativeHandlerCallback in self.nativeHandlers:
      self.domElement.removeEventListener(nativeHandlerCode, nativeHandlerCallback)
    # clear references to old callbacks
    self.nativeHandlers = newJDict[cstring, EventHandler]()

  proc onClick*(cb: ClickCallback) =
    self.eventHandlers["click"] = OnClick(dispatch: cb)

  proc onInput*(cb: InputCallback) =
    self.eventHandlers["input"] = OnInput(dispatch: cb)

  proc onKeydown*(cb: KeydownCallback) =
    self.eventHandlers["keydown"] = OnKeydown(dispatch: cb)

  proc onBlur*(cb: BlurCallback) =
    self.eventHandlers["blur"] = OnBlur(dispatch: cb)

  proc getClassList*(): ClassList =
    self.domElement.classList

# -----------------------------------------------------------------------------
# Text
# -----------------------------------------------------------------------------

class(Text of Element):
  ctor(text) proc(ep: ElementProps, text: cstring) =
    let el = document.createElement(ep.getTagOrDefault("span"))

    self:
      base(el)
      textNode = document.createTextNode(text).DomNode

    self.domElement.appendChild(self.textNode)
    self.domElement.addClasses(ep.classes)

  method setText*(text: cstring) {.base.} =
    self.textNode.nodeValue = text

  method setInnerHtml*(text: cstring) {.base.} =
    # FIXME: This invalidates the reference to the textNode, so after
    # using setInnerHtml once, setText can no longer be used. Should
    # we have two kinds of text elements, one which wraps a text node
    # and one which offers the generic setInnerHtml? Currently this
    # is only for the element which holds the markdown HTML.
    self.domElement.innerHTML = text


# Alternative constructors
proc tdiv*(ep: ElementProps, text: cstring): Text =
  ep.with(tag="div").text(text)

proc span*(ep: ElementProps, text: cstring): Text =
  ep.with(tag="span").text(text)

proc h1*(ep: ElementProps, text: cstring): Text =
  ep.with(tag="h1").text(text)

proc h2*(ep: ElementProps, text: cstring): Text =
  ep.with(tag="h2").text(text)

proc h3*(ep: ElementProps, text: cstring): Text =
  ep.with(tag="h3").text(text)

proc h4*(ep: ElementProps, text: cstring): Text =
  ep.with(tag="h4").text(text)

proc h5*(ep: ElementProps, text: cstring): Text =
  ep.with(tag="h5").text(text)

proc h6*(ep: ElementProps, text: cstring): Text =
  ep.with(tag="h6").text(text)

proc li*(ep: ElementProps, text: cstring): Text =
  ep.with(tag="li").text(text)

proc a*(ep: ElementProps, text: cstring): Text =
  ep.with(tag="a").text(text)

proc i*(ep: ElementProps, text: cstring): Text =
  ep.with(tag="i").text(text)

proc p*(ep: ElementProps, text: cstring): Text =
  ep.with(tag="p").text(text)

# -----------------------------------------------------------------------------
# Button
# -----------------------------------------------------------------------------

type
  Button* = Element

proc button*(ep: ElementProps, text: cstring): Button =
  ## Constructor for simple text button.
  let el = h(ep.getTagOrDefault("button"),
    text = text,
    class = ep.classes,
    attrs = ep.attrs,
  )
  newElement(el)

proc button*(ep: ElementProps, children: openarray[Unit]): Button =
  ## Constructor for button with nested units.
  let el = h(ep.getTagOrDefault("button"),
    class = ep.classes,
    attrs = ep.attrs,
  )
  el.appendChild(getDomFragment(children))
  newElement(el)

# -----------------------------------------------------------------------------
# Input
# -----------------------------------------------------------------------------

class(Input of Element):
  ctor(newInput) proc(el: InputElement) =
    self:
      base(el)

  template domInputElement*(): InputElement =
    # From the constructor we know that self.domNode has to be type InputElement
    # FIXME to clarify: There there differences between:
    # - https://developer.mozilla.org/en-US/docs/Web/API/HTMLInputElement
    # - https://developer.mozilla.org/en-US/docs/Web/API/HTMLTextAreaElement
    # Maybe we should differentiate, but TextAreaElement is not in kdom...
    self.domNode.InputElement

  method setValue*(value: cstring) {.base.} =
    # setAttribute doesn't seem to work for textarea
    # self.domElement.setAttribute("value", value)
    self.domElement.value = value

  method setPlaceholder*(placeholder: cstring) {.base.} =
    self.domElement.setAttribute("placeholder", placeholder)


proc input*(ep: ElementProps, placeholder: cstring = "", text: cstring = ""): Input =
  # Merge ep.attrs with explicit parameters
  var attrs = ep.attrs
  attrs.add({
    "value".cstring: text,
    "placeholder".cstring: placeholder,
  })
  let el = h(ep.getTagOrDefault("input"),
    class = ep.classes,
    attrs = attrs,
  ).InputElement
  Input.init(el)

# -----------------------------------------------------------------------------
# Container
# -----------------------------------------------------------------------------

class(Container of Element):
  ctor(container) proc(ep: ElementProps, children: openarray[Unit]) =
    let el = h(ep.getTagOrDefault("div"),
      class = ep.classes,
      attrs = ep.attrs,
    )
    el.appendChild(getDomFragment(children))
    self:
      base(el)
      children = @children
      isActive = false

  method activate*() =
    self.isActive = true
    for child in self.children:
      child.activate()

  method deactivate*() =
    self.isActive = false
    for child in self.children:
      child.deactivate()


  proc insert*(index: int, newChild: Unit) =
    # Activate/Deactivate
    if self.isActive:
      newChild.activate()

    # Update self.children
    self.children.insert(newChild, index)

    # Update DOM
    let newDomNode = newChild.domNode
    # TODO: need to handle case where there is no elementAfter?
    let elementAfter =
      if self.domElement.childNodes.len > index:
        self.domElement.childNodes[index]
      else:
        nil
    self.domElement.insertBefore(newDomNode, elementAfter)

    doAssert self.children.len == self.domElement.childNodes.len


  proc append*(newChild: Unit) =
    # Activate/Deactivate
    if self.isActive:
      newChild.activate()

    # Update self.children
    self.children.add(newChild)

    # Update DOM
    let newDomNode = newChild.domNode
    self.domElement.insertBefore(newDomNode, nil)

    doAssert self.children.len == self.domElement.childNodes.len


  proc remove*(index: int) =
    # TODO: OOB check

    # Activate/Deactivate
    if self.isActive:
      self.children[index].deactivate()

    # Update self.children
    self.children.delete(index)

    # Update DOM
    let nodeToRemove = self.domElement.childNodes[index]
    self.domElement.removeChild(nodeToRemove)

    doAssert self.children.len == self.domElement.childNodes.len


  proc clear*() =
    # Activate/Deactivate
    if self.isActive:
      for child in self.children:
        child.deactivate()

    # Update self.children
    self.children.setLen(0)

    # Update DOM
    let oldDisplay = self.domElement.style.display
    self.domElement.style.display = "none"
    self.domElement.removeAllChildren()
    self.domElement.style.display = oldDisplay

    doAssert self.children.len == self.domElement.childNodes.len


  proc replaceChildren*(newChildren: openarray[Unit]) =
    ## Performs a clear + inserts in an optimized way.

    # Activate/Deactivate
    if self.isActive:
      for child in self.children:
        child.deactivate()
      for child in newChildren:
        child.activate()

    # Update self.children
    self.children = @newChildren

    # Update DOM
    let oldDisplay = self.domElement.style.display
    self.domElement.style.display = "none"
    self.domElement.removeAllChildren()
    self.domElement.appendChild(getDomFragment(newChildren))
    self.domElement.style.display = oldDisplay

    doAssert self.children.len == self.domElement.childNodes.len


  proc getChildren*(): seq[Unit] =
    self.children


iterator items*(c: Container): Unit =
  for child in c.getChildren():
    yield child


iterator pairs*(c: Container): (int, Unit) =
  for i, child in c.getChildren():
    yield (i, child)


class(Widget of Element):
  ctor(newWidget) proc(element: Element) =
    self:
      base(element.domElement)
      element

  method activate*() =
    echo &"activating widget: {name(type(self))}"
    self.element.activate()

  method deactivate*() =
    echo &"deactivating widget {name(type(self))}"
    self.element.deactivate()
