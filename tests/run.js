const assert = require("node:assert/strict")
const Rig = require("../Rig.js")

// Legacy desktop payload (no capabilities field) stays 100% backward compatible
const ok = Rig.parseState(JSON.stringify({
  lanMouse: true, lanMouseGuard: true, sunshine: false,
  storageMounted: true, onedrive: true, wave3Alsa: true, wave3Usb: true
}))
assert.deepEqual(Rig.issues(ok), [])
assert.equal(Rig.tooltip(ok), "Rig · LAN Mouse ON")
assert.equal(Rig.visibleRows(ok).length, 7)

const broken = Rig.parseState(JSON.stringify({
  lanMouse: false, sunshine: true, storageMounted: false, onedrive: true, wave3Alsa: false, wave3Usb: true
}))
assert.equal(Rig.issues(broken).length, 2)
assert.ok(Rig.tooltip(broken).includes("Wave:3"))
assert.equal(Rig.parseState("bad"), null)

// Laptop / MacBook payload: missing desktop hardware produces ZERO issues
const laptop = Rig.parseState(JSON.stringify({
  deviceName: "Mac17,5",
  lanMouse: true,
  powerProfile: "balanced",
  capabilities: {
    jarvis: false, lanMouse: true, sunshine: false, wave3: false,
    pipewire: true, storage: false, onedrive: false, powerProfile: true
  }
}))
assert.deepEqual(Rig.issues(laptop), [])
assert.equal(Rig.visibleRows(laptop).map(r => r.id).join(","), "powerProfile,lanMouse,pipewire")
assert.equal(Rig.tooltip(laptop), "Rig · LAN Mouse ON · Power: balanced")
assert.equal(Rig.nextPowerProfile("balanced"), "performance")
assert.equal(Rig.nextPowerProfile("performance"), "power-saver")

console.log("PASS cornerstone.rig unit tests")
