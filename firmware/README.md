# K1 Firmware

Pico SDK firmware for the RP2040-Zero (Waveshare design). Enumerates as a
vendor HID device (VID 0x1209, PID 0x0001, usage page 0xFF60) and reports
debounced key down/up events. Protocol: `main/protocol.h`. No gesture logic
on-device.

## Build

    export PICO_SDK_PATH=~/pico-sdk
    export PICO_TOOLCHAIN_PATH=~/toolchains/arm-gnu-toolchain-14.2.rel1-darwin-arm64-arm-none-eabi
    cmake -B build -G Ninja -DCMAKE_BUILD_TYPE=Release
    ninja -C build

Produces `build/k1_firmware.uf2`.

## Flash

Hold BOOT while plugging the board in, then drag the UF2 onto the mounted
`RPI-RP2` volume — or `picotool load -f build/k1_firmware.uf2`.

## Tests

- Host unit tests (no hardware):
  `cc -I main tests/host/test_debounce.c main/debounce.c -o /tmp/test_debounce && /tmp/test_debounce`
- Hardware-in-loop: `tools/smoke_test.py` (see its docstring)

Key GPIOs are defined in `main/keys.c` (`K1_KEY_GPIOS`) — GPIO 26/27/28 (the
pad cluster at the USB end), active-low (key to GND), internal pull-ups.
Debug logs: UART0 on GPIO 0/1 at 115200 (optional to wire).
