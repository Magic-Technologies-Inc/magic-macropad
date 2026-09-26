#include "usb_hid.h"
#include "protocol.h"
#include "tusb.h"
#include <stdio.h>
#include <string.h>

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
    NULL,             // 0: language, handled specially in the callback
    "Magic",          // 1: manufacturer
    "Magic Macropad", // 2: product
    "K1-DEV-0001",    // 3: serial
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

// ---- TinyUSB device callbacks ----------------------------------------------
// (esp_tinyusb supplied these from its config struct; on the Pico SDK we
// implement them directly.)

uint8_t const *tud_descriptor_device_cb(void)
{
    return (uint8_t const *)&k1_device_descriptor;
}

uint8_t const *tud_descriptor_configuration_cb(uint8_t index)
{
    (void)index;
    return k1_configuration_descriptor;
}

uint16_t const *tud_descriptor_string_cb(uint8_t index, uint16_t langid)
{
    (void)langid;
    static uint16_t desc[32];
    uint8_t len;

    if (index == 0) {
        desc[1] = 0x0409;  // English (US)
        len = 1;
    } else {
        if (index >= sizeof(k1_string_descriptor) / sizeof(k1_string_descriptor[0]))
            return NULL;
        const char *s = k1_string_descriptor[index];
        len = (uint8_t)strlen(s);
        if (len > 31)
            len = 31;
        for (uint8_t i = 0; i < len; i++)
            desc[1 + i] = (uint16_t)s[i];  // ASCII -> UTF-16LE
    }
    desc[0] = (uint16_t)((TUSB_DESC_STRING << 8) | (2 * len + 2));
    return desc;
}

// ---- HID callbacks ---------------------------------------------------------

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
        s_info_requested = true;  // answered from k1_usb_task, not this callback context
}

// ---- Report pump -----------------------------------------------------------

// Seq only advances on a successful send, so host-side gap detection flags
// real USB losses, not benign drops while the host isn't polling.
static void send_report(uint8_t msg, uint8_t b1, uint8_t b2,
                        uint8_t p0, uint8_t p1, uint8_t p2, uint8_t p3)
{
    uint8_t report[K1_REPORT_SIZE] = {msg, b1, b2, s_seq, p0, p1, p2, p3};
    if (tud_hid_report(0, report, sizeof(report)))
        s_seq++;
    else
        printf("k1_usb: report dropped (host not ready)\n");
}

// Best-effort delivery: while the host isn't polling, key events pile up in
// the 32-slot queue and overflow is dropped by the scan side. One report per
// call — the IN endpoint fits one transfer at a time and the main loop spins
// far faster than the host polls.
void k1_usb_task(queue_t *key_queue)
{
    tud_task();

    if (!tud_hid_ready())
        return;
    // Answer a pending GET_INFO before key events, so a backlog of key
    // events never starves the info reply.
    if (s_info_requested) {
        s_info_requested = false;
        send_report(K1_MSG_INFO, 0, 0,
                    K1_FW_VERSION_MAJOR, K1_FW_VERSION_MINOR,
                    K1_KEY_COUNT, 0);
        return;
    }
    k1_key_event_t ev;
    if (queue_try_remove(key_queue, &ev))
        send_report(K1_MSG_KEY_EVENT, ev.key, ev.state, 0, 0, 0, 0);
}

void k1_usb_init(void)
{
    tusb_init();
    printf("k1_usb: USB HID started (VID %04x PID %04x)\n", K1_USB_VID, K1_USB_PID);
}
