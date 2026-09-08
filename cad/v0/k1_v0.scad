// K1 enclosure v0 — rough one-piece concept sketch (superseded by v1/v2)
// Not for printing/fit — a first-pass 3D sketch of the flush keypad form.
// All dimensions are placeholders until the MacBook port position and
// side taper are measured (see project summary).

$fn = 48;

/* ---------- Parameters ---------- */

// Body (sits along the MacBook's side, running to the front edge)
body_len    = 115;   // along the laptop side, rear (port) to front edge
body_wid    = 22;    // sticks out sideways from the laptop
body_ht     = 9;     // thin — roughly deck height
body_rad    = 3;     // corner rounding

// USB-C plug stub (perpendicular, out of the inner long face, near the rear)
plug_wid    = 8.3;   // USB-C plug width
plug_thk    = 2.5;   // USB-C plug thickness
plug_len    = 7;     // how far it protrudes into the port
plug_from_rear = 12; // plug center distance from the rear end of the body

// Keys
key_count   = 4;
key_size    = 14;    // square keycap side (MX-ish footprint)
key_pitch   = 19;    // MX spacing
key_ht      = 2;     // how proud the caps sit above the deck
key_rad     = 2;
keys_from_front = 8; // first key center from the front end

/* ---------- Helpers ---------- */

module rounded_box(l, w, h, r) {
    // rounded in plan view, flat top/bottom
    hull()
        for (x = [r, l - r], y = [r, w - r])
            translate([x, y, 0]) cylinder(h = h, r = r);
}

/* ---------- Parts ---------- */

// Coordinate frame: X = rear→front along the laptop side,
// Y = away from the laptop (Y=0 face touches the chassis), Z = up.

module body() {
    rounded_box(body_len, body_wid, body_ht, body_rad);
}

module plug() {
    // protrudes in -Y (into the laptop), vertically centered on the port height
    translate([plug_from_rear - plug_wid / 2,
               -plug_len,
               body_ht / 2 - plug_thk / 2])
        cube([plug_wid, plug_len + 1, plug_thk]);
}

module keys() {
    for (i = [0 : key_count - 1])
        translate([body_len - keys_from_front - i * key_pitch - key_size / 2,
                   (body_wid - key_size) / 2,
                   body_ht])
            rounded_box(key_size, key_size, key_ht, key_rad);
}

/* ---------- Assembly ---------- */

union() {
    body();
    plug();
    keys();
}
