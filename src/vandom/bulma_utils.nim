import units
import dsl

# Bulma helpers
proc field*(ep: ElementProps, units: openarray[Unit]): Container =
  unitDefs:
    ep.classes("field", "has-margin-top").container(units)
    #ep.classes("field", "has-margin-top", "is-horizontal").container(units)

proc label*(ep: ElementProps, text: cstring): Text =
  unitDefs:
    ep.tag("label").classes("label", "is-small").text(text)

proc control*(ep: ElementProps, units: openarray[Unit]): Container =
  unitDefs:
    ep.classes("control").container(units)

#[
proc fieldLabel*(ep: ElementProps, text: cstring): Container =
  unitDefs:
    ep.classes("field-label").container([
      ep.tag("label").classes("label").text(text)
    ])

proc fieldBody*(ep: ElementProps, units: openarray[Unit]): Container =
  unitDefs:
    ep.classes("field-body").container(units)

]#
