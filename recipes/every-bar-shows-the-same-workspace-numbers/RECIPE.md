---
{
  "id": "duff/every-bar-shows-the-same-workspace-numbers",
  "title": "Every display's bar shows the same workspace numbers",
  "summary": "Clone the workspaces widget so each bar lists only its own screen's workspaces.",
  "version": 1,
  "tested_on": {"omarchy": "4.0.4", "hyprland": "0.56.2"},
  "applies_to": "Multi-monitor setups that pin workspaces to screens.",
  "requires": [{"monitors": 2}],
  "touches": ["~/.config/omarchy/plugins/<username>.workspaces/", "~/.config/omarchy/shell.json"],
  "root": false,
  "network": false,
  "installs": [],
  "runs": ["the cloned workspaces bar widget, which reads the rules with hyprctl"],
  "agent_config": false,
  "history": [{"who": "duff", "did": "created", "date": "2026-10-01"}]
}
---

# Every display's bar shows the same workspace numbers

## Problem

Once each screen has its own block of workspaces (see
[Workspaces open on unpredictable monitors](../workspaces-open-on-the-wrong-monitor/RECIPE.md)),
the bar on every screen still lists the same numbers: 1 to 5, plus any other
workspace that exists. The bar on the right screen shows 1 to 5 even though
only 7, 8, and 9 can ever appear there, and it doesn't show which of its own
workspaces is on screen.

## Why it happens

The stock workspaces widget (`omarchy.workspaces`, in
`/usr/share/omarchy/shell/plugins/bar/widgets/Workspaces.qml`) lists the same
workspaces on every bar. It doesn't read Hyprland's workspace rules, so it has
no idea which numbers belong to which screen.

## Fix

Clone the stock widget into your own config and have it read the rules.

```bash
omarchy plugin clone omarchy.workspaces
```

That copies the widget to `~/.config/omarchy/plugins/<username>.workspaces/`
and switches the bar to the clone. Replace the clone's `Workspaces.qml` with
the version below. Keep the `moduleName` the clone wrote, which is your own
plugin id.

Each bar lists only the workspaces whose rules name its screen. The one the
screen is showing gets a square marker: filled on the focused screen, outlined
on the others. Empty workspaces are dimmed. A screen with no rules, or a
machine with none at all, gets the stock list.

```qml
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import qs.Commons
import qs.Ui

// Each display's bar lists only the workspaces Hyprland's workspace rules pin
// to that display (~/.config/hypr/monitors.lua), and marks the one it is
// showing: filled on the focused display, outlined on the others. A display
// with no pinned workspaces (or a machine with no rules) falls back to the
// stock list: 1-5 plus any other workspace up to 10 that exists.
BarWidget {
  id: root
  moduleName: "yourname.workspaces"

  readonly property string filledMarker: "󱓻"   // md-square-rounded
  readonly property string outlineMarker: "󱓼"  // md-square-rounded-outline

  // [{ id, monitor }] from `hyprctl workspacerules -j`, numbered workspaces only.
  property var rules: []

  readonly property var screen: root.QsWindow.window ? root.QsWindow.window.screen : null
  readonly property var monitor: root.screen ? Hyprland.monitorFor(root.screen) : null

  function workspaceById(id) {
    var values = Hyprland.workspaces.values
    for (var i = 0; i < values.length; i++) {
      if (values[i].id === id) return values[i]
    }

    return null
  }

  // A rule names a monitor by output ("eDP-1") or by "desc:<description>".
  function ruleMatches(rule, monitor) {
    if (!monitor) return false
    if (rule.monitor === monitor.name) return true
    if (rule.monitor.indexOf("desc:") !== 0) return false
    return String(monitor.description || "").indexOf(rule.monitor.slice(5)) === 0
  }

  function pinnedIds() {
    var ids = []
    for (var i = 0; i < root.rules.length; i++) {
      if (root.ruleMatches(root.rules[i], root.monitor)) ids.push(root.rules[i].id)
    }
    return ids
  }

  function stockIds() {
    var ids = [1, 2, 3, 4, 5]
    var values = Hyprland.workspaces.values

    for (var i = 0; i < values.length; i++) {
      var id = values[i].id
      if (id > 0 && id <= 10 && ids.indexOf(id) === -1) ids.push(id)
    }

    return ids
  }

  function workspaceIds() {
    var ids = root.pinnedIds()
    if (ids.length === 0) ids = root.stockIds()
    ids.sort(function(left, right) { return left - right })
    return ids
  }

  // Which display (if any) is showing this workspace right now.
  function showingMonitor(id) {
    var monitors = Hyprland.monitors.values
    for (var i = 0; i < monitors.length; i++) {
      var active = monitors[i].activeWorkspace
      if (active && active.id === id) return monitors[i]
    }
    return null
  }

  function focusWorkspace(id) {
    if (!root.bar) return
    root.bar.run("hyprctl dispatch " + Util.shellQuote("hl.dsp.focus({ workspace = \"" + id + "\" })"))
  }

  function loadRules() {
    if (!rulesProc.running) rulesProc.running = true
  }

  Component.onCompleted: loadRules()

  Connections {
    target: Hyprland
    // Rules change when monitors.lua is edited (config reload) or a display
    // is plugged in.
    function onRawEvent(event) {
      if (event.name === "configreloaded" || event.name === "monitoraddedv2" || event.name === "monitorremovedv2")
        root.loadRules()
    }
  }

  Process {
    id: rulesProc
    command: ["hyprctl", "workspacerules", "-j"]
    stdout: StdioCollector {
      onStreamFinished: {
        var parsed = []
        try {
          var list = JSON.parse(this.text)
          for (var i = 0; i < list.length; i++) {
            var id = parseInt(list[i].workspaceString, 10)
            if (String(id) === list[i].workspaceString && id > 0 && list[i].monitor)
              parsed.push({ id: id, monitor: String(list[i].monitor) })
          }
        } catch (e) {}
        root.rules = parsed
      }
    }
  }

  readonly property real trailingGap: root.vertical ? 0 : Style.spaceReal(1.5)

  implicitWidth: grid.implicitWidth + trailingGap
  implicitHeight: grid.implicitHeight

  GridLayout {
    id: grid
    anchors.fill: parent
    anchors.rightMargin: root.trailingGap
    columns: root.vertical ? 1 : root.workspaceIds().length
    columnSpacing: root.vertical ? 0 : Style.space(1)
    rowSpacing: root.vertical ? Style.space(2) : 0

    Repeater {
      model: root.workspaceIds()

      WidgetButton {
        required property int modelData

        readonly property var workspace: root.workspaceById(modelData)
        readonly property bool occupied: workspace !== null && workspace.toplevels.values.length > 0
        readonly property var shownOn: root.showingMonitor(modelData)
        readonly property bool focused: shownOn !== null && shownOn.focused

        bar: root.bar
        text: shownOn === null ? (modelData === 10 ? "0" : String(modelData))
          : (focused ? root.filledMarker : root.outlineMarker)
        opacity: occupied || shownOn !== null ? 1 : 0.5
        horizontalMargin: 6
        verticalPadding: 6
        fixedWidth: root.vertical ? root.barSize : Style.space(20)
        fixedHeight: root.barSize
        onPressed: function() { root.focusWorkspace(modelData) }
      }
    }
  }
}
```

Two details matter:

- A `desc:` rule matches when the monitor's description starts with the text
  after `desc:`, the same way Hyprland matches it, so rules that pin screens
  by make, model, and serial work.
- The widget reloads the rules when Hyprland reloads its config or a display
  is plugged in or removed, so editing `monitors.lua` updates the bars.

## Apply and check

The shell reloads plugin files on save. Check that the bar uses the clone:

```bash
omarchy plugin list
hyprctl workspacerules
```

Each screen's bar should list only its own block, such as 4 to 6 on the
middle screen, with a filled square in place of the number it is showing.
Clicking a number switches to that workspace on its own screen.

## Undo

Re-enable the stock widget in place of the clone with
`omarchy plugin disable <username>.workspaces` and
`omarchy plugin enable omarchy.workspaces`, then delete the clone's folder,
`~/.config/omarchy/plugins/<username>.workspaces/`.

## Notes

- The clone no longer follows changes to the stock widget. After an
  `omarchy update`, compare it with
  `/usr/share/omarchy/shell/plugins/bar/widgets/Workspaces.qml` if the bar
  looks off.
- Workspace 10 is shown as 0, like the stock widget, to match `Super + 0`.

## History

- Created by [@duff](https://github.com/duff) on 2026-10-01.
