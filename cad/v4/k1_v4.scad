// K1 enclosure v4 — printable 2-part design
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
//   openscad -D 'part="tray"'  -o k1_tray.stl  k1_v4.scad
//   openscad -D 'part="deck"'  -o k1_deck.stl  k1_v4.scad  (already flipped for printing)
//   openscad -D 'part="plate"' -o k1_plate.stl k1_v4.scad
//   part="assembly" / part="exploded" for viewing (includes mock switches/caps)

part = "exploded"; // tray | lid | assembly | exploded

$fn = 48;

/* ---------- Body ---------- */
body_len  = 129;   // grown for the 44mm USB chain: adapter body starts at
                   // plug_from_rear-6=6, +44 chain, -6.5 insertion -> board
                   // rear face ~43.5, board to ~67, key well from 70
body_wid  = 22;
body_rad  = 3;

wall       = 3.25; // lower walls; with wall_upper this leaves a 2mm ledge
                   // per side, wide enough to carry the board seat
wall_upper = 1.25; // thinner walls above the ledge -> wider key well
floor_th   = 1.5;
cav_depth  = 7;    // below-plate room: 5 switch + 2 for clipped pins & solder

/* ---------- Lid = switch plate (drop-in) ---------- */
lid_th     = 1.5;  // MX clips are made for a 1.5mm plate — don't change
fit_clr    = 0.15; // per-side clearance, tune per printer
well_depth = 7;    // wall height above the plate; hides the 6.6mm housing

tray_ht = floor_th + cav_depth;               // ledge height, 8.5
body_ht = tray_ht + lid_th + well_depth;      // full shell, 17

/* ---------- Lid retention: press-to-open rocker ----------
   Snap bumps only at the FRONT of the deck; the rear (USB end) ledge is
   relieved so the lid can dip there. Press the deck above the USB slot ->
   the lid pivots on the ledge edge at pivot_x -> the front pops up out of
   its grooves. ~0.25mm engagement; walls flex. Tune snap_r/snap_grv_r if
   the lid is too loose or won't click in. */
snap_r     = 0.4;    // bump radius (proud of the lid side face)
snap_grv_r = 0.5;    // groove radius in the tray wall (slop built in)
snap_len   = 6;      // bump length along the body
snap_xs    = [50];   // front of the deck only
pivot_x    = 38;     // ledge support ends here; relieved rearward
relief     = 1.6;    // rear dip travel (drives the front lift)

/* ---------- RP2040-Zero board seat ----------
   The board bridges the cavity, resting its long edges on the widened
   ledges in a shallow pocket (floor level = relieved ledge height, so
   PCB top sits ~0.6 below the lid). A pocket in the deck underside
   clears the top-side USB connector and components. Nominal board
   18 x 23.5 x 1mm PCB — verify with calipers before printing. */
seat_x0     = 45.5;   // rear edge of the seat (board USB-C faces rear);
                      // v3 position +2.5mm toward the keys per the test fit
seat_len    = 24;
seat_wid    = 18.5;
seat_depth  = relief; // shares the relieved-ledge height
comp_pocket = 4.5;    // deck underside pocket over the board — matches the
                      // chain channel depth so the hollow is one level

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
plug_from_rear = 11.5; // slot center from rear end (rear edge held at x=6;
                       // the keys-side edge came in 1mm with the narrowing)
slot_w = 11;           // sized for the 90-degree adapter's plug base
slot_h = 6;
tab_clr = 0.15;        // clearance around the lid's wall-filler tab
slot_z = (body_ht - slot_h) / 2; // slot centered on body height for now;
                                 // final height = MacBook port center above
                                 // desk (measure!), matched by the adapter
                                 // cradle pedestal when that gets added
// Lid notch over the slot: the slot's upper half is above the ledge, so the
// lid plate + deck must open up behind it for the plug/adapter to pass.
usb_notch_w     = slot_w + 1;
usb_notch_depth = 12;  // into the lid from the inner edge; placeholder until
                       // the 90-degree adapter is measured (becomes cradle)
usb_notch_h     = slot_z + slot_h + 1 - tray_ht;  // clears the slot top;
                                                  // deck top stays closed
/* Chain channel: hollows the deck underside from the USB notch to the
   board pocket so the adapter + coupler bodies (top ~12.5mm) fit under
   the lid. Height stays just under the tab bottom (4.6 local). */
chain_ch_h    = 4.5;
chain_ch_wall = 4;    // deck wall thickness on both sides of the channel
                      // (the USB notch zone stays open to the inner edge)

/* ---------- USB adapter support shelf ----------
   Raised platform on the tray floor the 90-degree adapter's body sits on,
   so its plug lines up with the slot center. Covers the adapter body only —
   the coupler hangs between adapter and board. Measure usb_body_th! */
usb_body_th  = 8;    // est. adapter body thickness
usb_shelf_x0 = plug_from_rear - slot_w / 2 - 0.5;             // 5.5
usb_shelf_len = seat_x0 - (plug_from_rear - slot_w / 2 - 0.5); // to the board seat
usb_shelf_w  = body_wid - 2 * wall;  // full cavity width, wall to wall
usb_shelf_top = slot_z + slot_h / 2 - usb_body_th / 2;        // 4.5

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
    union() {
    difference() {
        rounded_box(body_len, body_wid, body_ht, body_rad);
        // electronics cavity (lower, 2mm walls)
        translate([wall, wall, floor_th])
            rounded_box(cav_len, cav_wid, tray_ht - floor_th + 0.01, 1);
        // key well + lid seat (upper, thinner walls); the width step at
        // tray_ht forms the ledge the lid rests on
        translate([wall_upper, wall_upper, tray_ht])
            rounded_box(well_len, well_wid, body_ht, 1);
        // USB drop-in notch: slot plus the wall above it removed, so the
        // right-angle adapter drops in from the top; the lid's tab fills
        // the wall back in and captures it
        translate([plug_from_rear - slot_w / 2, -1, slot_z])
            cube([slot_w, wall + 2, body_ht - slot_z + 1]);
        // snap grooves in the upper wall inner faces
        for (x = snap_xs, y = [wall_upper, body_wid - wall_upper])
            translate([x - snap_len / 2 - 0.75, y,
                       tray_ht + lid_th + well_depth / 2])
                rotate([0, 90, 0])
                    cylinder(h = snap_len + 1.5, r = snap_grv_r);
        // ledge relief rear of the pivot so the lid can rock down there
        translate([wall_upper, wall_upper, tray_ht - relief])
            cube([pivot_x - wall_upper, well_wid, relief + 0.01]);
        // key plate snap grooves near the front
        for (y = [wall_upper, body_wid - wall_upper])
            translate([plate_snap_x - plate_snap_len / 2 - 0.75, y,
                       tray_ht + lid_th / 2])
                rotate([0, 90, 0])
                    cylinder(h = plate_snap_len + 1.5, r = plate_grv_r);
        // board seat pocket cut into the ledges (locates the RP2040-Zero)
        translate([seat_x0, (body_wid - seat_wid) / 2, tray_ht - seat_depth])
            cube([seat_len, seat_wid, seat_depth + 0.01]);
    }
    // USB adapter support shelf on the cavity floor
    translate([usb_shelf_x0, wall - 0.01, floor_th - 0.01])
        cube([usb_shelf_len, usb_shelf_w, usb_shelf_top - floor_th + 0.01]);
    }
}

// Rear edge of the key well: caps travel freely from here to the front wall;
// behind it the lid deck rises flush with the tray rim.
well_rear = key_cx(key_count - 1) - cap_size / 2 - 1;

/* ---------- Lid split: deck + key plate ----------
   The lid prints as two parts: the DECK (everything behind the key well,
   printed upside down so the pockets/channel/tab need no supports) and the
   flat KEY PLATE (printed as-is). Lock: the deck's front face is stepped —
   its top overhangs the plate's rear edge by 1.5mm, trapping it once the
   deck snaps in — and the plate has its own side bumps near the front. */
deck_top_end = well_rear;         // deck body ends 1mm clear of the caps
deck_bot_end = well_rear - 1.5;   // plate layer ends here; the 1.5 gap is
                                  // the roof lip that traps the key plate
plate_clr    = 0.15;              // seam clearance plate-to-deck
roof_clr     = 0.1;               // roof underside above the plate top
plate_snap_x   = 121.5;           // plate side-bump center
plate_snap_r   = 0.3;
plate_grv_r    = 0.45;
plate_snap_len = 5;

// Plate that drops into the well and rests on the ledge, with a raised deck
// over the non-key area so the top surface is flush with the tray rim.
// Full lid geometry; split into deck_part()/plate_part() for printing.
module lid() {
    difference() {
        union() {
            translate([wall_upper + fit_clr, wall_upper + fit_clr, 0]) {
                rounded_box(lid_len, lid_wid, lid_th, 1);
                // deck: fills the well behind the keys, flush with the rim
                rounded_box(deck_top_end - wall_upper - fit_clr, lid_wid,
                            lid_th + well_depth, 1);
            }
            // tab that re-fills the tray wall above the USB notch; bottom
            // flush with the slot top so the closed cutout is exactly
            // slot_h (6mm) tall. NOTE: rocker presses now dip the tab
            // ~1mm into the opening — open the lid with the adapter
            // unplugged from the Mac.
            translate([plug_from_rear - slot_w / 2 + tab_clr, tab_clr,
                       slot_z + slot_h - tray_ht])
                cube([slot_w - 2 * tab_clr, wall_upper + 0.3,
                      lid_th + well_depth - (slot_z + slot_h - tray_ht)]);
            // snap bumps on the deck side faces
            for (x = snap_xs, y = [wall_upper + fit_clr,
                                   body_wid - wall_upper - fit_clr])
                translate([x - snap_len / 2, y, lid_th + well_depth / 2])
                    rotate([0, 90, 0])
                        cylinder(h = snap_len, r = snap_r);
        }
        // deck underside pocket over the board's USB connector/components;
        // stops short of the deck/plate seam so the roof lip stays intact
        // (the board's front sliver sits under the flat plate, 0.6 clear)
        translate([seat_x0, (body_wid - seat_wid) / 2 + 0.5, -1])
            cube([min(seat_len, deck_bot_end - 0.5 - seat_x0),
                  seat_wid - 1, comp_pocket + 1]);
        // chain channel: centered trench with chain_ch_wall on both sides;
        // the USB notch zone stays open to the inner edge for the adapter
        translate([plug_from_rear - usb_notch_w / 2, wall_upper + 0.05, -1])
            cube([usb_notch_w,
                  body_wid - wall_upper - fit_clr - chain_ch_wall
                      - (wall_upper + 0.05), chain_ch_h + 1]);
        translate([plug_from_rear + usb_notch_w / 2,
                   wall_upper + fit_clr + chain_ch_wall, -1])
            cube([seat_x0 - (plug_from_rear + usb_notch_w / 2) + 1,
                  body_wid - 2 * (wall_upper + fit_clr + chain_ch_wall),
                  chain_ch_h + 1]);
        // MX plate cutouts — switches drop in from the top and clip under
        for (i = [0 : key_count - 1])
            translate([key_cx(i) - plate_hole / 2,
                       (body_wid - plate_hole) / 2,
                       -1])
                cube([plate_hole, plate_hole, lid_th + 2]);
    }
}

// Deck: rear lid section with a stepped front face — the plate layer ends
// at deck_bot_end while the top overhangs to deck_top_end, forming the
// roof lip that traps the key plate. Print upside down (see export).
module deck_part() {
    difference() {
        intersection() {
            lid();
            translate([-1, -1, -1])
                cube([deck_top_end + 1, body_wid + 2, lid_th + well_depth + 2]);
        }
        translate([deck_bot_end, -1, -1])
            cube([deck_top_end - deck_bot_end + 2, body_wid + 2,
                  lid_th + roof_clr + 1]);
    }
}

// Key plate: flat front section; its rear edge slides under the deck's
// roof lip, and side bumps near the front click into wall grooves.
module plate_part() {
    union() {
        intersection() {
            lid();
            // clamp to plate thickness: without this the rear strip would
            // keep deck-height material and collide with the deck's roof
            translate([deck_bot_end + plate_clr, -1, -1])
                cube([body_len, body_wid + 2, lid_th + 1.01]);
        }
        for (y = [wall_upper + fit_clr, body_wid - wall_upper - fit_clr])
            translate([plate_snap_x - plate_snap_len / 2, y, lid_th / 2])
                rotate([0, 90, 0]) cylinder(h = plate_snap_len, r = plate_snap_r);
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

// Mock RP2040-Zero for assembly views only (not exported)
module board_mock() {
    color("darkgreen")
        translate([seat_x0 + 0.25, (body_wid - 18) / 2, tray_ht - seat_depth])
            cube([23.5, 18, 1]);
    color("silver") // top-side USB-C, facing rear
        translate([seat_x0 + 0.25, (body_wid - 8.9) / 2, tray_ht - seat_depth + 1])
            cube([7, 8.9, 3.2]);
}

/* ---------- Views ---------- */

module assembly(explode = 0) {
    plate_top = tray_ht + lid_th;
    tray();
    board_mock();
    translate([0, 0, tray_ht + explode]) deck_part();
    translate([0, 0, tray_ht + explode * 1.5]) plate_part();
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
// deck exports upside down = its print orientation (pockets/tab face up)
else if (part == "deck")     translate([0, body_wid, lid_th + well_depth])
                                 rotate([180, 0, 0]) deck_part();
else if (part == "plate")    plate_part();
else if (part == "lid")      lid(); // full one-piece lid, reference only
else if (part == "assembly") assembly(0);
else if (part == "exploded") assembly(14);
