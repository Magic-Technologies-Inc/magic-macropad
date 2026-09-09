#pragma once
#include <stdint.h>

// Onboard WS2812 (RP2040-Zero, GPIO 16). Colors are 0xGGRRBB.
void k1_led_init(void);

// Sets the LED color; no-op if unchanged since the last call.
void k1_led_set(uint32_t grb);

// Per-key held colors (index = key number), dim by design.
uint32_t k1_led_key_color(int key);
