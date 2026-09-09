#include "pico/stdlib.h"
#include "keys.h"
#include "usb_hid.h"
#include "led.h"
#include "protocol.h"
#include <stdio.h>

// Onboard LED mirrors the debounced key state: a per-key color while any
// key is held (highest-index key wins), off otherwise.
static void update_led(void)
{
    uint32_t color = 0;
    for (int i = 0; i < K1_KEY_COUNT; i++)
        if (k1_keys_pressed(i))
            color = k1_led_key_color(i);
    k1_led_set(color);
}

int main(void)
{
    stdio_init_all();
    printf("K1 firmware boot, fw %d.%d\n",
           K1_FW_VERSION_MAJOR, K1_FW_VERSION_MINOR);

    queue_t *key_queue = k1_keys_init();
    k1_led_init();
    k1_usb_init();

    for (;;) {
        k1_keys_poll();
        update_led();
        k1_usb_task(key_queue);
    }
}
