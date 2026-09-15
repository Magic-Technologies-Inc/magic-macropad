#include "keys.h"
#include "protocol.h"
#include "debounce.h"
#include "pico/stdlib.h"
#include <stdio.h>

// Active-low keys, wired key -> GND.
static const uint K1_KEY_GPIOS[K1_KEY_COUNT] = {10, 11, 12};

static queue_t s_event_queue;
static k1_debounce_t s_db[K1_KEY_COUNT];
static uint64_t s_next_scan_us;

bool k1_keys_pressed(int key)
{
    return s_db[key].stable;
}

queue_t *k1_keys_init(void)
{
    for (int i = 0; i < K1_KEY_COUNT; i++) {
        gpio_init(K1_KEY_GPIOS[i]);
        gpio_set_dir(K1_KEY_GPIOS[i], GPIO_IN);
        gpio_pull_up(K1_KEY_GPIOS[i]);
        k1_debounce_init(&s_db[i], false);
    }
    queue_init(&s_event_queue, sizeof(k1_key_event_t), 32);
    s_next_scan_us = time_us_64();
    return &s_event_queue;
}

void k1_keys_poll(void)
{
    uint64_t now = time_us_64();
    if (now < s_next_scan_us)
        return;
    s_next_scan_us += 1000;
    if (now > s_next_scan_us + 10000)  // loop stalled; resync instead of bursting
        s_next_scan_us = now;

    for (int i = 0; i < K1_KEY_COUNT; i++) {
        bool pressed = !gpio_get(K1_KEY_GPIOS[i]);  // active low
        if (k1_debounce_update(&s_db[i], pressed)) {
            k1_key_event_t ev = {
                .key = (uint8_t)i,
                .state = s_db[i].stable ? K1_KEY_DOWN : K1_KEY_UP,
            };
            if (!queue_try_add(&s_event_queue, &ev))
                printf("k1_keys: event queue full, dropped key %d\n", i);
        }
    }
}
