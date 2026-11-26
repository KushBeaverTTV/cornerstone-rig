# Cornerstone Rig

Device-aware hardware, streaming, power, and mount control center for the Omarchy status bar.

- **Auto-discovery**: probes which hardware and services actually exist on this PC (Power Profile, Jarvis, LAN Mouse, Sunshine, Elgato Wave:3, PipeWire, `/mnt/storage`, OneDrive) and hides absent desktop peripherals so laptops and minimal hosts never show false errors.
- **Bar icon**: crisp gear glyph with a status dot when a configured service or peripheral needs attention (or when Sunshine is live / LAN Mouse is paused).
- **Clicks & keys**: left-click opens the panel; right-click toggles LAN Mouse (or cycles Power Profile on laptops without LAN Mouse). Keyboard: `l` LAN Mouse, `s` Sunshine, `p` power profile, `j`/`k` + Enter.

## Tests

```bash
node tests/run.js
```
