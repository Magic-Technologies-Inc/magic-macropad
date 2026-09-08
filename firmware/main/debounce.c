#include "debounce.h"

void k1_debounce_init(k1_debounce_t *d, bool initial)
{
    d->stable = initial;
    d->candidate = initial;
    d->count = 0;
}

bool k1_debounce_update(k1_debounce_t *d, bool raw)
{
    if (raw != d->candidate) {
        d->candidate = raw;
        d->count = 1;
        return false;
    }
    if (d->candidate == d->stable) {
        d->count = 0;
        return false;
    }
    if (++d->count >= K1_DEBOUNCE_SAMPLES) {
        d->stable = d->candidate;
        d->count = 0;
        return true;
    }
    return false;
}
