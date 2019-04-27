import vandom
import vandom/dom


proc run(unit: Unit) =
  echo "Mounting main unit"
  unit.activate()
  let node = unit.domNode
  let root = document.getElementById("ROOT")
  root.appendChild(node)
  unit.setFocus()


unitDefs:
  var button: Element
  var input: Input
  let mainUnit = ep.container([
    ep.tag("div").text("Hello world"),
    textNode("TextNode"),
    ep.tag("div").text("Hello world"),
    ep.button("Button") as button,
    ep.input("Input") as input,
  ])

  button.onClick() do (e: DomEvent):
    echo "clicked"

  input.onInput() do (e: DomEvent, s: cstring):
    echo "input:", s

  input.onKeydown() do (e: KeyboardEvent):
    echo "keypress"

  input.onBlur() do (e: DomEvent):
    echo "blur"

run(mainUnit)
