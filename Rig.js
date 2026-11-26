// Pure state parsing, device-capability filtering & health helpers for Cornerstone Rig.

function parseCapabilities(raw) {
  // Legacy payloads without `capabilities` preserve the original desktop-rig set.
  if (!raw || typeof raw !== "object" || Array.isArray(raw)) {
    return {
      jarvis: true,
      lanMouse: true,
      sunshine: true,
      wave3: true,
      pipewire: true,
      storage: true,
      onedrive: true,
      powerProfile: false
    }
  }
  return {
    jarvis: raw.jarvis === true,
    lanMouse: raw.lanMouse === true,
    sunshine: raw.sunshine === true,
    wave3: raw.wave3 === true,
    pipewire: raw.pipewire !== false,
    storage: raw.storage === true,
    onedrive: raw.onedrive === true,
    powerProfile: raw.powerProfile === true
  }
}

function parseState(text) {
  var d
  try { d = JSON.parse(String(text || "")) } catch (e) { return null }
  if (!d || typeof d !== "object" || Array.isArray(d)) return null
  var pp = String(d.powerProfile || "")
  if (pp !== "performance" && pp !== "balanced" && pp !== "power-saver") pp = ""
  return {
    deviceName: String(d.deviceName || "").slice(0, 48),
    lanMouse: d.lanMouse === true,
    lanMouseGuard: d.lanMouseGuard === true,
    sunshine: d.sunshine === true,
    storageMounted: d.storageMounted === true,
    onedrive: d.onedrive === true,
    wave3Alsa: d.wave3Alsa === true,
    wave3Usb: d.wave3Usb === true,
    jarvisActive: d.jarvisActive === true,
    jarvisWake: d.jarvisWake === true,
    jarvisGated: d.jarvisGated === true,
    powerProfile: pp,
    capabilities: parseCapabilities(d.capabilities)
  }
}

function nextPowerProfile(current) {
  var order = ["power-saver", "balanced", "performance"]
  var i = order.indexOf(String(current || ""))
  return order[(i < 0 ? 1 : i + 1) % order.length]
}

function issues(s) {
  if (!s) return []
  var cap = parseCapabilities(s.capabilities)
  var out = []
  if (cap.wave3 && !s.wave3Alsa) out.push("Wave:3 audio missing")
  if (cap.storage && !s.storageMounted) out.push("/mnt/storage unmounted")
  if (cap.onedrive && !s.onedrive) out.push("OneDrive offline")
  return out
}

function visibleRows(st) {
  var s = st || {}
  var cap = parseCapabilities(s.capabilities)
  var rows = []
  if (cap.powerProfile && s.powerProfile) {
    rows.push({
      id: "powerProfile",
      glyph: s.powerProfile === "performance" ? "󰓅" : (s.powerProfile === "power-saver" ? "󰌪" : "󰾅"),
      label: "Power Profile",
      status: s.powerProfile,
      ok: true,
      action: "switch to " + nextPowerProfile(s.powerProfile)
    })
  }
  if (cap.jarvis) {
    rows.push({
      id: "jarvis", glyph: "✦", label: "Jarvis Wake Word",
      status: !s.jarvisActive ? "offline" : (!s.jarvisWake ? "wake off" : (s.jarvisGated ? "call paused" : "Hey Jarvis")),
      ok: !!s.jarvisActive && !!s.jarvisWake,
      action: s.jarvisWake ? "mute wake" : "enable wake"
    })
  }
  if (cap.lanMouse) {
    rows.push({
      id: "lanMouse", glyph: "󰍽", label: "LAN Mouse",
      status: s.lanMouse ? "active" : "paused",
      ok: !!s.lanMouse,
      action: s.lanMouse ? "pause" : "start"
    })
  }
  if (cap.sunshine) {
    rows.push({
      id: "sunshine", glyph: "󰢹", label: "Sunshine Stream Host",
      status: s.sunshine ? "live" : "off",
      ok: !!s.sunshine,
      action: s.sunshine ? "stop" : "start"
    })
  }
  if (cap.wave3) {
    rows.push({
      id: "wave3", glyph: "󰍬", label: "Elgato Wave:3 Audio",
      status: s.wave3Alsa ? "healthy" : (s.wave3Usb ? "USB hung" : "unplugged"),
      ok: !!s.wave3Alsa, bad: !s.wave3Alsa,
      action: "USB reset"
    })
  }
  if (cap.pipewire) {
    rows.push({
      id: "pipewire", glyph: "󰕾", label: "PipeWire Audio Graph",
      status: "running", ok: true, action: "restart"
    })
  }
  if (cap.storage) {
    rows.push({
      id: "storage", glyph: "󰋊", label: "/mnt/storage",
      status: s.storageMounted ? "mounted" : "unmounted",
      ok: !!s.storageMounted, bad: !s.storageMounted,
      action: "remount"
    })
  }
  if (cap.onedrive) {
    rows.push({
      id: "onedrive", glyph: "󰏊", label: "OneDrive Mount",
      status: s.onedrive ? "active" : "offline",
      ok: !!s.onedrive, bad: !s.onedrive,
      action: "restart"
    })
  }
  return rows
}

function tooltip(s) {
  if (!s) return "Cornerstone Rig"
  var cap = parseCapabilities(s.capabilities)
  var prob = issues(s)
  if (prob.length > 0) return "Rig · " + prob.join(" · ")
  var parts = ["Rig"]
  if (cap.lanMouse) parts.push(s.lanMouse ? "LAN Mouse ON" : "LAN Mouse paused")
  if (cap.sunshine && s.sunshine) parts.push("Sunshine LIVE")
  if (cap.powerProfile && s.powerProfile) parts.push("Power: " + s.powerProfile)
  if (parts.length === 1) parts.push("Healthy")
  return parts.join(" · ")
}

if (typeof module !== "undefined") {
  module.exports = {
    parseCapabilities: parseCapabilities,
    parseState: parseState,
    nextPowerProfile: nextPowerProfile,
    issues: issues,
    visibleRows: visibleRows,
    tooltip: tooltip
  }
}
