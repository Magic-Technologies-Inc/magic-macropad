// protocol.h — K1 <-> Magic Keys wire protocol. 8-byte HID reports.
// This file is the single source of truth; the Mac app's Protocol.swift mirrors it.
#pragma once
#include <stdint.h>

#define K1_KEY_COUNT        3
#define K1_REPORT_SIZE      8

#define K1_USB_VID          0x1209  // pid.codes (dev)
#define K1_USB_PID          0x0001  // pid.codes test PID (dev)
#define K1_HID_USAGE_PAGE   0xFF60
#define K1_HID_USAGE        0x61

#define K1_FW_VERSION_MAJOR 0
#define K1_FW_VERSION_MINOR 1

// Device -> host, byte 0
#define K1_MSG_KEY_EVENT    0x01
#define K1_MSG_INFO         0x02
// Host -> device, byte 0
#define K1_MSG_GET_INFO     0x10

// KEY_EVENT byte 2
#define K1_KEY_UP           0x00
#define K1_KEY_DOWN         0x01

typedef struct {
    uint8_t key;    // 0..K1_KEY_COUNT-1
    uint8_t state;  // K1_KEY_UP / K1_KEY_DOWN
} k1_key_event_t;
