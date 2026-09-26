# Magic Macropad

A thin, three-key macropad that plugs straight into your MacBook's side USB-C
port and sits flush along the chassis, plus the menu-bar app that turns each
key into tap, double-tap, triple-tap, and hold actions.

![Exploded view of the side-mount enclosure: tray, drop-in lid, three MX switches, and keycaps](cad/v5/k1_v5_exploded.png)

> **Status: early prototype.** The firmware and app work, and the enclosures
> are tuned against real prints. Expect rough edges. The hardware's codename
> is **K1**, and you'll see it in file names and code.

## Features

- **Three keys, twelve bindings.** Each key does something different on tap,
  double-tap, triple-tap, and hold.
- **Per-app profiles.** Bindings follow the frontmost app and fall back to
  your Default profile.
- **Built-in actions:**
  - Open an app, URL, file, or folder
  - Keyboard shortcuts, with a recorder
  - Media: play/pause, previous/next, volume, mute
  - Paste a text snippet
  - System: app switcher (⌘Tab), mic mute, lock screen, display sleep, dark
    mode, region screenshot, Mission Control, keep-awake
  - AI: new Claude or ChatGPT chat, dictation
  - Shell scripts, with a preset library that includes Claude CLI helpers
    like "Improve Writing" for whatever's on the clipboard
- **No drivers.** The device is a vendor-defined USB HID device, so macOS
  needs nothing installed. Gesture timing lives in the app, so you can tune
  it without reflashing.
- **Key-press light.** The board's RGB LED glows red, green, or blue while a
  key is held.

There's also one easter egg. Try pressing all three keys at once.

## How it works

    keys ──► RP2040 firmware ─── USB HID ───► Magic Macropad app
             debounce, down/up events          HIDService → GestureEngine
             8-byte reports + sequence byte      → ActionEngine (per-app profiles)

The firmware only reports debounced key down/up events. It uses a
vendor-defined HID interface (usage page `0xFF60`, 8-byte reports with a
sequence byte). The app does everything else: gesture detection, profiles, and
running actions. The full design is in
[`docs/superpowers/specs/`](docs/superpowers/specs/).

## Build one

### Parts

| Part | Notes |
|---|---|
| RP2040-Zero | Waveshare's board or a pin-compatible clone |
| 3 × MX-style switches | Plate-mount, through-hole. Clip the pins short after soldering; the cavity is 7 mm deep. |
| 3 × MX keycaps | 18 mm wide. 3D-printed or off-the-shelf. |
| Right-angle USB-C adapter + USB-C coupler | Side-mount build only. Together they bridge the board to the MacBook's port; the enclosure is sized for a ~44 mm chain. |
| USB-C cable | Desk build only |
| Hookup wire | Each switch connects to a GPIO pin and GND |

### 1. Print the enclosure

There are two variants. Each is a tray plus a drop-in lid, which is split into
a deck and a key plate.

- **Side-mount**, in [`cad/v5/`](cad/v5/): hangs off the MacBook's side USB-C
  port. The `*_mirror.stl` files fit the other side.
- **Desk**, in [`cad/desk/v2/`](cad/desk/v2/): sits on the desk and takes a
  normal USB-C cable at the back.

The OpenSCAD sources are parametric, and each lists its export commands at the
top. Some revisions include Bambu Studio projects (`.3mf`, sliced for an A1 at
0.20 mm). Older revisions are kept for reference.

### 2. Wire it

Wire each switch between a GPIO pin and GND. The firmware uses internal
pull-ups, so there's nothing else to add. Key 1 goes to GPIO 12, key 2 to
GPIO 11, and key 3 to GPIO 10.

### 3. Flash the firmware

You need the [Pico SDK](https://github.com/raspberrypi/pico-sdk) 2.x and the
Arm GNU toolchain. [firmware/README.md](firmware/README.md) has the details.

    cd firmware
    export PICO_SDK_PATH=~/pico-sdk
    cmake -B build -G Ninja -DCMAKE_BUILD_TYPE=Release && ninja -C build

Hold **BOOT** while plugging the board in, then copy `build/k1_firmware.uf2`
onto the `RPI-RP2` drive.

### 4. Install the app

You need macOS 15 or later and Xcode 26; the app icon is an Icon Composer
file.

    brew install xcodegen
    cd mac && xcodegen generate
    open MagicKeys.xcodeproj    # then Run

**Magic Macropad** lives in the menu bar. Grant Accessibility when it asks;
that's how it sends keystrokes. No board yet? The **Test keys** menu fires
virtual presses.

Some shell presets need other command-line tools, such as the Claude CLI
(`claude`) or GitHub CLI (`gh`). Each preset notes what it needs.

## Repository layout

- `cad/`: OpenSCAD enclosure, one folder per revision (`v5/` and `desk/v2/`
  are current)
- `firmware/`: Pico SDK and TinyUSB firmware for the RP2040-Zero
- `mac/`: the menu-bar app (SwiftUI). `MagicKeysCore/` holds the unit-tested
  core. The target and package still use the older "Magic Keys" name.
- `docs/superpowers/`: design specs and implementation plans. They predate the
  Magic Macropad name, so they still say "K1" and "Magic Keys".

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md).

## License

Magic Macropad (hardware designs, firmware, and app) is © 2026 Magic
Technologies Inc., licensed under
[CC BY-NC-SA 4.0](https://creativecommons.org/licenses/by-nc-sa/4.0/). The
full text is in [LICENSE](LICENSE).

In plain English (the license itself is what counts):

- ✅ You can build one, change it, and share your changes. Credit Magic and
  keep the same license.
- ❌ You can't sell devices, kits, printed parts, or the software, modified or
  not.
- **Additional permission:** beyond CC BY-NC-SA 4.0, Magic Technologies Inc.
  lets you use a Magic Macropad you built yourself, along with its firmware
  and app, for your work, including at a for-profit company. This covers use
  only. It doesn't allow selling, renting, or otherwise commercially
  distributing devices, kits, parts, design files, or software.

For commercial licensing, get in touch at [usemagic.io](https://usemagic.io).

Some bundled fonts, a sound, and two small firmware files are third-party and
keep their own licenses; see [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md). The Magic name and logo aren't
licensed at all; see [TRADEMARKS.md](TRADEMARKS.md).

---

Made by [Magic](https://usemagic.io).
