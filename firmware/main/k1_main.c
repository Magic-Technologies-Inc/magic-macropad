#include "pico/stdlib.h"
#include "keys.h"
#include "usb_hid.h"
#include "protocol.h"
#include <stdio.h>

int main(void)
{
    stdio_init_all();
    printf("K1 firmware boot, fw %d.%d\n",
           K1_FW_VERSION_MAJOR, K1_FW_VERSION_MINOR);

    queue_t *key_queue = k1_keys_init();
    k1_usb_init();

    for (;;) {
        k1_keys_poll();
        k1_usb_task(key_queue);
    }
}
