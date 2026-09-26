# Magic Macropad (K1) Project Summary

**Last updated:** 2026-09-26

## What it is

Magic Macropad (codename K1, "Keys v1") is a Magic hardware product: a thin
**3-key** macro pad that plugs into a MacBook's side USB-C port and sits flush
along the chassis edge, running toward the front. There's also a desk variant
that takes a normal cable. It's built on an **RP2040** (RP2040-Zero board) and
is **app-required**. The device sends raw key events over USB and does nothing
without the companion **Magic Macropad** Mac app, which detects gestures and
runs the user's configured actions.

## Key decisions

| Decision | Choice |
|---|---|
| Key count | 3 (CAD, firmware, and app) |
| Device model | App-required; no standalone HID-keyboard fallback |
| Transport | Native USB, vendor-defined HID (usage page `0xFF60`), 8-byte reports |
| Firmware stack | Pico SDK 2.x + TinyUSB (was ESP-IDF/ESP32-S3; ported 2026-09-08) |
| Board | RP2040-Zero (Waveshare design, hiBCTR clones); keys on GPIO 12/11/10 |
| Gesture logic | Entirely in the Mac app (tap / double-tap / triple-tap / hold); firmware sends only down/up |
| Mac app | SwiftUI menu-bar app, macOS 15+, `IOHIDManager` |
| Config UI | Logitech Options-style: device render, click a key, assign actions per gesture; per-app profiles |
| Actions | Open app/URL/file, keyboard shortcut, media, paste text, system actions, AI (Claude/ChatGPT/dictation), shell script (with presets) |
| Dev USB IDs | VID `0x1209` (pid.codes) + test PID until Magic has its own VID |
| License | CC BY-NC-SA 4.0 (source-available, non-commercial) plus a permission to use self-built devices at work; Magic name and logo reserved |

## Repository layout

- `cad/`: OpenSCAD enclosure revisions `v0`–`v5` (side-mount) and
  `desk/v1`–`v2`, with STLs, renders, and Bambu Studio projects
- `firmware/`: Pico SDK + TinyUSB vendor-HID firmware
- `mac/`: the Magic Macropad app (XcodeGen, target `MagicKeys`) and the
  `MagicKeysCore` package
- `docs/superpowers/specs/`: design specs (historical names)

## Current status

- ✅ Architecture designed and spec approved:
  [docs/superpowers/specs/2026-09-07-k1-firmware-and-mac-app-design.md](docs/superpowers/specs/2026-09-07-k1-firmware-and-mac-app-design.md)
- ✅ Implementation plans (firmware + Mac app, in docs/superpowers/plans/)
- ✅ Firmware: vendor-HID device with debounced key events + GET_INFO, ported
  to RP2040-Zero / Pico SDK, plus per-key WS2812 press colors
  (spec: docs/superpowers/specs/2026-09-08-rp2040-port-design.md)
- ✅ Magic Macropad app: HID pipeline, gesture engine, action engine, per-app
  profiles, config UI, Test keys menu
- ✅ Hardware bring-up (2026-09-08): flashed to a real RP2040-Zero, enumerates
  as 0x1209:0x0001 (product string then "K1", now "Magic Macropad"), smoke
  test PASS (GET_INFO + all key events, gapless seq). Flash tip: a
  CircuitPython board can be kicked into BOOTSEL from the Mac via a 1200-baud
  touch on its /dev/cu.usbmodem* port
- ✅ Enclosure at 3 keys around the RP2040-Zero; fit tuned empirically against
  prints (v4 was the first confirmed fit; v5 raises the USB corridor to meet
  the port; desk v2 is unprinted)
- ✅ Prepared for public release (2026-09-26): renamed Magic Macropad,
  CC BY-NC-SA 4.0, commercial Advercase font purged from history
- ⬜ End-to-end: keys → Magic Macropad app gestures → actions
- ⬜ Dedicated USB PID (pid.codes needs an open-source license, so likely
  Raspberry Pi's RP2040 PID program)

## Explicitly out of scope for v1

On-device config, OTA/DFU, smart-home actions (would be a new `ActionConfig`
case), non-Mac hosts.
