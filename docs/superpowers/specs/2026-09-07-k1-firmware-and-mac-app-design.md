# K1 Firmware & Magic Keys Mac App — Design

**Date:** 2026-09-07
**Status:** Approved

## Product summary

K1 ("Keys v1") is a thin **3-key** macro pad built on an ESP32-S3. It plugs into a
MacBook's side USB-C port and sits flush along the chassis edge. The device is
**app-required**: it emits raw key events over USB and does nothing on its own.
The companion Mac app, **Magic Keys**, detects gestures (tap / double-tap / hold)
and executes user-configured actions, with a Logitech-Options-style configuration
UI.

> Note: `cad/k1_v1.scad` still models 4 keys (`key_count = 4`); the confirmed spec
> is 3 keys. CAD update is out of scope for this spec.

## Repository layout

Single repo (`K1/`) so protocol changes in firmware and app land together:

- `cad/` — enclosure sources and renders
- `firmware/` — ESP-IDF project
- `mac/` — Magic Keys Xcode project
- `docs/` — specs and plans

## Firmware (ESP-IDF + TinyUSB)

- **Stack:** ESP-IDF 5.x with the `esp_tinyusb` component. The ESP32-S3's native
  USB peripheral enumerates as a single **vendor-defined HID** interface, usage
  page `0xFF60` (QMK raw-HID convention), fixed 8-byte reports, full speed.
- **Input:** 3 keys on GPIOs, scanned by a FreeRTOS task with 5 ms debounce.
- **Deliberately dumb:** firmware sends only `down`/`up` events. All gesture
  timing lives in the app so it can be tuned without reflashing.
- **USB IDs (dev):** VID `0x1209` (pid.codes) with a test PID until Magic has its
  own VID.

### Report protocol (8 bytes, little-endian)

Device → host:

| Byte | Field   | Values                                      |
|------|---------|---------------------------------------------|
| 0    | msg     | `0x01` KEY_EVENT, `0x02` INFO               |
| 1    | key     | 0–2 (KEY_EVENT)                             |
| 2    | state   | `0x00` up, `0x01` down (KEY_EVENT)          |
| 3    | seq     | wrapping counter; app detects dropped reports |
| 4–7  | payload | INFO: fw version major/minor, key count, 0  |

Host → device (output report, 8 bytes): byte 0 `0x10` GET_INFO → device replies
with INFO. This is the extension point for future LED/config messages.

## Magic Keys Mac app

SwiftUI menu-bar app (`MenuBarExtra`), macOS 14+. Four isolated units:

1. **HIDService** — wraps `IOHIDManager`: matches VID/PID, handles
   hotplug/reconnect, parses raw reports into typed `KeyEvent`s, sends GET_INFO
   on connect. The only unit that touches IOKit.
2. **GestureEngine** — pure logic, no I/O. Consumes `KeyEvent`s, emits `tap`,
   `doubleTap`, `hold` per key. Thresholds configurable (defaults: double-tap
   window 300 ms, hold 400 ms). Fully unit-testable with synthetic events.
3. **ActionEngine** — executes the action bound to (key, gesture). V1 actions:
   - Open app
   - Open URL
   - Keyboard shortcut injection (`CGEvent`; requests Accessibility permission
     only when first used)
   - Media control (play/pause, volume up/down, mute)
   - Run shell script
   Actions are a Codable `ActionConfig` enum with an exhaustive switch in
   ActionEngine — adding a later action (e.g. smart-home triggers via the Magic
   FastAPI server) is one new enum case plus one switch arm, and the compiler
   flags every site that must handle it. (Chosen over a `MagicAction` protocol
   because enums get Codable persistence for free.)
4. **ConfigStore** — Codable JSON at
   `~/Library/Application Support/MagicKeys/config.json`, observed by the UI.

### Configuration UI

Logitech-Options-style window: K1 render on the left (placeholder:
`cad/k1_v1_assembled.png`), click a key to select it; right panel shows three
gesture slots (tap / double-tap / hold), each with an action picker and its
parameters. Menu-bar icon reflects connection state. Launch-at-login via
`SMAppService`.

## Error handling

- Disconnect → grayed menu icon, in-flight gesture state reset; IOHIDManager
  auto-resumes on replug.
- Malformed or out-of-sequence reports are logged and dropped.
- Failed actions (script error, missing app) post a user notification; the
  engine never crashes on action failure.

## Testing

- **GestureEngine / ConfigStore:** unit tests with synthetic event streams —
  the bulk of the logic, no hardware needed.
- **HID path:** debug-menu "virtual K1" injects fake reports so the whole app
  runs without hardware.
- **Firmware:** hardware-in-loop smoke test — Python `hidapi` script asserting
  key-event delivery and the GET_INFO round trip.

## Out of scope (v1)

- CAD change from 4 → 3 keys
- LEDs, on-device config storage, OTA/DFU
- Smart-home actions (protocol hook exists via `MagicAction`)
- Windows/Linux hosts
