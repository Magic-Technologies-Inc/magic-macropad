# Build guide

This guide takes you from parts to a working Magic Macropad: print the
enclosure, flash the board, wire three switches, put it together, and install
the Mac app. Most of the time is print time. The soldering is six short wires.

1. [Choose a variant](#1-choose-a-variant)
2. [Gather parts and tools](#2-gather-parts-and-tools)
3. [Print the enclosure](#3-print-the-enclosure)
4. [Flash the firmware](#4-flash-the-firmware)
5. [Install the app](#5-install-the-app)
6. [Wire and test the switches](#6-wire-and-test-the-switches)
7. [Assemble](#7-assemble)
8. [Troubleshooting](#8-troubleshooting)
9. [Changing the enclosure](#9-changing-the-enclosure)

## 1. Choose a variant

| | Side-mount | Desk |
|---|---|---|
| Files | [`cad/v5/`](../cad/v5/) | [`cad/desk/v2/`](../cad/desk/v2/) |
| How it connects | Plugs straight into a MacBook's USB-C port and sits flush along its side | Sits on the desk, with a normal USB-C cable at the back |
| Extra parts | A 90° USB-C adapter and a USB-C coupler | None |
| Status | An earlier revision (v4) was confirmed to fit; v5 raises the plug 2.5 mm to meet the port. Check the plug height against your Mac before a final print. | Not test-printed yet, so expect to tune it (see [Troubleshooting](#8-troubleshooting)) |

The side-mount version comes in two mirror-image sets. With the pad running
from the port toward the front of the Mac, keys up:

- The standard files (`k1_tray.stl`, `k1_deck.stl`) fit a USB-C port on the
  Mac's **right** side.
- The `_mirror` files fit the **left** side, which is the only side with USB-C
  on a MacBook Air.
- The key plate is symmetric, so `k1_plate.stl` works for either.

Either way, the USB opening in the tray's side wall must face the Mac.

## 2. Gather parts and tools

**Parts**

| Qty | Part | Notes |
|---|---|---|
| 1 | RP2040-Zero | Waveshare's board, or a pin-compatible clone |
| 3 | MX-style switches | Plate-mount, through-hole. Any feel you like. |
| 3 | MX keycaps | Standard 1u (18 mm wide). Any MX keycap model you print, or off-the-shelf caps. |
| ~30 cm | Thin hookup wire | 28–30 AWG fits the shallow cavity best |
| 1 | USB-C **data** cable | Both variants: for flashing and testing, and it's the desk version's cable. A charge-only cable won't work. |
| 1 | 90° USB-C adapter, female to male, **left/right-angle** | Side-mount only. Plugged into the Mac, its socket must face along the Mac's side, not up or down. Its plug base has to fit an 11.5 × 6 mm opening. |
| 1 | Straight USB-C male-to-male coupler | Side-mount only. With the coupler plugged into the adapter, measure from the back of the adapter's body to the tip of the coupler's free plug: the enclosure expects about 44 mm. |

USB-C adapters vary. If yours don't match, see
[Changing the enclosure](#9-changing-the-enclosure).

**Tools:** a 3D printer, a soldering iron and solder, flush cutters, and wire
strippers. For the software you need a Mac with [Homebrew](https://brew.sh)
and Xcode 26, which needs macOS 15.6 or later; the app itself runs on
macOS 15 or later. [OpenSCAD](https://openscad.org) is only needed if you
change the enclosure.

## 3. Print the enclosure

![Exploded view of the side-mount enclosure: the tray at the bottom, the deck and key plate above it, then the switches and keycaps](../cad/v5/k1_v5_exploded.png)

**The parts, and the words this guide uses for them**

- The **tray** is the base.
- The **lid** comes in two pieces:
  - the **deck**, the long raised cover at the USB end
  - the **key plate**, the flat plate the switches clip into
- **Rear** means the USB end, and **front** means the key end.
- Inside the tray:
  - the lid rests on a **ledge**
  - the board sits in a shallow **pocket** in that ledge
- Side-mount only:
  - the adapter's body sits on a raised **shelf** between the pocket and the
    rear wall
  - its plug leaves through a **notch** in the side wall, which a **tab** on
    the deck closes

Print three parts in PLA:

| Part | Side-mount (`cad/v5/`) | Desk (`cad/desk/v2/`) |
|---|---|---|
| Tray | `k1_tray.stl` (right) or `k1_tray_mirror.stl` (left) | `k1_tray.stl` |
| Deck | `k1_deck.stl` (right) or `k1_deck_mirror.stl` (left) | `k1_deck.stl` |
| Key plate | `k1_plate.stl` | `k1_plate.stl` |

- **Orientation:** print the STLs as they come. The deck is already flipped
  upside down so it needs no supports.
- **Settings used for the prototype:** Bambu Lab A1, 0.4 mm nozzle, 0.20 mm
  layers, 2 walls, 15% infill, no supports, auto brim.
- **Bambu Studio:** [`cad/v5/k1_v5_m.3mf`](../cad/v5/k1_v5_m.3mf) is a
  ready-made project with the left-side (mirror) set.

The fit clearances were tuned on that printer. If your lid comes out too
tight or too loose, see [Troubleshooting](#8-troubleshooting).

## 4. Flash the firmware

Flash the board before you solder anything, so you know it works.

**Get the firmware.** Download the `.uf2` file from the latest release on the
[Releases page](https://github.com/Magic-Technologies-Inc/magic-macropad/releases).
You only need to build it yourself if you change the firmware; see
[Building the firmware yourself](#building-the-firmware-yourself) below.

**Flash.**

1. Hold the **BOOT** button on the RP2040-Zero while you plug it into the Mac
   with the data cable. It shows up as a drive called `RPI-RP2`.
2. Copy the `.uf2` file onto that drive. The board reboots into the firmware
   and the drive disappears.

To check it worked, this should print a line for the board:

```bash
ioreg -p IOUSB -l -w0 | grep -i "Magic Macropad"
```

### Building the firmware yourself

**Install the toolchain (once).** You need CMake, Ninja, picotool, the Pico SDK
with its TinyUSB submodule, and Arm's compiler:

```bash
brew install cmake ninja picotool
git clone --branch 2.1.1 https://github.com/raspberrypi/pico-sdk.git ~/pico-sdk
git -C ~/pico-sdk submodule update --init lib/tinyusb
```

Then download the Arm GNU Toolchain from
[Arm's downloads page](https://developer.arm.com/downloads/-/arm-gnu-toolchain-downloads).
Pick the macOS `.tar.xz` for the **AArch32 bare-metal target
(`arm-none-eabi`)**: `darwin-arm64` for Apple silicon, `darwin-x86_64` for
Intel. Unpack it:

```bash
mkdir -p ~/toolchains
tar -xf ~/Downloads/arm-gnu-toolchain-*-arm-none-eabi.tar.xz -C ~/toolchains
```

Homebrew's `arm-none-eabi-gcc` won't work, because it ships without newlib.

> Prefer a guided setup? The official **Raspberry Pi Pico** extension for
> VS Code installs the SDK and toolchain under `~/.pico-sdk`. Point the two
> variables below at those folders instead.

**Build.** From the repo root, pointing `PICO_TOOLCHAIN_PATH` at the folder
you unpacked:

```bash
cd firmware
export PICO_SDK_PATH=~/pico-sdk
export PICO_TOOLCHAIN_PATH=~/toolchains/arm-gnu-toolchain-14.2.rel1-darwin-arm64-arm-none-eabi
cmake -B build -G Ninja -DCMAKE_BUILD_TYPE=Release
ninja -C build
```

That produces `firmware/build/k1_firmware.uf2`; flash it the same way.

## 5. Install the app

From the repo root:

```bash
brew install xcodegen
cd mac
xcodegen generate
xcodebuild -project MagicKeys.xcodeproj -scheme MagicKeys -configuration Release -derivedDataPath DerivedData build
cp -R "DerivedData/Build/Products/Release/Magic Macropad.app" /Applications/
open "/Applications/Magic Macropad.app"
```

- **Signing:** you don't need an Apple developer account. The app is signed
  for your Mac only.
- **Updating later:** quit the app and delete the old copy from
  `/Applications` before copying the new one in.
- **Just trying it:** after `xcodegen generate`, open `MagicKeys.xcodeproj` in
  Xcode and press ⌘R.

**First launch.** The app has no window and no Dock icon; it lives in the menu
bar.

1. Find its icon: three stacked keys in a rounded outline. The keys fill in
   while the pad is connected. On a MacBook with a notch, a crowded menu bar
   can hide the icon behind the notch.
2. Click the icon to open the panel.
3. Click **Permissions** at the panel's top right. It closes and reopens
   System Settings on the Accessibility page. Turn on Magic Macropad there: the
   app needs that to send keystrokes, media keys, and pastes. Allow
   notifications too, so failed actions can tell you why.
4. Optional: tick **Launch at Login** in the panel's footer.

macOS ties the Accessibility grant to the exact build. After you rebuild the
app, click **Permissions** again: it clears the stale entry and walks you
through turning it back on.

**Out of the box** the keys come with these bindings:

| | Tap | Double tap | Triple tap | Hold |
|---|---|---|---|---|
| Key 1 | Play / Pause | Next Track | Previous Track | Mute |
| Key 2 | Mission Control | Screenshot Region | — | Lock Screen |
| Key 3 | New Claude Chat | New ChatGPT Chat | Improve Writing | Dictation |

**Changing them.** Pick a key on the drawing, click one of its gesture rows,
and choose an action. The chips at the top add per-app profiles: a profile's
bindings apply while that app is in front, and anything it leaves unset falls
back to the default profile. No board yet? The **Test keys** menu in the
footer simulates presses.

## 6. Wire and test the switches

Each switch has two pins. One goes to a GPIO pad on the board and the other to
ground:

```
RP2040-Zero                switches
  GP12 ───────────────── Key 1 ─┐
  GP11 ───────────────── Key 2 ─┤
  GP10 ───────────────── Key 3 ─┤
  GND  ─────────────────────────┘   (daisy-chain the three ground pins)
```

- **No resistors are needed.** The firmware turns on the chip's internal
  pull-ups.
- **Where the pads are:** GP9–GP13 run along the board's short edge opposite
  the USB-C socket, so GP10, GP11, and GP12 are the middle three. GND is on a
  long edge near the socket. Check against your board's pinout diagram.
- **Which switch is which:** Key 1 is the switch nearest the USB end; the app
  draws it at the top, next to the plug. Key 3 is at the front.

**Solder it:**

1. Snap the three switches into the key plate from the top. They click in.
2. Solder a wire from one pin of each switch to its GPIO pad. MX switches
   have no polarity, so either pin works.
3. Solder the switches' other pins together, and to a GND pad.
4. Keep every joint low and let the wires drop into the cavity below the
   board. There's only about 0.6 mm between the board's key end and the key
   plate.
5. Leave enough slack to lift the plate off the tray, but no more. Everything
   has to fold into the 7 mm cavity under the plate.
6. Clip the switch pins short after soldering. Full-length pins don't fit.
7. Route the ground wire for your variant:
   - **Side-mount:** the board's long edges rest on narrow ledges, so plan how
     the ground wire reaches the cavity before you solder it.
   - **Desk:** the rear half of one seat rail is cut away, so solder joints on
     that edge of the board clear it.

**Test before you close it up.** Quit the app first. While it runs, holding a
key fires its Hold action, and Key 2's default Hold locks the screen.

1. Plug the board in and press each switch. The board's LED lights while a key
   is held: **red** for Key 1, **green** for Key 2, **blue** for Key 3. No
   light? Check both wires on that switch.
2. To confirm the order, run the self-test from the repo root and follow its
   prompts:

   ```bash
   cd firmware/tools
   python3 -m venv .venv
   .venv/bin/pip install -r requirements.txt
   .venv/bin/python smoke_test.py
   ```

   It checks that the board answers the app's info request, then asks you to
   press Key 1, Key 2, and Key 3 in turn. It ends with `PASS`, or says what
   went wrong.
3. Keys in the wrong order? Swap the GPIO wires, or just bind the keys in the
   app however they're wired.
4. Open the app again and tap Key 1: by default it plays or pauses music.

## 7. Assemble

**Side-mount**

1. Plug the coupler into the board's USB-C socket, then plug the 90° adapter
   onto the coupler.
2. Lower the board, coupler, and adapter into the tray as one piece. The board
   sits in its pocket with its USB-C socket toward the rear. The adapter's body
   rests on the shelf behind the board, and its plug drops into the notch in
   the side wall.
3. Fold the wires into the cavity and drop the key plate into the front of the
   tray. The end with the two small side bumps goes toward the front. Press
   that end down until the bumps click.
4. Press the deck into the rear of the tray. Its front edge tucks over the key
   plate's rear edge, and its tab fills the top of the notch. Press until it
   clicks.
5. Push the keycaps onto the switches.
6. Plug the pad into your MacBook's port. It rests along the side of the Mac.

**Desk**

1. Put the board's USB-C socket into the opening in the tray's rear wall first,
   then lower the board into its pocket. Nothing clips it in: the rear opening
   and the deck hold it in place.
2. Follow side-mount steps 3–5, then plug in the USB-C cable.

**Opening it again:** unplug it first, from the Mac or the cable, because
pressing the deck pushes its tab down into the USB opening. Then press down on
the deck right above the USB end. The deck rocks on its ledge and its front
pops up. Lift the deck out, then the key plate.

## 8. Troubleshooting

| Problem | What to do |
|---|---|
| The app says "Not connected" | Run the `ioreg` check from step 4. If the board doesn't show up, re-flash it, and make sure the USB chain or cable is fully seated and carries data. |
| The LED lights but actions don't run | Keystroke, media, and paste actions need Accessibility. Click **Permissions** in the panel, and do it again after every rebuild. |
| No LED when pressing a key | Check that switch's two wires: one to its GPIO pad, one to ground. |
| A shell-script action fails | The notification says why. The AI presets need the Claude CLI (`claude`) installed and signed in. Other presets list what they need in their first line. |
| Toggle Dark Mode (or a script that controls another app) does nothing | Allow Magic Macropad under System Settings → Privacy & Security → Automation. |
| The side-mount plug sits too high or low for your Mac's port | The plug's center sits 11 mm above the bottom of the pad. Measure your port's center above the desk and change `chain_raise` by the difference (bigger is higher). Then reprint the tray and deck. |
| The lid won't drop in, or rattles | Change `fit_clr` (clearance per side), then reprint the deck and key plate. |
| The lid won't click in, or pops out | Change the snap bump sizes: `snap_r` and `snap_grv_r` for the deck, `plate_snap_r` and `plate_grv_r` for the key plate. |
| Desk version: the cable doesn't click all the way in | Measure how far the board's USB-C socket sticks out past the PCB's edge, and set `seat_x0` to 0.8 plus that, in mm. Smaller values move the socket toward the outside. Then reprint the tray. |

## 9. Changing the enclosure

The enclosure is parametric OpenSCAD. Each variant's `.scad` file has its
settings near the top, so edit those and re-export the parts you reprint:

```bash
cd cad/v5
openscad -D 'part="tray"' -o k1_tray.stl k1_v5.scad
openscad -D 'part="deck"' -o k1_deck.stl k1_v5.scad
openscad -D 'part="plate"' -o k1_plate.stl k1_v5.scad
```

- **Left-side (mirror) set:** add `-D 'mirrored=true'` and write the
  `_mirror` file names, for example
  `openscad -D 'part="tray"' -D 'mirrored=true' -o k1_tray_mirror.stl k1_v5.scad`.
- **Desk:** the same commands work in `cad/desk/v2/` with `k1_desk_v2.scad`.
- **Different USB parts:**
  - `usb_body_th` sets the shelf height for your adapter's body thickness.
  - A chain shorter or longer than 44 mm moves the board: change `seat_x0` by
    the difference, and `body_len` too if the chain is longer.
