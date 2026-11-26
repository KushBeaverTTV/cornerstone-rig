import QtQuick
import Quickshell.Io
import qs.Commons
import qs.Ui
import "Rig.js" as Rig

// Cornerstone Rig bar icon & control center.
// Left click: open panel. Right click: pause/resume LAN Mouse.
Panel {
  id: root
  moduleName: "cornerstone.rig"
  ipcTarget: "cornerstone-rig"
  manageIpc: false

  readonly property var service: bar && bar.shell ? bar.shell.serviceFor("cornerstone.rig") : null
  readonly property color foreground: bar ? bar.foreground : Color.foreground
  readonly property color muted: Qt.darker(foreground, 1.55)
  readonly property color hairline: Qt.darker(foreground, 2.4)
  readonly property string fontFamily: bar ? bar.fontFamily : Style.font.family

  property var palette: ({})
  readonly property color okColor: palette.color2 || Color.accent
  readonly property color warnColor: palette.color3 || "#FFB020"
  readonly property color badColor: Color.urgent

  FileView {
    id: paletteFile
    path: Color.currentThemePath + "/colors.toml"
    printErrors: false
    onLoaded: {
      var found = {}
      var re = /^\s*([A-Za-z0-9_]+)\s*=\s*"(#[0-9A-Fa-f]{6,8})"/gm
      var m
      while ((m = re.exec(String(text()))) !== null) found[m[1]] = m[2]
      root.palette = found
    }
  }
  Connections {
    target: Color
    function onBackgroundChanged() { paletteFile.reload() }
    function onAccentChanged() { paletteFile.reload() }
  }

  readonly property var st: service ? service.state : ({})
  readonly property var cap: Rig.parseCapabilities(st.capabilities)
  readonly property bool hasIssue: service ? service.hasIssue : false
  readonly property string barTooltip: Rig.tooltip(st)

  readonly property var rows: Rig.visibleRows(st)

  property int cursor: -1
  property bool watching: false

  onOpenedChanged: {
    cursor = -1
    if (service) {
      if (opened && !watching) { watching = true; service.watchers++; service.refresh() }
      else if (!opened && watching) { watching = false; service.watchers = Math.max(0, service.watchers - 1) }
    }
  }
  Component.onDestruction: {
    if (watching && service) service.watchers = Math.max(0, service.watchers - 1)
  }

  function triggerRow(id) {
    if (!service) return
    if (id === "powerProfile") service.cyclePowerProfile()
    else if (id === "jarvis") service.toggleJarvisWake()
    else if (id === "lanMouse") service.toggleLanMouse()
    else if (id === "sunshine") service.toggleSunshine()
    else if (id === "wave3") { service.resetElgatoWave3(); root.close() }
    else if (id === "pipewire") service.restartPipewire()
    else if (id === "storage") service.restartStorage()
    else if (id === "onedrive") service.restartOneDrive()
  }

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  BarIconButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    tooltipText: root.opened ? "" : root.barTooltip
    onPressed: function(code) {
      if (code === Qt.RightButton && root.service) {
        if (root.cap.lanMouse) root.service.toggleLanMouse()
        else if (root.cap.powerProfile) root.service.cyclePowerProfile()
        else root.toggle()
      } else {
        root.toggle()
      }
    }
    iconComponent: Component {
      Item {
        width: 18; height: 18
        Text {
          anchors.centerIn: parent
          textFormat: Text.PlainText
          text: "󰢻"
          color: root.hasIssue ? root.badColor : (root.st.sunshine ? Color.accent : root.foreground)
          font.family: root.fontFamily
          font.pixelSize: Style.font.icon
        }
        Rectangle {
          visible: root.hasIssue || (root.cap.lanMouse && !root.st.lanMouse) || (root.cap.sunshine && !!root.st.sunshine)
          width: 5; height: 5; radius: 2.5
          anchors.right: parent.right
          anchors.top: parent.top
          color: root.hasIssue ? root.badColor : (root.st.sunshine ? root.okColor : root.warnColor)
        }
      }
    }
  }

  KeyboardPanel {
    id: panel
    anchorItem: button
    owner: root
    bar: root.bar
    open: root.opened
    centerOnBar: false
    focusTarget: panel.loadedContent
    contentWidth: panel.fittedContentWidth(Style.space(330))
    contentHeight: panel.fittedContentHeight(panel.loadedContentHeight, Style.space(520))

    content: PanelKeyCatcher {
      anchors.fill: parent
      implicitHeight: column.implicitHeight
      onCloseRequested: root.close()
      onTabRequested: function(direction) { root.switchPanel(direction) }
      onMoveRequested: function(dx, dy) {
        if (dy === 0) return
        var n = root.rows.length
        root.cursor = root.cursor < 0 ? (dy > 0 ? 0 : n - 1) : (root.cursor + dy + n) % n
      }
      onActivateRequested: {
        if (root.cursor >= 0 && root.cursor < root.rows.length)
          root.triggerRow(root.rows[root.cursor].id)
      }
      onTextKey: function(t) {
        if (!root.service) return
        if ((t === "l" || t === "L") && root.cap.lanMouse) root.service.toggleLanMouse()
        else if ((t === "s" || t === "S") && root.cap.sunshine) root.service.toggleSunshine()
        else if ((t === "p" || t === "P") && root.cap.powerProfile) root.service.cyclePowerProfile()
        else if (t === "r" || t === "R") root.service.refresh()
      }
      clip: true

      Column {
        id: column
        anchors.fill: parent
        spacing: Style.space(10)

        Column {
          spacing: Style.space(2)
          Text {
            textFormat: Text.PlainText
            text: "Cornerstone Rig"
            color: root.foreground
            font.family: root.fontFamily
            font.pixelSize: Style.font.body
            font.bold: true
          }
          Text {
            textFormat: Text.PlainText
            text: root.hasIssue
              ? root.service.issues.join(" · ")
              : (root.st.deviceName ? root.st.deviceName + " · healthy" : "Hardware, sharing & mounts healthy")
            color: root.hasIssue ? root.badColor : root.muted
            font.family: root.fontFamily
            font.pixelSize: Style.font.caption
          }
        }

        Rectangle { width: parent.width; height: 1; color: root.hairline }

        Column {
          width: parent.width
          spacing: Style.space(6)

          Repeater {
            model: root.rows
            Rectangle {
              required property var modelData
              required property int index
              readonly property bool focused: root.cursor === index
              width: parent.width
              height: Style.space(32)
              radius: Style.space(6)
              color: modelData.bad
                ? Util.alpha(root.badColor, rArea.containsMouse || focused ? 0.24 : 0.14)
                : Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b,
                          rArea.containsMouse || focused ? 0.16 : 0.06)
              border.width: focused ? 1 : 0
              border.color: Color.accent
              Behavior on color { ColorAnimation { duration: Style.duration(120) } }

              Rectangle {
                id: dot
                width: 7; height: 7; radius: 3.5
                anchors.left: parent.left
                anchors.leftMargin: Style.space(10)
                anchors.verticalCenter: parent.verticalCenter
                color: modelData.bad ? root.badColor : (modelData.ok ? root.okColor : root.muted)
              }

              Text {
                id: iconG
                anchors.left: dot.right
                anchors.leftMargin: Style.space(8)
                anchors.verticalCenter: parent.verticalCenter
                textFormat: Text.PlainText
                text: modelData.glyph
                color: root.foreground
                font.family: root.fontFamily
                font.pixelSize: Style.font.body
              }

              Text {
                anchors.left: iconG.right
                anchors.leftMargin: Style.space(8)
                anchors.right: stateLbl.left
                anchors.rightMargin: Style.space(8)
                anchors.verticalCenter: parent.verticalCenter
                textFormat: Text.PlainText
                text: modelData.label
                color: root.foreground
                font.family: root.fontFamily
                font.pixelSize: Style.font.caption
                elide: Text.ElideRight
              }

              Text {
                id: stateLbl
                anchors.right: parent.right
                anchors.rightMargin: Style.space(10)
                anchors.verticalCenter: parent.verticalCenter
                textFormat: Text.PlainText
                text: rArea.containsMouse || focused ? modelData.action : modelData.status
                color: rArea.containsMouse || focused ? Color.accent : (modelData.bad ? root.badColor : root.muted)
                font.family: root.fontFamily
                font.pixelSize: Style.font.caption
              }

              MouseArea {
                id: rArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onEntered: root.cursor = index
                onClicked: root.triggerRow(modelData.id)
              }
            }
          }
        }

        Text {
          width: parent.width
          textFormat: Text.PlainText
          wrapMode: Text.WordWrap
          text: {
            var hints = []
            if (root.cap.lanMouse) hints.push("Right-click = LAN Mouse", "l LAN Mouse")
            else if (root.cap.powerProfile) hints.push("Right-click = power profile")
            if (root.cap.sunshine) hints.push("s Sunshine")
            if (root.cap.powerProfile) hints.push("p power")
            hints.push("j/k + Enter")
            return hints.join(" · ")
          }
          color: root.muted
          font.family: root.fontFamily
          font.pixelSize: Style.font.caption
        }
      }
    }
  }
}
