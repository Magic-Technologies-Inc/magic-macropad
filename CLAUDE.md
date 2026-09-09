# CLAUDE.md

Guidance for Claude Code when working in the K1 repo.

## What this is

K1 is a thin **3-key** macro pad on an **RP2040** (RP2040-Zero board) that
plugs into a MacBook's side USB-C port. It is **app-required**: firmware sends raw key down/up events
over a vendor-defined USB HID interface (usage page `0xFF60`, 8-byte reports);
the **Magic Keys** Mac app does all gesture detection (tap / double-tap / hold)
and action execution, with a Logitech-Options-style config UI.

Read `PROJECT_SUMMARY.md` first for status and decisions, and the approved spec
in `docs/superpowers/specs/2026-09-07-k1-firmware-and-mac-app-design.md` before
changing the protocol or architecture.

## Layout

- `cad/` — OpenSCAD enclosure, one folder per revision: `v0/` (first one-piece sketch), `v1/` (flat 2-part design — lid on top, switch housings exposed; includes its slicer project), `v2/` (recessed key well, drop-in lid with raised deck), `v3/` (drop-in USB notch with lid filler tab), `v4/` (lid split into deck + key plate, adapter shelf — first confirmed-fitting print), `v5/` (`k1_v5.scad`, current — USB corridor raised 2.5mm via `chain_raise` to meet the MacBook port); `desk/v1/` (adapter-less desk variant — board at the rear wall, its own female USB-C facing out the rear for a normal cable; body 88mm). Fit dims are empirically tuned against prints
- `firmware/` — Pico SDK + TinyUSB vendor-HID device (RP2040-Zero; see
  `docs/superpowers/specs/2026-09-08-rp2040-port-design.md`)
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
- **Key count is 3** everywhere: CAD, firmware, and app.
- Dev USB IDs: VID `0x1209` (pid.codes) + test PID until Magic has its own VID.

## Build

- Firmware: Pico SDK flow from `firmware/` (`cmake -B build -G Ninja && ninja -C build`,
  flash the UF2 via BOOTSEL or `picotool`; see `firmware/README.md`).
- Mac app: Xcode project in `mac/`.
- Hardware-in-loop smoke test: Python `hidapi` script (see spec's Testing section).
