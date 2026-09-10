// K1 desk variant v1 — printable 2-part design, NO USB adapter chain.
// Derived from cad/v5: same tray + drop-in lid (deck + key plate) and
// press-to-open rocker, but the RP2040-Zero sits hard against the rear
// wall with its own female USB-C facing out a rear port opening — you
// plug a normal USB-C cable straight into the board. The device sits on
// the desk instead of hanging off the MacBook port, so the adapter
// shelf, chain channel, side slot, chain_raise, and the mirrored
// variant are all gone and the body shrinks 129 -> 88.
//
// Sized for MX-style clicky switches (PCB/plate mount, through-hole):
//   body 15.6 sq, plate cutout 14.0 sq in a 1.5mm plate (clips grab the
//   plate underside), lower housing ~5mm below plate, upper ~6.6mm above.
// NOTE: clip or bend the switch pins short after soldering — the 7mm cavity
// does not clear full-length 3.3mm pins.
// Plug engagement depends on how far the board's USB-C face sits behind
// the outer rear face — measure the connector overhang with calipers and
// slide seat_x0 until a cable clicks in fully.
//
// Render one part at a time:
//   openscad -D 'part="tray"'  -o k1_desk_tray.stl  k1_desk_v1.scad
//   openscad -D 'part="deck"'  -o k1_desk_deck.stl  k1_desk_v1.scad  (already flipped for printing)
//   openscad -D 'part="plate"' -o k1_desk_plate.stl k1_desk_v1.scad
//   part="assembly" / part="exploded" for viewing (includes mock switches/caps)

part = "exploded"; // tray | lid | assembly | exploded

$fn = 48;

/* ---------- Body ---------- */
body_len  = 88;    // rear wall + board (to ~25.7) + 3-key well from 29
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
   relieved so the lid can dip there. Press the deck above the port ->
   the lid pivots on the ledge edge at pivot_x -> the front pops up out of
   its grooves. ~0.25mm engagement; walls flex. Tune snap_r/snap_grv_r if
   the lid is too loose or won't click in. Unlike v5 the board sits IN
   the dip zone, and the deck can only dip ~0.6 before its underside
   edge strips meet the PCB (and the tab the USB shell) — so the pivot
   sits well rearward: lever 1.4-10 vs overhang 10-24 releases the
   snaps at only ~0.15 rear dip. */
snap_r     = 0.4;    // bump radius (proud of the lid side face)
snap_grv_r = 0.5;    // groove radius in the tray wall (slop built in)
snap_len   = 6;      // bump length along the body
snap_xs    = [24];   // front of the deck only
pivot_x    = 10;     // ledge support ends here; relieved rearward — must
                     // stay rear of the PCB/tab contact points (see above)
relief     = 1.6;    // rear dip travel (drives the front lift)

/* ---------- Rear clips ----------
   v5's single centered rear clip is displaced by the port notch, so two
   shorter clips flank it — bumps on the deck's rear end face clicking
   into grooves in the rear upper wall's remaining side segments. They
   pop down out of their grooves when the rocker is pressed. */
rear_clip_len = 3;
rear_clip_ys  = [3.5, body_wid - 3.5]; // centers, inside the wall segments

/* ---------- RP2040-Zero board seat ----------
   The board bridges the cavity, resting its long edges on the widened
   ledges in a shallow pocket (floor level = relieved ledge height, so
   PCB top sits ~0.6 below the lid). A pocket in the deck underside
   clears the top-side USB connector and components. Nominal board
   18 x 23.5 x 1mm PCB — verify with calipers before printing. */
seat_x0     = 1.6;    // rear edge of the seat — the pocket bites into the
                      // rear wall so the USB-C face lands ~1mm behind the
                      // outer face (assumes ~0.8mm connector overhang past
                      // the PCB edge). Slide to tune plug engagement.
seat_len    = 24;
seat_wid    = 18.5;
seat_depth  = relief; // shares the relieved-ledge height
comp_pocket = 4.5;    // deck underside pocket over the board — also the
                      // cable-plug headroom over the connector (top 2.7)

/* ---------- Board retention nubs ----------
   Cable forces act above the PCB, so plugging tilts the board rear-up
   and unplugging tilts it front-up — and the deck can't hold it down:
   the rocker dips ~1.3mm over the seat, so a deck boss would block the
   press-to-open. The tray pins the board instead: wedge nubs on the
   seat pocket's rear and front walls overhang the PCB corners. The
   triangular profile keeps both faces at 45 degrees so the tray prints
   them cleanly upright (a round nub's droopy underside was the
   fit-critical surface). Install by pressing the board straight down —
   both pairs' top chamfers cam it in as the PCB bows — and remove by
   prying an edge up; the opposing 45-degree faces trap it otherwise.
   RP2040-Zero corners are pad-free, but keep soldered key wires clear
   of the nub spots. */
nub_prot = 0.5;  // protrusion off the pocket wall; ~0.25 over the PCB edge
nub_len  = 2.5;
nub_ys   = [4, body_wid - 4]; // corner centers, clear of the USB notch
nub_z0   = 8.0;  // underside root at the wall: PCB top (7.9) + 0.1

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

/* ---------- USB-C port opening (rear end wall) ----------
   The board's own receptacle (8.94 x 3.26 on the PCB top, mouth center
   z ~9.5) shows through the rear wall. The board drops in from the top
   with the connector overlapping the wall, so the wall gets a top-open
   notch and the deck's rear tab fills it back down to the port opening.
   Only the cable's plug shell passes the wall; the overmold butts the
   outer face. */
usb_w   = 10.5;  // opening width, centered on the body
usb_z   = 7.2;   // opening bottom (receptacle bottom 7.9 - clearance)
usb_h   = 4.6;   // opening height when closed (tab bottom at 11.8)
tab_clr = 0.15;  // clearance around the lid's wall-filler tab

/* ---------- Derived ---------- */
cav_len  = body_len - 2 * wall;        // 81.5
cav_wid  = body_wid - 2 * wall;        // 15.5
well_len = body_len - 2 * wall_upper;  // 85.5, also the lid seat opening
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
// Frame: X rear->front, Y centered on the port, Z up.

module tray() {
    union() {
    difference() {
        rounded_box(body_len, body_wid, body_ht, body_rad);
        // electronics cavity (lower walls)
        translate([wall, wall, floor_th])
            rounded_box(cav_len, cav_wid, tray_ht - floor_th + 0.01, 1);
        // key well + lid seat (upper, thinner walls); the width step at
        // tray_ht forms the ledge the lid rests on
        translate([wall_upper, wall_upper, tray_ht])
            rounded_box(well_len, well_wid, body_ht, 1);
        // USB drop-in notch: port opening plus the wall above it removed,
        // so the board's connector clears the rear wall on the way down;
        // the lid's tab fills the wall back in above the opening
        translate([-1, (body_wid - usb_w) / 2, usb_z])
            cube([wall + 2, usb_w, body_ht - usb_z + 1]);
        // snap grooves in the upper wall inner faces
        for (x = snap_xs, y = [wall_upper, body_wid - wall_upper])
            translate([x - snap_len / 2 - 0.75, y,
                       tray_ht + lid_th + well_depth / 2])
                rotate([0, 90, 0])
                    cylinder(h = snap_len + 1.5, r = snap_grv_r);
        // rear clip grooves flanking the port notch
        for (yc = rear_clip_ys)
            translate([wall_upper, yc - rear_clip_len / 2 - 0.75,
                       tray_ht + lid_th + well_depth / 2])
                rotate([-90, 0, 0])
                    cylinder(h = rear_clip_len + 1.5, r = snap_grv_r);
        // ledge relief rear of the pivot so the lid can rock down there
        translate([wall_upper, wall_upper, tray_ht - relief])
            cube([pivot_x - wall_upper, well_wid, relief + 0.01]);
        // key plate snap grooves near the front
        for (y = [wall_upper, body_wid - wall_upper])
            translate([plate_snap_x - plate_snap_len / 2 - 0.75, y,
                       tray_ht + lid_th / 2])
                rotate([0, 90, 0])
                    cylinder(h = plate_snap_len + 1.5, r = plate_grv_r);
        // board seat pocket cut into the ledges (locates the RP2040-Zero);
        // bites into the rear wall so the connector reaches the port
        translate([seat_x0, (body_wid - seat_wid) / 2, tray_ht - seat_depth])
            cube([seat_len, seat_wid, seat_depth + 0.01]);
    }
    // pillars continuing the seat pocket's front wall across the cavity:
    // that wall otherwise exists only on the 1.5mm side ledges, so the
    // front nubs would overhang open cavity (unprintable, unanchored)
    // and plug thrust would bear on the two ledge strips alone — these
    // back both, floor to ledge plane
    for (yc = nub_ys)
        translate([seat_x0 + seat_len, yc - nub_len / 2, floor_th - 0.01])
            cube([1.2, nub_len, tray_ht - floor_th + 0.01]);
    // board retention nubs on the seat pocket's rear and front walls;
    // the wall-embedded tails are trimmed flush above the ledge plane
    // so they don't poke into the seated deck's underside
    for (yc = nub_ys) {
        difference() { // rear pair, protruding forward over the PCB
            translate([seat_x0, yc - nub_len / 2, nub_z0]) board_nub();
            translate([seat_x0 - 1, yc - nub_len / 2 - 1, tray_ht])
                cube([1, nub_len + 2, 2 * nub_prot]);
        }
        difference() { // front pair, protruding rearward over the PCB
            translate([seat_x0 + seat_len, yc - nub_len / 2, nub_z0])
                mirror([1, 0, 0]) board_nub();
            translate([seat_x0 + seat_len, yc - nub_len / 2 - 1, tray_ht])
                cube([1, nub_len + 2, 2 * nub_prot]);
        }
    }
    }
}

// Wedge retention nub: triangular X-Z profile extruded nub_len along Y,
// origin on the pocket wall face at the underside root, protruding +X.
// Tip sits nub_prot up/out at the ledge plane; the 0.1 tail embeds in
// the wall so the union stays manifold.
module board_nub() {
    translate([0, nub_len, 0]) rotate([90, 0, 0]) linear_extrude(nub_len)
        polygon([[-0.1, 0], [nub_prot, nub_prot], [-0.1, 2 * nub_prot]]);
}

// Rear edge of the key well: caps travel freely from here to the front wall;
// behind it the lid deck rises flush with the tray rim.
well_rear = key_cx(key_count - 1) - cap_size / 2 - 1;

/* ---------- Lid split: deck + key plate ----------
   The lid prints as two parts: the DECK (everything behind the key well,
   printed upside down so the pockets/tab need no supports) and the
   flat KEY PLATE (printed as-is). Lock: the deck's front face is stepped —
   its top overhangs the plate's rear edge by 1.5mm, trapping it once the
   deck snaps in — and the plate has its own side bumps near the front. */
deck_top_end = well_rear;         // deck body ends 1mm clear of the caps
deck_bot_end = well_rear - 1.5;   // plate layer ends here; the 1.5 gap is
                                  // the roof lip that traps the key plate
plate_clr    = 0.15;              // seam clearance plate-to-deck
roof_clr     = 0.1;               // roof underside above the plate top
plate_snap_x   = body_len - 7.5;  // plate side-bump center
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
            // tab that re-fills the rear wall above the USB notch; bottom
            // flush with the opening top so the closed port is exactly
            // usb_h (4.6mm) tall. Rocker presses dip the tab ~0.2 into
            // the opening at snap release — clears a plugged-in shell
            // (0.6 below), but unplug before opening to be safe.
            translate([tab_clr, (body_wid - usb_w) / 2 + tab_clr,
                       usb_z + usb_h - tray_ht])
                cube([wall_upper + 0.3, usb_w - 2 * tab_clr,
                      lid_th + well_depth - (usb_z + usb_h - tray_ht)]);
            // snap bumps on the deck side faces
            for (x = snap_xs, y = [wall_upper + fit_clr,
                                   body_wid - wall_upper - fit_clr])
                translate([x - snap_len / 2, y, lid_th + well_depth / 2])
                    rotate([0, 90, 0])
                        cylinder(h = snap_len, r = snap_r);
            // rear clips flanking the port: bumps on the deck's rear end
            // face — resist rear lift, pop down out of their grooves when
            // the rocker is pressed to open
            for (yc = rear_clip_ys)
                translate([wall_upper + fit_clr, yc - rear_clip_len / 2,
                           lid_th + well_depth / 2])
                    rotate([-90, 0, 0])
                        cylinder(h = rear_clip_len, r = snap_r);
        }
        // deck underside pocket over the board's USB connector/components;
        // opens through the deck's rear face (the seat starts at the rear
        // wall, and the rear retention nubs poke above the ledge plane) —
        // the tab and rear clips root in the deck above the pocket — and
        // stops short of the deck/plate seam so the roof lip stays intact
        translate([wall_upper + fit_clr - 0.01, (body_wid - seat_wid) / 2 + 0.5, -1])
            cube([seat_x0 + seat_len - (wall_upper + fit_clr - 0.01),
                  seat_wid - 1, comp_pocket + 1]);
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
    color("silver") // top-side USB-C facing rear, ~0.8mm overhang past the PCB
        translate([seat_x0 + 0.25 - 0.8, (body_wid - 8.9) / 2,
                   tray_ht - seat_depth + 1])
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
