#pragma once
#include <stdbool.h>
#include <stdint.h>

#define K1_DEBOUNCE_SAMPLES 5  // at 1 ms/sample => 5 ms debounce

typedef struct {
    bool stable;     // debounced state (true = pressed)
    bool candidate;  // last raw sample
    uint8_t count;   // consecutive samples matching candidate
} k1_debounce_t;

void k1_debounce_init(k1_debounce_t *d, bool initial);
// Feed one raw sample. Returns true iff the stable state just changed
// (read the new state from d->stable).
bool k1_debounce_update(k1_debounce_t *d, bool raw);
