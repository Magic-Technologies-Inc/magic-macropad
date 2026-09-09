# K1 Project Summary

**Last updated:** 2026-09-08

## What K1 is

K1 ("Keys v1") is a Magic hardware product: a thin **3-key** macro pad that plugs
into a MacBook's side USB-C port and sits flush along the chassis edge, running
toward the front. It is built on an **RP2040** (RP2040-Zero board) and is
**app-required** — the
device sends raw key events over USB and does nothing without the companion Mac
app, **Magic Keys**, which detects gestures and runs the user's configured
actions.

## Key decisions

| Decision | Choice |
|---|---|
| Key count | 3 (CAD still shows 4 — pending update) |
| Device model | App-required; no standalone HID-keyboard fallback |
| Transport | Native USB, vendor-defined HID (usage page `0xFF60`), 8-byte reports |
| Firmware stack | Pico SDK 2.x + TinyUSB (was ESP-IDF/ESP32-S3 — ported 2026-09-08) |
| Board | RP2040-Zero (Waveshare design, hiBCTR clones); keys on GPIO 0/1/2 |
| Gesture logic | Entirely in the Mac app (tap / double-tap / hold); firmware sends only down/up |
| Mac app | SwiftUI menu-bar app, macOS 14+, `IOHIDManager` |
| Config UI | Logitech Options-style: device render, click a key, assign actions per gesture |
| V1 actions | Open app, open URL, keyboard shortcut, media control, shell script |
| Dev USB IDs | VID `0x1209` (pid.codes) + test PID until Magic has its own VID |

## Repository layout

- `cad/` — OpenSCAD enclosure concept (body, lid, tray), STLs, renders
- `firmware/` — ESP-IDF firmware (not started)
- `mac/` — Magic Keys app (not started)
- `docs/superpowers/specs/` — design specs

## Current status

- ✅ Enclosure concept CAD (v0.1 — placeholder dimensions; MacBook port position
  and side taper still need measuring)
- ✅ Architecture designed and spec approved:
  [docs/superpowers/specs/2026-09-07-k1-firmware-and-mac-app-design.md](docs/superpowers/specs/2026-09-07-k1-firmware-and-mac-app-design.md)
- ✅ Implementation plans (firmware + Mac app, in docs/superpowers/plans/)
- ✅ Firmware: vendor-HID device with debounced key events + GET_INFO, ported
  to RP2040-Zero / Pico SDK (build-verified UF2; flash + enumeration pending
  hardware bring-up — spec: docs/superpowers/specs/2026-09-08-rp2040-port-design.md)
- ✅ Magic Keys app: HID pipeline, gesture engine, action engine, config UI, virtual K1
- 🔶 Hardware-in-loop smoke test written (run pending hardware)
- ⬜ CAD update 4 → 3 keys; real measurements
- ⬜ CAD: board pocket rework for the RP2040-Zero footprint (~18×23.5 mm,
  different pad layout than the XIAO the v2 CAD models)

## Explicitly out of scope for v1

LEDs, on-device config, OTA/DFU, smart-home actions (hook exists via the
`MagicAction` protocol), non-Mac hosts.

## Related Magic context

Magic's other components live alongside this repo (`app/`, `iOS/`, `server/`,
`website/`). Smart-home triggers via the FastAPI server (Hue, Govee, Meross) are
a planned later action type for Magic Keys.
