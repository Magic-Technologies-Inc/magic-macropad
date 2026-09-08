#pragma once
#include "freertos/FreeRTOS.h"
#include "freertos/queue.h"

// Installs TinyUSB and starts the report task, which drains key events
// from `key_queue` into HID input reports (see protocol.h).
void k1_usb_start(QueueHandle_t key_queue);
