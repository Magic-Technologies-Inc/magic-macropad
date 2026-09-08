# K1 Firmware

ESP-IDF 5.x firmware for the ESP32-S3 (Seeed XIAO ESP32-S3). Enumerates as a
vendor HID device (VID 0x1209, PID 0x0001, usage page 0xFF60) and reports
debounced key down/up events. Protocol: `main/protocol.h`. No gesture logic
on-device.

## Build & flash

    source ~/esp/esp-idf/export.sh
    idf.py set-target esp32s3   # first time only
    idf.py build
    idf.py flash monitor

## Tests

- Host unit tests (no hardware):
  `cc -I main tests/host/test_debounce.c main/debounce.c -o /tmp/test_debounce && /tmp/test_debounce`
- Hardware-in-loop: `tools/smoke_test.py` (see its docstring)

Key GPIOs are defined in `main/keys.c` (`K1_KEY_GPIOS`) — GPIO 1/2/3
(XIAO pads D0/D1/D2), active-low (key to GND), internal pull-ups.
