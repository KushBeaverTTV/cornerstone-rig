import QtQuick
import Quickshell
import Quickshell.Io
import "Rig.js" as Rig

// Single session-wide service for Cornerstone Rig: monitors LAN Mouse,
// Sunshine, Elgato Wave:3 audio/USB, /mnt/storage, and OneDrive, and owns
// the `cornerstone-rig` IPC target.
Item {
  id: service

  property var shell: null
  readonly property string pluginId: "cornerstone.rig"
  readonly property string probePath: Qt.resolvedUrl("bin/rig-state.py").toString().replace(/^file:\/\//, "")
  readonly property string elgatoResetScript: Quickshell.env("HOME") + "/Work/reset-elgato-usb.sh"

  property var state: ({
    lanMouse: false, lanMouseGuard: false, sunshine: false,
    storageMounted: true, onedrive: true, wave3Alsa: true, wave3Usb: true
  })
  property int watchers: 0

  readonly property var issues: Rig.issues(state)
  readonly property bool hasIssue: issues.length > 0

  function refresh() {
    if (!probeProc.running) probeProc.running = true
  }

  function run(argv) {
    Quickshell.execDetached(argv)
    refreshSoon.restart()
  }

  function toggleLanMouse() {
    var stopping = state.lanMouse
    // Stop/start both lan-mouse and its guard so the guard doesn't immediately restart it.
    run(["systemctl", "--user", stopping ? "stop" : "start", "lan-mouse-guard.service", "lan-mouse.service"])
    Quickshell.execDetached(["omarchy-shell", "dynamic-island", "toast",
      stopping ? "LAN Mouse paused" : "LAN Mouse active",
      stopping ? "Cursor locked to this PC" : "Edge switching enabled", "󰍽", stopping ? "orange" : "green"])
  }

  function toggleSunshine() {
    var stopping = state.sunshine
    run(["systemctl", "--user", stopping ? "stop" : "start", "sunshine.service"])
    Quickshell.execDetached(["omarchy-shell", "dynamic-island", "toast",
      stopping ? "Sunshine stopped" : "Sunshine started",
      stopping ? "Stream host offline" : "Ready for Moonlight", "󰢹", stopping ? "dim" : "green"])
  }

  function restartPipewire() {
    run(["systemctl", "--user", "restart", "pipewire.service", "pipewire-pulse.service", "wireplumber.service"])
    Quickshell.execDetached(["omarchy-shell", "dynamic-island", "toast",
      "Audio restarted", "PipeWire & WirePlumber reloaded", "󰕾", "accent"])
  }

  function resetElgatoWave3() {
    // Runs in a visible interactive terminal so sudo can prompt cleanly.
    Quickshell.execDetached(["omarchy-launch-tui", "sh", "-c",
      'sudo "$1"; echo ""; read -r -p "Press Enter to close..." _', "sh", elgatoResetScript])
    refreshSoon.restart()
  }

  function restartOneDrive() {
    run(["systemctl", "--user", "restart", "onedrive-mount.service"])
  }

  function restartStorage() {
    run(["systemctl", "--user", "restart", "cornerstone-storage.service"])
  }

  Process {
    id: probeProc
    command: ["python3", service.probePath]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        var parsed = Rig.parseState(this.text)
        if (parsed) service.state = parsed
      }
    }
  }

  Timer {
    interval: service.watchers > 0 ? 2000 : 12000
    running: true
    repeat: true
    triggeredOnStart: true
    onTriggered: service.refresh()
  }

  Timer {
    id: refreshSoon
    interval: 900
    onTriggered: service.refresh()
  }

  IpcHandler {
    target: "cornerstone-rig"

    function toggle(): string { if (service.shell) service.shell.toggle(service.pluginId); return "ok" }
    function toggleLanMouse(): string { service.toggleLanMouse(); return "ok" }
    function toggleSunshine(): string { service.toggleSunshine(); return "ok" }
    function refresh(): string { service.refresh(); return "ok" }
  }
}
