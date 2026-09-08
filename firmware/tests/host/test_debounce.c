#include <assert.h>
#include <stdio.h>
#include "debounce.h"

static void test_stays_idle_without_input(void) {
    k1_debounce_t d;
    k1_debounce_init(&d, false);
    for (int i = 0; i < 100; i++) assert(!k1_debounce_update(&d, false));
    assert(d.stable == false);
}

static void test_clean_press_fires_after_5_samples(void) {
    k1_debounce_t d;
    k1_debounce_init(&d, false);
    for (int i = 0; i < K1_DEBOUNCE_SAMPLES - 1; i++)
        assert(!k1_debounce_update(&d, true));
    assert(k1_debounce_update(&d, true));   // 5th sample flips it
    assert(d.stable == true);
    assert(!k1_debounce_update(&d, true));  // no repeat events while held
}

static void test_bounce_is_ignored(void) {
    k1_debounce_t d;
    k1_debounce_init(&d, false);
    // 3 pressed samples, then a bounce back to released, resets the counter
    assert(!k1_debounce_update(&d, true));
    assert(!k1_debounce_update(&d, true));
    assert(!k1_debounce_update(&d, true));
    assert(!k1_debounce_update(&d, false));
    assert(d.stable == false);
    // now a clean press still needs 5 consecutive samples
    for (int i = 0; i < K1_DEBOUNCE_SAMPLES - 1; i++)
        assert(!k1_debounce_update(&d, true));
    assert(k1_debounce_update(&d, true));
}

static void test_release_debounces_too(void) {
    k1_debounce_t d;
    k1_debounce_init(&d, true);
    for (int i = 0; i < K1_DEBOUNCE_SAMPLES - 1; i++)
        assert(!k1_debounce_update(&d, false));
    assert(k1_debounce_update(&d, false));
    assert(d.stable == false);
}

int main(void) {
    test_stays_idle_without_input();
    test_clean_press_fires_after_5_samples();
    test_bounce_is_ignored();
    test_release_debounces_too();
    printf("debounce: all tests passed\n");
    return 0;
}
