// K1 (Keys v1) — printable 2-part concept, v0.4
// Parts: tray (electronics cavity) + friction-fit lid that doubles as an
// MX switch plate. Keycaps are printed separately (any MX cross-stem cap
// works — e.g. the Lego-style caps).
//
// Sized for MX-style clicky switches (PCB/plate mount, through-hole):
//   body 15.6 sq, plate cutout 14.0 sq in a 1.5mm plate (clips grab the
//   plate underside), lower housing ~5mm below plate, pins ~3.3mm more.
// Body/plug dimensions remain placeholders until the MacBook is measured.
//
// Render one part at a time:
//   openscad -D 'part="tray"' -o k1_tray.stl k1_v1.scad
//   openscad -D 'part="lid"'  -o k1_lid.stl  k1_v1.scad   (print orientation)
//   part="assembly" / part="exploded" for viewing (includes mock switches/caps)

part = "exploded"; // tray | lid | assembly | exploded

$fn = 48;

/* ---------- Body ---------- */
body_len  = 115;   // rear (port) to laptop front edge
body_wid  = 22;
body_rad  = 3;

wall      = 2;     // side wall thickness
floor_th  = 1.5;
cav_depth = 10;    // below-plate room: 5 switch + 3.3 pins + wiring

/* ---------- Lid = switch plate ---------- */
lid_th        = 1.5;   // MX clips are made for a 1.5mm plate — don't change
lid_rim_depth = 2.5;   // perimeter rim that friction-fits into the tray
lid_rim_wid   = 1.6;
fit_clr       = 0.15;  // per-side clearance, tune per printer

tray_ht = floor_th + cav_depth;          // 11.5
body_ht = tray_ht + lid_th;              // 13 (shell only, keys stick up)

/* ---------- Keys (MX) ---------- */
key_count       = 3;
key_pitch       = 19;    // MX standard
keys_from_front = 10;    // first key center from the front end
plate_hole      = 14.1;  // 14.0 nominal + print tolerance
sw_body         = 15.6;  // switch housing (for clearance checks / mock)
sw_upper_ht     = 6.6;   // housing above plate
sw_stem_ht      = 3.6;   // cross stem above housing

/* ---------- Keycap envelope (for mock/clearance only, printed separately) ---------- */
cap_size = 18;   // standard MX cap footprint, < 19 pitch
cap_ht   = 9;    // roughly the Lego-style cap height

/* ---------- USB-C slot (inner wall, near rear) ---------- */
plug_from_rear = 12;   // slot center from rear end
slot_w = 10.5;         // fits a male USB-C breakout plug
slot_h = 4;
slot_z = floor_th + 1; // bottom of slot above cavity floor

/* ---------- Derived ---------- */
cav_len = body_len - 2 * wall;
cav_wid = body_wid - 2 * wall;

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
        rounded_box(body_len, body_wid, tray_ht, body_rad);
        // cavity
        translate([wall, wall, floor_th])
            rounded_box(cav_len, cav_wid, tray_ht, 1);
        // USB-C slot through the inner (Y=0) wall
        translate([plug_from_rear - slot_w / 2, -1, slot_z])
            cube([slot_w, wall + 2, slot_h]);
    }
}

// Modeled in assembly orientation: plate z=0..lid_th, rim hangs below.
module lid_assembled() {
    difference() {
        union() {
            rounded_box(body_len, body_wid, lid_th, body_rad);
            // friction rim: band just inside the cavity walls
            translate([0, 0, -lid_rim_depth])
                linear_extrude(lid_rim_depth)
                    difference() {
                        translate([wall + fit_clr, wall + fit_clr])
                            projection()
                                rounded_box(cav_len - 2 * fit_clr,
                                            cav_wid - 2 * fit_clr, 1, 1);
                        translate([wall + fit_clr + lid_rim_wid,
                                   wall + fit_clr + lid_rim_wid])
                            projection()
                                rounded_box(cav_len - 2 * (fit_clr + lid_rim_wid),
                                            cav_wid - 2 * (fit_clr + lid_rim_wid), 1, 1);
                    }
        }
        // MX plate cutouts — switches drop in from the top and clip under
        for (i = [0 : key_count - 1])
            translate([key_cx(i) - plate_hole / 2,
                       (body_wid - plate_hole) / 2,
                       -lid_rim_depth - 1])
                cube([plate_hole, plate_hole, lid_rim_depth + lid_th + 2]);
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
    translate([0, 0, tray_ht + explode]) lid_assembled();
    for (i = [0 : key_count - 1]) {
        translate([key_cx(i), body_wid / 2, plate_top + explode])
            switch_mock();
        // mock keycap (printed separately, seats over the stem)
        color("steelblue")
            translate([key_cx(i) - cap_size / 2, (body_wid - cap_size) / 2,
                       plate_top + sw_upper_ht + explode * 2])
                rounded_box(cap_size, cap_size, cap_ht, 2);
    }
}

if (part == "tray")          tray();
else if (part == "lid")      translate([0, body_wid, lid_th]) rotate([180, 0, 0]) lid_assembled();
else if (part == "assembly") assembly(0);
else if (part == "exploded") assembly(14);
