# CLAUDE.md

Guidance for Claude Code when working in the K1 repo.

## What this is

K1 is a thin **3-key** macro pad on an **ESP32-S3** that plugs into a MacBook's
side USB-C port. It is **app-required**: firmware sends raw key down/up events
over a vendor-defined USB HID interface (usage page `0xFF60`, 8-byte reports);
the **Magic Keys** Mac app does all gesture detection (tap / double-tap / hold)
and action execution, with a Logitech-Options-style config UI.

Read `PROJECT_SUMMARY.md` first for status and decisions, and the approved spec
in `docs/superpowers/specs/2026-09-07-k1-firmware-and-mac-app-design.md` before
changing the protocol or architecture.

## Layout

- `cad/` — OpenSCAD enclosure concept + STLs/renders (v0.1, placeholder dims; still models 4 keys)
- `firmware/` — ESP-IDF 5.x + TinyUSB (`esp_tinyusb`) vendor-HID device
- `mac/` — Magic Keys, SwiftUI menu-bar app (macOS 14+, `IOHIDManager`)
- `docs/superpowers/specs/` — design specs

## Rules

- **Firmware stays dumb.** No gesture logic on-device — only debounced down/up
  events with a sequence byte. Gesture timing is tuned in the app.
- **Protocol changes touch both sides.** Firmware and app live in one repo so a
  report-format change lands as one commit updating both, plus the spec.
- **Keep the four Mac app units isolated:** HIDService (only unit touching
  IOKit), GestureEngine (pure logic, unit-tested), ActionEngine (`MagicAction`
  protocol), ConfigStore (Codable JSON in Application Support).
- **Key count is 3.** The CAD's `key_count = 4` is stale — don't propagate 4
  anywhere in firmware or app.
- Dev USB IDs: VID `0x1209` (pid.codes) + test PID until Magic has its own VID.

## Build

- Firmware: standard ESP-IDF flow (`idf.py build flash monitor`) from `firmware/`.
- Mac app: Xcode project in `mac/`.
- Hardware-in-loop smoke test: Python `hidapi` script (see spec's Testing section).
