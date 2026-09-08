#!/usr/bin/env python3
"""K1 hardware-in-loop smoke test.

Verifies: device opens, GET_INFO round-trips, and key events arrive
with correct shape and sequence numbers. Run with the K1 plugged in:

    python3 -m venv .venv && .venv/bin/pip install -r requirements.txt
    .venv/bin/python smoke_test.py
"""
import sys
import time

import hid

VID, PID = 0x1209, 0x0001
MSG_KEY_EVENT, MSG_INFO, MSG_GET_INFO = 0x01, 0x02, 0x10
KEY_COUNT = 3


def fail(msg):
    print(f"FAIL: {msg}")
    sys.exit(1)


def main():
    try:
        dev = hid.device()
        dev.open(VID, PID)
    except OSError:
        fail(f"no HID device {VID:04x}:{PID:04x} — is the K1 plugged in?")
    dev.set_nonblocking(False)
    print(f"opened {dev.get_manufacturer_string()} {dev.get_product_string()}")

    # GET_INFO round trip. First byte 0x00 is the report id (none).
    dev.write([0x00, MSG_GET_INFO] + [0] * 7)
    report = dev.read(8, timeout_ms=1000)
    if not report:
        fail("no INFO reply within 1 s")
    if report[0] != MSG_INFO:
        fail(f"expected INFO (0x02), got 0x{report[0]:02x}")
    major, minor, keys = report[4], report[5], report[6]
    if keys != KEY_COUNT:
        fail(f"device reports {keys} keys, expected {KEY_COUNT}")
    print(f"INFO ok: fw {major}.{minor}, {keys} keys")

    # Key events: one press+release per key, in order.
    print("press and release each key once, left to right (30 s timeout)...")
    deadline = time.time() + 30
    seen, last_seq = [], None
    while len(seen) < KEY_COUNT * 2 and time.time() < deadline:
        report = dev.read(8, timeout_ms=500)
        if not report:
            continue
        if report[0] != MSG_KEY_EVENT:
            continue
        key, state, seq = report[1], report[2], report[3]
        if key >= KEY_COUNT or state not in (0, 1):
            fail(f"malformed report: {report}")
        if last_seq is not None and seq != (last_seq + 1) % 256:
            fail(f"sequence gap: {last_seq} -> {seq}")
        last_seq = seq
        seen.append((key, state))
        print(f"  key {key} {'down' if state else 'up'} (seq {seq})")
    if len(seen) < KEY_COUNT * 2:
        fail(f"timed out; saw {len(seen)}/{KEY_COUNT * 2} events")

    print("PASS: smoke test complete")


if __name__ == "__main__":
    main()
