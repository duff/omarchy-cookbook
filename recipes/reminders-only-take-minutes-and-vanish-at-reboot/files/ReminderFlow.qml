import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import qs.Commons
import qs.Commons as Commons
import qs.Ui
import "ReminderFlowModel.js" as ReminderFlowModel

// Super+Ctrl+R. One box: type when and what ("4pm call Bob", "20m tea",
// "tomorrow 9am pay rent"), see what that will set before pressing Enter,
// and see what's already waiting and how long until each. Up and Down pick
// one; Delete cancels it. The remind command next to the reminders' toast
// wrapper (~/.config/omarchy/reminders/remind) reads, sets and lists them.
Item {
  id: root

  property string remind: Quickshell.env("HOME") + "/.config/omarchy/reminders/remind"
  property var shell: null
  property var manifest: null

  property bool opened: false
  property string filterText: ""
  property var preview: ({})
  property var reminders: []
  property int selected: -1
  property real now: Date.now() / 1000
  property string fontFamily: Style.font.menuFamily

  property color background: Commons.Color.menu.background
  property color foreground: Commons.Color.menu.text
  property color border: Commons.Color.menu.border
  property color selectedBackground: Commons.Color.menu.selectedBackground
  property color selectedText: Commons.Color.menu.selectedText
  property var borderSpec: Border.surfaceSpec("menu", "border", border, Math.max(1, Style.space(2)))
  property color scrim: Commons.Color.menu.scrim
  readonly property int cornerRadius: Style.cornerRadius
  property int contentMargin: Style.spacing.panelPadding
  property int cardWidth: Math.min(Style.space(460), panel.width - Style.gapsOut * 2)

  function open(payloadJson) {
    var payload = ({})
    try { payload = JSON.parse(payloadJson || "{}") } catch (e) { payload = ({}) }
    if (payload.fontFamily) root.fontFamily = payload.fontFamily

    root.opened = true
    root.filterText = ""
    root.preview = ({})
    root.selected = -1
    root.now = Date.now() / 1000
    listProc.running = true

    Qt.callLater(function() { keyCatcher.forceActiveFocus() })
  }

  function close() {
    root.opened = false
  }

  function dismiss() {
    root.opened = false
    if (root.shell && typeof root.shell.hide === "function")
      root.shell.hide((root.manifest && root.manifest.id) || "omarchy.reminders")
  }

  function toggle() {
    if (root.opened) root.dismiss()
    else root.open("{}")
  }

  function setFilter(nextFilter) {
    root.filterText = nextFilter
    if (!nextFilter.trim()) root.preview = ({})
    parseDelay.restart()
  }

  function runParse() {
    var text = root.filterText
    if (!text.trim()) return
    if (parseProc.running) {
      parseDelay.restart()
      return
    }
    parseProc.sentText = text
    parseProc.command = [root.remind, "parse", "--", text]
    parseProc.running = true
  }

  // Under what's typed: what it will set, why it can't, or examples.
  function previewLine() {
    if (!root.filterText.trim()) return "4pm call Bob  ·  20m tea  ·  tomorrow 9am pay rent"
    var p = root.preview
    if (p.ok) return (p.message || "Reminder") + "  ·  " + p.when + ", in " + ReminderFlowModel.left(p.at - root.now)
    return p.error || ""
  }

  function submit() {
    var text = root.filterText.trim()
    if (!text) {
      root.dismiss()
      return
    }
    // Stay open on text the preview already says can't be set.
    if (root.preview.input === root.filterText && root.preview.ok !== true) return

    root.dismiss()
    Quickshell.execDetached([root.remind, "--", text])
  }

  function cancelSelected() {
    var item = root.reminders[root.selected]
    if (!item) return
    Quickshell.execDetached([root.remind, "cancel", item.unit])
    var rest = root.reminders.slice()
    rest.splice(root.selected, 1)
    root.reminders = rest
    root.selected = Math.min(root.selected, rest.length - 1)
  }

  Timer {
    id: parseDelay
    interval: 120
    onTriggered: root.runParse()
  }

  Timer {
    interval: 1000
    repeat: true
    running: root.opened
    onTriggered: root.now = Date.now() / 1000
  }

  Process {
    id: parseProc
    property string sentText: ""
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        if (parseProc.sentText !== root.filterText) return
        try { root.preview = JSON.parse(text) } catch (e) { root.preview = ({}) }
      }
    }
  }

  Process {
    id: listProc
    command: [root.remind, "show", "--json"]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        try { root.reminders = JSON.parse(text) } catch (e) { root.reminders = [] }
      }
    }
  }

  PanelWindow {
    id: panel
    visible: root.opened
    anchors { top: true; bottom: true; left: true; right: true }
    color: "transparent"
    WlrLayershell.namespace: "omarchy-reminders"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
    exclusionMode: ExclusionMode.Ignore

    Rectangle {
      anchors.fill: parent
      color: root.scrim
    }

    MouseArea {
      anchors.fill: parent
      onClicked: root.dismiss()
    }

    BorderSurface {
      id: card
      width: root.cardWidth
      height: Math.min(content.implicitHeight + card.contentTopInset + card.contentBottomInset, panel.height - Style.gapsOut * 2)
      radius: root.cornerRadius
      anchors.centerIn: parent
      color: root.background
      borderSpec: root.borderSpec
      padding: root.contentMargin

      MouseArea { anchors.fill: parent; onClicked: {} }

      Item {
        id: keyCatcher
        anchors.fill: parent
        focus: true

        Keys.priority: Keys.BeforeItem
        Keys.onPressed: function(event) {
          if (event.key === Qt.Key_Escape) {
            if (root.filterText) root.setFilter("")
            else if (root.selected >= 0) root.selected = -1
            else root.dismiss()
            event.accepted = true
          } else if (event.key === Qt.Key_Down || event.key === Qt.Key_Up) {
            root.selected = ReminderFlowModel.moved(root.selected, root.reminders.length, event.key === Qt.Key_Down ? 1 : -1)
            event.accepted = true
          } else if (event.key === Qt.Key_Delete) {
            root.cancelSelected()
            event.accepted = true
          } else if (Util.editsFilter(event, root.filterText)) {
            root.setFilter(Util.editedFilter(event, root.filterText))
            event.accepted = true
          } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
            root.submit()
            event.accepted = true
          } else if (event.text && event.text.length === 1 && event.text.charCodeAt(0) >= 32 && event.text.charCodeAt(0) !== 127) {
            root.setFilter(root.filterText + event.text)
            event.accepted = true
          }
        }
      }

      Column {
        id: content
        x: card.contentLeftInset
        y: card.contentTopInset
        width: card.width - card.contentLeftInset - card.contentRightInset
        spacing: Style.spacing.md

        Text {
          width: parent.width
          textFormat: Text.PlainText
          text: root.filterText || "Remind me..."
          color: root.foreground
          opacity: root.filterText ? 1 : 0.58
          font.family: root.fontFamily
          font.pixelSize: Style.font.heading
          elide: Text.ElideLeft
        }

        Text {
          width: parent.width
          textFormat: Text.PlainText
          text: root.previewLine()
          color: root.preview.ok ? root.selectedText : root.foreground
          opacity: root.preview.ok ? 1 : 0.58
          font.family: root.fontFamily
          font.pixelSize: Style.font.body
          wrapMode: Text.Wrap
        }

        Rectangle {
          visible: root.reminders.length > 0
          width: parent.width
          height: 1
          color: root.foreground
          opacity: 0.15
        }

        Repeater {
          model: root.reminders

          Rectangle {
            required property var modelData
            required property int index
            readonly property bool picked: index === root.selected

            width: content.width
            height: label.implicitHeight + Style.spacing.sm * 2
            radius: Style.spacing.sm
            color: picked ? root.selectedBackground : "transparent"

            Text {
              id: label
              anchors.left: parent.left
              anchors.right: due.left
              anchors.leftMargin: Style.spacing.sm
              anchors.rightMargin: Style.spacing.lg
              anchors.verticalCenter: parent.verticalCenter
              textFormat: Text.PlainText
              text: modelData.message
              color: picked ? root.selectedText : root.foreground
              font.family: root.fontFamily
              font.pixelSize: Style.font.body
              elide: Text.ElideRight
            }

            Text {
              id: due
              anchors.right: parent.right
              anchors.rightMargin: Style.spacing.sm
              anchors.verticalCenter: parent.verticalCenter
              textFormat: Text.PlainText
              text: modelData.when + "  ·  " + ReminderFlowModel.left(modelData.at - root.now)
              color: picked ? root.selectedText : root.foreground
              opacity: picked ? 1 : 0.7
              font.family: root.fontFamily
              font.pixelSize: Style.font.body
            }
          }
        }

        Text {
          visible: root.reminders.length > 0
          width: parent.width
          textFormat: Text.PlainText
          text: root.selected >= 0 ? "Delete cancels it  ·  Esc unpicks it" : "Up and Down pick one to cancel"
          color: root.foreground
          opacity: 0.45
          font.family: root.fontFamily
          font.pixelSize: Style.font.caption
        }
      }
    }
  }
}
