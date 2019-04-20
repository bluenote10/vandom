import times
import sequtils
import sugar
import better_options

import oop_utils/standard_class

import karax/kdom except class
import ui_units
import ui_dsl

import store

import dom_utils
import js_markdown
import jstr_utils
import js_utils

# -----------------------------------------------------------------------------
# Types
# -----------------------------------------------------------------------------

type
  WidgetLabeltreeUnits* = ref object
    main*: Container
    renderLabel*: proc(name: cstring, count: int): Unit

#[
  WidgetLabeltree* = ref object of Unit
    units: WidgetLabeltreeUnits
]#

# -----------------------------------------------------------------------------
# Public methods
# -----------------------------------------------------------------------------

class(WidgetLabeltree of Widget):

  ctor(widgetLabelTree) proc (ui: UiContext) =
    let units = WidgetLabeltreeUnits()
    uiDefs: discard
      ui.container([]) as units.main
    units.renderLabel = proc(name: cstring, count: int): Unit =
      uiDefs:
        ui.container([
          ui.classes("tag", "is-dark").span(name & " (" & $count & ")")
        ])

    self:
      base(units.main)
      units


  method setLabels*(labelsDict: JDict[cstring, int]) {.base.} =
    let labelNames = labelsDict.keys()
    self.units.main.replaceChildren(
      labelsDict.items().map(
        kv => self.units.renderLabel(kv[0], kv[1])
      )
    )

