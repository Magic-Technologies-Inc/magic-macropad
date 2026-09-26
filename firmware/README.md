# Magic Macropad firmware

Pico SDK firmware for the RP2040-Zero (Waveshare design), codename K1. It
enumerates as a vendor HID device and reports debounced key down/up events:
manufacturer "Magic", product "Magic Macropad", VID 0x1209, PID 0x0001, usage
page 0xFF60. There's no gesture logic on the device. The protocol is in
`main/protocol.h`.

PID `0x0001` is the pid.codes shared *test* PID, a placeholder until the
project has its own.

Building a whole pad? Start with the [build guide](../docs/build-guide.md),
which also covers installing the toolchain. Prebuilt `.uf2` files are attached
to the GitHub releases.

## Build

    export PICO_SDK_PATH=~/pico-sdk        # Pico SDK 2.x with the tinyusb submodule
    export PICO_TOOLCHAIN_PATH=/path/to/arm-gnu-toolchain   # Arm GNU Toolchain 14.x (arm-none-eabi)
    cmake -B build -G Ninja -DCMAKE_BUILD_TYPE=Release
    ninja -C build

Produces `build/k1_firmware.uf2`. On macOS, use Arm's official toolchain
download. Homebrew's `arm-none-eabi-gcc` formula ships without newlib and
fails on `nosys.specs`.

## Flash

Hold BOOT while plugging the board in, then drag the UF2 onto the mounted
`RPI-RP2` volume, or run `picotool load -f build/k1_firmware.uf2`.

## Tests

- Host unit tests (no hardware):
  `cc -I main tests/host/test_debounce.c main/debounce.c -o /tmp/test_debounce && /tmp/test_debounce`
  and `cc -I main tests/host/test_keysync.c main/keysync.c -o /tmp/test_keysync && /tmp/test_keysync`
- Hardware-in-loop: `tools/smoke_test.py` (see its docstring)

Key GPIOs are defined in `main/keys.c` (`K1_KEY_GPIOS`): GPIO 12, 11, and 10
for keys 0, 1, and 2 (the app's Key 1–3). They're active-low (key to GND) with
internal pull-ups. Debug logs go out UART0 on GPIO 0/1 at 115200; wiring it is
optional.

While the host isn't listening (bus suspended, not yet mounted), key edges
are dropped rather than replayed later as live presses; when it's back, any
key whose state changed meanwhile is reported once (`main/keysync.c`).

The onboard WS2812 (GPIO 16) shows a dim per-key color while a key is held
(red/green/blue for keys 0/1/2); see `main/led.c`.
