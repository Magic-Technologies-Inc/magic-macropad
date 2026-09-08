#pragma once
#include "freertos/FreeRTOS.h"
#include "freertos/queue.h"

// Starts the 1 kHz scan task. Debounced key events are posted to the
// returned queue as k1_key_event_t (see protocol.h).
QueueHandle_t k1_keys_start(void);
