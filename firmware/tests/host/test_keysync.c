#include <assert.h>
#include <stdio.h>
#include "keysync.h"

static const bool NONE[K1_KEY_COUNT] = {false, false, false};

static void test_idle_enumeration_reports_nothing(void) {
    k1_keysync_t s;
    bool down;
    k1_keysync_reset(&s);
    assert(k1_keysync_next(&s, NONE, &down) == -1);
    assert(!s.resync);
}

static void test_key_held_at_enumeration_is_reported(void) {
    k1_keysync_t s;
    bool down = false;
    const bool pressed[K1_KEY_COUNT] = {false, true, false};
    k1_keysync_reset(&s);
    assert(k1_keysync_next(&s, pressed, &down) == 1 && down);
    k1_keysync_delivered(&s, 1, true);
    assert(k1_keysync_next(&s, pressed, &down) == -1);
}

static void test_release_missed_while_suspended_is_reported(void) {
    k1_keysync_t s;
    bool down = true;
    k1_keysync_reset(&s);
    k1_keysync_delivered(&s, 0, true);   // host saw key 0 go down...
    k1_keysync_invalidate(&s);           // ...then the bus suspended
    // key 0 was released while suspended
    assert(k1_keysync_next(&s, NONE, &down) == 0 && !down);
    k1_keysync_delivered(&s, 0, false);
    assert(k1_keysync_next(&s, NONE, &down) == -1);
}

static void test_presses_made_while_suspended_are_not_replayed(void) {
    k1_keysync_t s;
    bool down;
    k1_keysync_reset(&s);
    assert(k1_keysync_next(&s, NONE, &down) == -1);  // in sync
    k1_keysync_invalidate(&s);
    // keys pressed and released while suspended: nothing left to report
    assert(k1_keysync_next(&s, NONE, &down) == -1);
}

static void test_no_resync_pending_reports_nothing(void) {
    k1_keysync_t s;
    bool down;
    const bool pressed[K1_KEY_COUNT] = {true, false, false};
    k1_keysync_reset(&s);
    assert(k1_keysync_next(&s, NONE, &down) == -1);    // sync done
    assert(k1_keysync_next(&s, pressed, &down) == -1); // live edges go via the queue
}

int main(void) {
    test_idle_enumeration_reports_nothing();
    test_key_held_at_enumeration_is_reported();
    test_release_missed_while_suspended_is_reported();
    test_presses_made_while_suspended_are_not_replayed();
    test_no_resync_pending_reports_nothing();
    printf("keysync: all tests passed\n");
    return 0;
}
