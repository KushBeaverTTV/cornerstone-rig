#!/usr/bin/env python3
"""Quick hardware & streaming rig status snapshot for cornerstone.rig."""
import glob
import json
import os
import subprocess


def unit_active(name):
    try:
        r = subprocess.run(
            ["systemctl", "--user", "is-active", f"{name}.service"],
            capture_output=True, text=True, timeout=1.5
        )
        return r.stdout.strip() == "active"
    except Exception:
        return False


def has_wave3_alsa():
    try:
        with open("/proc/asound/cards") as f:
            txt = f.read().lower()
        return "wave3" in txt or "wave:3" in txt or "elgato" in txt
    except Exception:
        return False


def has_wave3_usb():
    for p in glob.glob("/sys/bus/usb/devices/*/product"):
        try:
            with open(p) as f:
                if "wave:3" in f.read().lower():
                    return True
        except Exception:
            pass
    return False


def jarvis_state():
    path = os.path.expanduser("~/.local/state/cornerstone-jarvis/state.json")
    try:
        with open(path) as f:
            d = json.load(f)
        return {
            "jarvisActive": unit_active("cornerstone-jarvis"),
            "jarvisWake": bool(d.get("wakeEnabled")),
            "jarvisGated": bool(d.get("wakeGated")),
        }
    except Exception:
        return {"jarvisActive": unit_active("cornerstone-jarvis"), "jarvisWake": False, "jarvisGated": False}


def main():
    out = {
        "lanMouse": unit_active("lan-mouse"),
        "lanMouseGuard": unit_active("lan-mouse-guard"),
        "sunshine": unit_active("sunshine"),
        "storageMounted": os.path.ismount("/mnt/storage"),
        "onedrive": unit_active("onedrive-mount"),
        "wave3Alsa": has_wave3_alsa(),
        "wave3Usb": has_wave3_usb(),
    }
    out.update(jarvis_state())
    print(json.dumps(out))


if __name__ == "__main__":
    main()
