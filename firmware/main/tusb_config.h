// TinyUSB configuration for the K1 vendor-HID device.
// (With ESP-IDF this lived in esp_tinyusb + sdkconfig; on the Pico SDK it's ours.)
#pragma once

#define CFG_TUSB_RHPORT0_MODE OPT_MODE_DEVICE
#define CFG_TUSB_OS           OPT_OS_PICO

#define CFG_TUD_ENDPOINT0_SIZE 64

#define CFG_TUD_HID    1
#define CFG_TUD_CDC    0
#define CFG_TUD_MSC    0
#define CFG_TUD_MIDI   0
#define CFG_TUD_VENDOR 0

// Must hold the largest report (K1_REPORT_SIZE = 8).
#define CFG_TUD_HID_EP_BUFSIZE 8
