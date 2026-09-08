# K1 — Magic Keys

A thin 3-key macro pad built on an ESP32-S3 that plugs into a MacBook's side USB-C
port and sits flush along the chassis edge. Keys are configured and executed by the
**Magic Keys** companion Mac app — the device itself sends raw key events only.

## Layout

- `cad/` — OpenSCAD sources, STLs, and renders for the enclosure
- `firmware/` — ESP-IDF firmware (TinyUSB vendor-HID device)
- `mac/` — Magic Keys, the SwiftUI menu-bar companion app for macOS
- `docs/` — design specs and plans

## Architecture at a glance

The ESP32-S3 enumerates as a vendor-defined USB HID device (usage page `0xFF60`).
Firmware debounces the 3 keys and reports `down`/`up` events; all gesture logic
(tap / double-tap / hold) and action execution live in the Mac app. See
`docs/superpowers/specs/` for the full design.
