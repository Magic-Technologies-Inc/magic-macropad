#pragma once
#include "pico/util/queue.h"

// Configures the key GPIOs and returns the debounced-event queue
// (entries are k1_key_event_t, see protocol.h).
queue_t *k1_keys_init(void);

// Call from the main loop. Self-paces to a 1 kHz scan; on each tick it
// samples the keys, debounces, and queues state changes.
void k1_keys_poll(void);
