const assert = require("node:assert/strict")
const Rig = require("../Rig.js")

const ok = Rig.parseState(JSON.stringify({
  lanMouse: true, lanMouseGuard: true, sunshine: false,
  storageMounted: true, onedrive: true, wave3Alsa: true, wave3Usb: true
}))
assert.deepEqual(Rig.issues(ok), [])
assert.equal(Rig.tooltip(ok), "Rig · LAN Mouse ON")

const broken = Rig.parseState(JSON.stringify({
  lanMouse: false, sunshine: true, storageMounted: false, onedrive: true, wave3Alsa: false, wave3Usb: true
}))
assert.equal(Rig.issues(broken).length, 2)
assert.ok(Rig.tooltip(broken).includes("Wave:3"))
assert.equal(Rig.parseState("bad"), null)

console.log("PASS cornerstone.rig unit tests")
