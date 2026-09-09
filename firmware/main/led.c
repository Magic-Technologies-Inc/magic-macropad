#include "led.h"
#include "protocol.h"
#include "hardware/pio.h"
#include "ws2812.pio.h"

#define K1_LED_PIN 16  // RP2040-Zero onboard WS2812

// Dim per-key colors, 0xGGRRBB: key 0 red, key 1 green, key 2 blue —
// matches the CircuitPython bring-up script's palette.
static const uint32_t s_key_colors[K1_KEY_COUNT] = {
    0x001400,  // red
    0x140000,  // green
    0x000014,  // blue
};

static PIO s_pio = pio0;
static uint s_sm;

uint32_t k1_led_key_color(int key)
{
    return s_key_colors[key];
}

void k1_led_set(uint32_t grb)
{
    static uint32_t last = 0xFFFFFFFF;
    if (grb == last)
        return;
    last = grb;
    pio_sm_put_blocking(s_pio, s_sm, grb << 8u);
}

void k1_led_init(void)
{
    uint offset = pio_add_program(s_pio, &ws2812_program);
    s_sm = pio_claim_unused_sm(s_pio, true);
    ws2812_program_init(s_pio, s_sm, offset, K1_LED_PIN, 800000.0f, false);
    k1_led_set(0);
}
