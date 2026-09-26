#pragma once
#include <stdbool.h>
#include <stdint.h>
#include "protocol.h"

// Keeps the host's picture of the keys in step with reality. Edges the host
// misses while it isn't listening (bus suspended, not yet mounted, a failed
// send) are dropped rather than replayed later as if they were live presses;
// once it listens again, each key whose state changed meanwhile is reported
// once, so the host never believes a key is still held.
typedef struct {
    bool host_down[K1_KEY_COUNT];  // each key as last delivered to the host
    bool resync;                   // host view may be stale: realign before queued edges
} k1_keysync_t;

// A fresh enumeration: the host starts from "all keys up".
void k1_keysync_reset(k1_keysync_t *s);

// The host stopped listening, or a report was lost: realign once it's back.
void k1_keysync_invalidate(k1_keysync_t *s);

// While resyncing, the next key whose host view differs from `pressed`
// (its current state is written to *down); -1 once in sync, which ends the
// resync. Always -1 when no resync is pending.
int k1_keysync_next(k1_keysync_t *s, const bool pressed[K1_KEY_COUNT], bool *down);

// A key report reached the host.
void k1_keysync_delivered(k1_keysync_t *s, uint8_t key, bool down);
