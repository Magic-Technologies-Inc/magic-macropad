#include "keysync.h"

void k1_keysync_reset(k1_keysync_t *s)
{
    for (int i = 0; i < K1_KEY_COUNT; i++)
        s->host_down[i] = false;
    s->resync = true;  // a key already held at enumeration still needs reporting
}

void k1_keysync_invalidate(k1_keysync_t *s)
{
    s->resync = true;
}

int k1_keysync_next(k1_keysync_t *s, const bool pressed[K1_KEY_COUNT], bool *down)
{
    if (!s->resync)
        return -1;
    for (int i = 0; i < K1_KEY_COUNT; i++) {
        if (s->host_down[i] != pressed[i]) {
            *down = pressed[i];
            return i;
        }
    }
    s->resync = false;
    return -1;
}

void k1_keysync_delivered(k1_keysync_t *s, uint8_t key, bool down)
{
    if (key < K1_KEY_COUNT)
        s->host_down[key] = down;
}
