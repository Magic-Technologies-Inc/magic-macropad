#pragma once
#include "pico/util/queue.h"

// Initializes the TinyUSB device stack.
void k1_usb_init(void);

// Call from the main loop. Services USB and drains key events from
// `key_queue` into HID input reports (see protocol.h).
void k1_usb_task(queue_t *key_queue);
