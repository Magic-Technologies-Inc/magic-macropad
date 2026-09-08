// K1 (Keys v1) — printable 2-part concept, v0.6
// Parts: tray + drop-in lid that doubles as an MX switch plate.
// High-profile: the tray walls continue past the plate, so the lid sits
// recessed on an internal ledge and the switch housings hide in a key well;
// only the caps show. The lid carries a raised deck behind the keys, flush
// with the tray rim. Keycaps are printed separately (Infill Key Caps STLs).
//
// Sized for MX-style clicky switches (PCB/plate mount, through-hole):
//   body 15.6 sq, plate cutout 14.0 sq in a 1.5mm plate (clips grab the
//   plate underside), lower housing ~5mm below plate, upper ~6.6mm above.
// NOTE: clip or bend the switch pins short after soldering — the 7mm cavity
// does not clear full-length 3.3mm pins.
// Body/plug dimensions remain placeholders until the MacBook is measured.
//
// Render one part at a time:
//   openscad -D 'part="tray"' -o k1_tray.stl k1_v1_parts.scad
//   openscad -D 'part="lid"'  -o k1_lid.stl  k1_v1_parts.scad
//   part="assembly" / part="exploded" for viewing (includes mock switches/caps)

part = "exploded"; // tray | lid | assembly | exploded

$fn = 48;

/* ---------- Body ---------- */
body_len  = 115;   // rear (port) to laptop front edge
body_wid  = 22;
body_rad  = 3;

wall       = 2;    // lower walls (electronics cavity)
wall_upper = 1.25; // thinner walls above the ledge -> wider key well
floor_th   = 1.5;
cav_depth  = 7;    // below-plate room: 5 switch + 2 for clipped pins & solder

/* ---------- Lid = switch plate (drop-in) ---------- */
lid_th     = 1.5;  // MX clips are made for a 1.5mm plate — don't change
fit_clr    = 0.15; // per-side clearance, tune per printer
well_depth = 7;    // wall height above the plate; hides the 6.6mm housing

tray_ht = floor_th + cav_depth;               // ledge height, 8.5
body_ht = tray_ht + lid_th + well_depth;      // full shell, 17

/* ---------- Keys (MX) ---------- */
key_count       = 3;
key_pitch       = 19;    // MX standard
keys_from_front = 11;    // first key center from the front end
plate_hole      = 14.1;  // 14.0 nominal + print tolerance
sw_body         = 15.6;  // switch housing (for clearance checks / mock)
sw_upper_ht     = 6.6;   // housing above plate
sw_stem_ht      = 3.6;   // cross stem above housing

/* ---------- Keycap envelope (for mock/clearance only, printed separately) ----------
   Measured from the Infill Key Caps STLs: 18 x 18 x 11.5, hollow skirt,
   cross-socket mouth 1.5 above the skirt edge -> when seated the skirt
   drops ~1mm over the switch housing. */
cap_size    = 18;
cap_ht      = 11.5;
cap_overlap = 1;    // skirt drop below the housing top when seated

/* ---------- USB-C slot (inner wall, near rear) ---------- */
plug_from_rear = 12;   // slot center from rear end
slot_w = 10.5;         // fits a male USB-C breakout plug
slot_h = 4;
slot_z = floor_th + 1; // bottom of slot above cavity floor

/* ---------- Derived ---------- */
cav_len  = body_len - 2 * wall;        // 111
cav_wid  = body_wid - 2 * wall;        // 18
well_len = body_len - 2 * wall_upper;  // 112.5, also the lid seat opening
well_wid = body_wid - 2 * wall_upper;  // 19.5
lid_len  = well_len - 2 * fit_clr;
lid_wid  = well_wid - 2 * fit_clr;

function key_cx(i) = body_len - keys_from_front - i * key_pitch;

/* ---------- Helpers ---------- */
module rounded_box(l, w, h, r) {
    hull()
        for (x = [r, l - r], y = [r, w - r])
            translate([x, y, 0]) cylinder(h = h, r = r);
}

/* ---------- Parts ---------- */
// Frame: X rear->front, Y=0 face touches the laptop, Z up.

module tray() {
    difference() {
        rounded_box(body_len, body_wid, body_ht, body_rad);
        // electronics cavity (lower, 2mm walls)
        translate([wall, wall, floor_th])
            rounded_box(cav_len, cav_wid, tray_ht - floor_th + 0.01, 1);
        // key well + lid seat (upper, thinner walls); the width step at
        // tray_ht forms the ledge the lid rests on
        translate([wall_upper, wall_upper, tray_ht])
            rounded_box(well_len, well_wid, body_ht, 1);
        // USB-C slot through the inner (Y=0) wall
        translate([plug_from_rear - slot_w / 2, -1, slot_z])
            cube([slot_w, wall + 2, slot_h]);
    }
}

// Rear edge of the key well: caps travel freely from here to the front wall;
// behind it the lid deck rises flush with the tray rim.
well_rear = key_cx(key_count - 1) - cap_size / 2 - 1;

// Plate that drops into the well and rests on the ledge, with a raised deck
// over the non-key area so the top surface is flush with the tray rim.
module lid() {
    difference() {
        union() {
            translate([wall_upper + fit_clr, wall_upper + fit_clr, 0]) {
                rounded_box(lid_len, lid_wid, lid_th, 1);
                // deck: fills the well behind the keys, flush with the rim
                rounded_box(well_rear - wall_upper - fit_clr, lid_wid,
                            lid_th + well_depth, 1);
            }
        }
        // MX plate cutouts — switches drop in from the top and clip under
        for (i = [0 : key_count - 1])
            translate([key_cx(i) - plate_hole / 2,
                       (body_wid - plate_hole) / 2,
                       -1])
                cube([plate_hole, plate_hole, lid_th + 2]);
    }
}

// Mock MX switch for assembly views only (not exported)
module switch_mock() {
    color("gray") {
        translate([-sw_body / 2, -sw_body / 2, -5]) cube([sw_body, sw_body, 5]);
        translate([-sw_body / 2, -sw_body / 2, 0])  cube([sw_body, sw_body, sw_upper_ht]);
        translate([-2.05, -2.05, sw_upper_ht])      cube([4.1, 4.1, sw_stem_ht]);
    }
}

/* ---------- Views ---------- */

module assembly(explode = 0) {
    plate_top = tray_ht + lid_th;
    tray();
    translate([0, 0, tray_ht + explode]) lid();
    for (i = [0 : key_count - 1]) {
        translate([key_cx(i), body_wid / 2, plate_top + explode])
            switch_mock();
        // mock keycap (printed separately, seats over the stem)
        color("steelblue")
            translate([key_cx(i) - cap_size / 2, (body_wid - cap_size) / 2,
                       plate_top + sw_upper_ht - cap_overlap + explode * 2])
                rounded_box(cap_size, cap_size, cap_ht, 2);
    }
}

if (part == "tray")          tray();
else if (part == "lid")      lid();
else if (part == "assembly") assembly(0);
else if (part == "exploded") assembly(14);
