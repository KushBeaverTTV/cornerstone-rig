// Pure state parsing & health helpers for Cornerstone Rig.

function parseState(text) {
  var d
  try { d = JSON.parse(String(text || "")) } catch (e) { return null }
  if (!d || typeof d !== "object" || Array.isArray(d)) return null
  return {
    lanMouse: d.lanMouse === true,
    lanMouseGuard: d.lanMouseGuard === true,
    sunshine: d.sunshine === true,
    storageMounted: d.storageMounted === true,
    onedrive: d.onedrive === true,
    wave3Alsa: d.wave3Alsa === true,
    wave3Usb: d.wave3Usb === true,
    jarvisActive: d.jarvisActive === true,
    jarvisWake: d.jarvisWake === true,
    jarvisGated: d.jarvisGated === true
  }
}

function issues(s) {
  if (!s) return []
  var out = []
  if (!s.wave3Alsa) out.push("Wave:3 audio missing")
  if (!s.storageMounted) out.push("/mnt/storage unmounted")
  if (!s.onedrive) out.push("OneDrive offline")
  return out
}

function tooltip(s) {
  if (!s) return "Cornerstone Rig"
  var prob = issues(s)
  if (prob.length > 0) return "Rig · " + prob.join(" · ")
  var parts = ["Rig"]
  parts.push(s.lanMouse ? "LAN Mouse ON" : "LAN Mouse paused")
  if (s.sunshine) parts.push("Sunshine LIVE")
  return parts.join(" · ")
}

if (typeof module !== "undefined") {
  module.exports = {
    parseState: parseState,
    issues: issues,
    tooltip: tooltip
  }
}
