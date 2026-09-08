#include "keys.h"
#include "protocol.h"
#include "debounce.h"
#include "driver/gpio.h"
#include "esp_log.h"
#include "freertos/task.h"

static const char *TAG = "k1_keys";

// Active-low keys, wired key -> GND on the breadboard.
static const gpio_num_t K1_KEY_GPIOS[K1_KEY_COUNT] = {
    GPIO_NUM_1, GPIO_NUM_2, GPIO_NUM_3,
};

static QueueHandle_t s_event_queue;

static void scan_task(void *arg)
{
    k1_debounce_t db[K1_KEY_COUNT];
    for (int i = 0; i < K1_KEY_COUNT; i++)
        k1_debounce_init(&db[i], false);

    TickType_t last_wake = xTaskGetTickCount();
    for (;;) {
        for (int i = 0; i < K1_KEY_COUNT; i++) {
            bool pressed = gpio_get_level(K1_KEY_GPIOS[i]) == 0; // active low
            if (k1_debounce_update(&db[i], pressed)) {
                k1_key_event_t ev = {
                    .key = (uint8_t)i,
                    .state = db[i].stable ? K1_KEY_DOWN : K1_KEY_UP,
                };
                if (xQueueSend(s_event_queue, &ev, 0) != pdTRUE)
                    ESP_LOGW(TAG, "event queue full, dropped key %d", i);
            }
        }
        vTaskDelayUntil(&last_wake, pdMS_TO_TICKS(1));
    }
}

QueueHandle_t k1_keys_start(void)
{
    gpio_config_t cfg = {
        .mode = GPIO_MODE_INPUT,
        .pull_up_en = GPIO_PULLUP_ENABLE,
    };
    for (int i = 0; i < K1_KEY_COUNT; i++) {
        cfg.pin_bit_mask = 1ULL << K1_KEY_GPIOS[i];
        ESP_ERROR_CHECK(gpio_config(&cfg));
    }
    s_event_queue = xQueueCreate(32, sizeof(k1_key_event_t));
    configASSERT(s_event_queue);
    xTaskCreate(scan_task, "k1_scan", 3072, NULL, 10, NULL);
    return s_event_queue;
}
