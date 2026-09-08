#include "esp_log.h"
#include "keys.h"
#include "usb_hid.h"
#include "protocol.h"

static const char *TAG = "k1";

void app_main(void)
{
    ESP_LOGI(TAG, "K1 firmware boot, fw %d.%d",
             K1_FW_VERSION_MAJOR, K1_FW_VERSION_MINOR);
    k1_usb_start(k1_keys_start());
}
