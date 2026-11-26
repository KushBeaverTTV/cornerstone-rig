#!/usr/bin/env python3
"""Device-aware hardware & streaming rig status snapshot for cornerstone.rig.

Auto-discovers which services and peripherals actually exist on this PC
(desktop rig vs laptop/MacBook) so missing desktop-only hardware never triggers
false errors on portable or minimal machines.
"""
import glob
import json
import os
import shutil
import socket
import subprocess


HOME = os.path.expanduser("~")
UNIT_DIRS = (
    os.path.join(HOME, ".config/systemd/user"),
    "/etc/systemd/user",
    "/usr/lib/systemd/user",
)


def read_text(path):
    try:
        with open(path, "rb") as f:
            return f.read().replace(b"\x00", b"").decode("utf-8", errors="ignore").strip()
    except Exception:
        return ""


def unit_exists(name):
    fname = f"{name}.service"
    return any(os.path.exists(os.path.join(d, fname)) for d in UNIT_DIRS)


def unit_active(name):
    try:
        r = subprocess.run(
            ["systemctl", "--user", "is-active", f"{name}.service"],
            capture_output=True, text=True, timeout=1.5
        )
        return r.stdout.strip() == "active"
    except Exception:
        return False


def unit_enabled(name):
    try:
        r = subprocess.run(
            ["systemctl", "--user", "is-enabled", f"{name}.service"],
            capture_output=True, text=True, timeout=1.5
        )
        return r.stdout.strip() in ("enabled", "indirect")
    except Exception:
        return False


def has_wave3_alsa():
    txt = read_text("/proc/asound/cards").lower()
    return "wave3" in txt or "wave:3" in txt or "elgato" in txt


def has_wave3_usb():
    for p in glob.glob("/sys/bus/usb/devices/*/product"):
        if "wave:3" in read_text(p).lower():
            return True
    return False


def has_storage_configured():
    return (
        os.path.ismount("/mnt/storage")
        or os.path.isdir("/mnt/storage")
        or "/mnt/storage" in read_text("/etc/fstab")
    )


def power_profile():
    if not shutil.which("powerprofilesctl"):
        return ""
    try:
        r = subprocess.run(
            ["powerprofilesctl", "get"],
            capture_output=True, text=True, timeout=1.5
        )
        val = r.stdout.strip()
        return val if val in ("performance", "balanced", "power-saver") else ""
    except Exception:
        return ""


def detect_device_name():
    for path in (
        "/proc/device-tree/model",
        "/sys/devices/virtual/dmi/id/product_name",
        "/sys/class/dmi/id/product_name",
    ):
        val = read_text(path)
        if val and val.lower() not in ("to be filled by o.e.m.", "system product name", "default string"):
            return val
    return socket.gethostname()


def jarvis_state():
    path = os.path.expanduser("~/.local/state/cornerstone-jarvis/state.json")
    active = unit_active("cornerstone-jarvis")
    try:
        with open(path) as f:
            d = json.load(f)
        return {
            "jarvisActive": active,
            "jarvisWake": bool(d.get("wakeEnabled")),
            "jarvisGated": bool(d.get("wakeGated")),
        }
    except Exception:
        return {"jarvisActive": active, "jarvisWake": False, "jarvisGated": False}


def main():
    wave3_alsa = has_wave3_alsa()
    wave3_usb = has_wave3_usb()
    wave3_present = wave3_alsa or wave3_usb or os.path.exists(os.path.join(HOME, "Work/reset-elgato-usb.sh"))
    storage_present = has_storage_configured()
    onedrive_present = unit_exists("onedrive-mount")
    lan_mouse_present = unit_exists("lan-mouse") or bool(shutil.which("lan-mouse"))
    sunshine_present = unit_exists("sunshine") or bool(shutil.which("sunshine"))
    jarvis_present = unit_exists("cornerstone-jarvis") and (unit_active("cornerstone-jarvis") or unit_enabled("cornerstone-jarvis"))
    pp = power_profile()

    out = {
        "deviceName": detect_device_name(),
        "lanMouse": unit_active("lan-mouse") if lan_mouse_present else False,
        "lanMouseGuard": unit_active("lan-mouse-guard") if lan_mouse_present else False,
        "sunshine": unit_active("sunshine") if sunshine_present else False,
        "storageMounted": os.path.ismount("/mnt/storage") if storage_present else False,
        "onedrive": unit_active("onedrive-mount") if onedrive_present else False,
        "wave3Alsa": wave3_alsa,
        "wave3Usb": wave3_usb,
        "powerProfile": pp,
        "capabilities": {
            "jarvis": jarvis_present,
            "lanMouse": lan_mouse_present,
            "sunshine": sunshine_present,
            "wave3": wave3_present,
            "pipewire": True,
            "storage": storage_present,
            "onedrive": onedrive_present,
            "powerProfile": bool(pp),
        },
    }
    out.update(jarvis_state())
    print(json.dumps(out))


if __name__ == "__main__":
    main()
