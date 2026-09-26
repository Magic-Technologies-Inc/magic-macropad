#pragma once
#include "pico/util/queue.h"

// Configures the key GPIOs and returns the debounced-event queue
// (entries are k1_key_event_t, see protocol.h).
queue_t *k1_keys_init(void);

// Call from the main loop. Self-paces to a 1 kHz scan; on each tick it
// samples the keys, debounces, and queues state changes.
void k1_keys_poll(void);

// Debounced state of one key (true = held).
bool k1_keys_pressed(int key);

// True (once) if an edge was dropped because the queue was full since the
// last call, so the USB side can realign the host from the live key state.
bool k1_keys_take_overflow(void);
