#include "esp_log.h"
#include "keys.h"
#include "protocol.h"
#include "freertos/FreeRTOS.h"
#include "freertos/queue.h"

static const char *TAG = "k1";

void app_main(void)
{
    ESP_LOGI(TAG, "K1 firmware boot, fw %d.%d",
             K1_FW_VERSION_MAJOR, K1_FW_VERSION_MINOR);
    QueueHandle_t q = k1_keys_start();

    // Temporary: log events until USB lands (replaced in Task 5).
    k1_key_event_t ev;
    for (;;) {
        if (xQueueReceive(q, &ev, portMAX_DELAY) == pdTRUE)
            ESP_LOGI(TAG, "key %d %s", ev.key,
                     ev.state == K1_KEY_DOWN ? "down" : "up");
    }
}
