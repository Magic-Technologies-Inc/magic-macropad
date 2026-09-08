#include "usb_hid.h"
#include "protocol.h"
#include "esp_log.h"
#include "freertos/task.h"
#include "tinyusb.h"
#include "class/hid/hid_device.h"
#include <string.h>

static const char *TAG = "k1_usb";

// ---- Descriptors -----------------------------------------------------------

// Vendor-defined raw HID: 8-byte input + 8-byte output report, no report ID.
static const uint8_t k1_report_descriptor[] = {
    0x06, (K1_HID_USAGE_PAGE & 0xFF), (K1_HID_USAGE_PAGE >> 8), // Usage Page (0xFF60)
    0x09, K1_HID_USAGE,             // Usage (0x61)
    0xA1, 0x01,                     // Collection (Application)
    0x09, 0x62,                     //   Usage (vendor, input)
    0x15, 0x00,                     //   Logical Min 0
    0x26, 0xFF, 0x00,               //   Logical Max 255
    0x75, 0x08,                     //   Report Size 8 bits
    0x95, K1_REPORT_SIZE,           //   Report Count 8
    0x81, 0x02,                     //   Input (Data,Var,Abs)
    0x09, 0x63,                     //   Usage (vendor, output)
    0x15, 0x00,
    0x26, 0xFF, 0x00,
    0x75, 0x08,
    0x95, K1_REPORT_SIZE,
    0x91, 0x02,                     //   Output (Data,Var,Abs)
    0xC0                            // End Collection
};

static const tusb_desc_device_t k1_device_descriptor = {
    .bLength = sizeof(tusb_desc_device_t),
    .bDescriptorType = TUSB_DESC_DEVICE,
    .bcdUSB = 0x0200,
    .bDeviceClass = 0x00,
    .bDeviceSubClass = 0x00,
    .bDeviceProtocol = 0x00,
    .bMaxPacketSize0 = CFG_TUD_ENDPOINT0_SIZE,
    .idVendor = K1_USB_VID,
    .idProduct = K1_USB_PID,
    .bcdDevice = 0x0001,
    .iManufacturer = 1,
    .iProduct = 2,
    .iSerialNumber = 3,
    .bNumConfigurations = 1,
};

static const char *k1_string_descriptor[] = {
    (const char[]){0x09, 0x04},  // 0: English (US)
    "Magic",                     // 1: manufacturer
    "K1",                        // 2: product
    "K1-DEV-0001",               // 3: serial
};

enum { ITF_NUM_HID = 0, ITF_NUM_TOTAL };
#define K1_CONFIG_DESC_LEN (TUD_CONFIG_DESC_LEN + TUD_HID_INOUT_DESC_LEN)

static const uint8_t k1_configuration_descriptor[] = {
    TUD_CONFIG_DESCRIPTOR(1, ITF_NUM_TOTAL, 0, K1_CONFIG_DESC_LEN,
                          0 /* no remote wakeup — not implemented */, 100),
    TUD_HID_INOUT_DESCRIPTOR(ITF_NUM_HID, 0, HID_ITF_PROTOCOL_NONE,
                             sizeof(k1_report_descriptor),
                             0x01 /* EP OUT */, 0x81 /* EP IN */,
                             K1_REPORT_SIZE, 5 /* poll ms */),
};

// ---- TinyUSB HID callbacks -------------------------------------------------

static uint8_t s_seq;
static volatile bool s_info_requested;

uint8_t const *tud_hid_descriptor_report_cb(uint8_t instance)
{
    (void)instance;
    return k1_report_descriptor;
}

uint16_t tud_hid_get_report_cb(uint8_t instance, uint8_t report_id,
                               hid_report_type_t report_type,
                               uint8_t *buffer, uint16_t reqlen)
{
    (void)instance; (void)report_id; (void)report_type; (void)buffer; (void)reqlen;
    return 0;
}

void tud_hid_set_report_cb(uint8_t instance, uint8_t report_id,
                           hid_report_type_t report_type,
                           uint8_t const *buffer, uint16_t bufsize)
{
    (void)instance; (void)report_id; (void)report_type;
    if (bufsize >= 1 && buffer[0] == K1_MSG_GET_INFO)
        s_info_requested = true;  // answered from the report task, not this callback context
}

// ---- Report task -----------------------------------------------------------

// Seq only advances on a successful send, so host-side gap detection flags
// real USB losses, not benign drops while the host isn't polling.
static void send_report(uint8_t msg, uint8_t b1, uint8_t b2,
                        uint8_t p0, uint8_t p1, uint8_t p2, uint8_t p3)
{
    uint8_t report[K1_REPORT_SIZE] = {msg, b1, b2, s_seq, p0, p1, p2, p3};
    if (tud_hid_report(0, report, sizeof(report)))
        s_seq++;
    else
        ESP_LOGW(TAG, "report dropped (host not ready)");
}

// Best-effort delivery: while the host isn't polling, key events pile up in
// the 32-slot queue and the oldest overflow is dropped by the scan task.
static void report_task(void *arg)
{
    QueueHandle_t key_queue = (QueueHandle_t)arg;
    k1_key_event_t ev;
    for (;;) {
        if (s_info_requested && tud_hid_ready()) {
            s_info_requested = false;
            send_report(K1_MSG_INFO, 0, 0,
                        K1_FW_VERSION_MAJOR, K1_FW_VERSION_MINOR,
                        K1_KEY_COUNT, 0);
        }
        // Only dequeue when the interface can take a report, so a stalled
        // key-event send never starves a pending GET_INFO reply.
        if (!tud_hid_ready()) {
            vTaskDelay(pdMS_TO_TICKS(10));
            continue;
        }
        if (xQueueReceive(key_queue, &ev, pdMS_TO_TICKS(10)) == pdTRUE)
            send_report(K1_MSG_KEY_EVENT, ev.key, ev.state, 0, 0, 0, 0);
    }
}

void k1_usb_start(QueueHandle_t key_queue)
{
    const tinyusb_config_t tusb_cfg = {
        .device_descriptor = &k1_device_descriptor,
        .string_descriptor = k1_string_descriptor,
        .string_descriptor_count =
            sizeof(k1_string_descriptor) / sizeof(k1_string_descriptor[0]),
        .external_phy = false,
        .configuration_descriptor = k1_configuration_descriptor,
    };
    ESP_ERROR_CHECK(tinyusb_driver_install(&tusb_cfg));
    xTaskCreate(report_task, "k1_usb_report", 4096, key_queue, 9, NULL);
    ESP_LOGI(TAG, "USB HID started (VID %04x PID %04x)", K1_USB_VID, K1_USB_PID);
}
