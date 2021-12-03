// All kinds of bolt and machine screw holes                                   |
// Adrian McCarthy 2021

use <aidutil.scad>;

function thou(x) = x*0.0254;
function inch(x) = x*25.4;
function tpi(x)  = inch(1/x);

// The bolt table provides parameters about the bolts (screws).  The rows
// must be sorted by the first entry (ASCIIbetical).
//
// Each row of a bolt table row consists of:
//  [0] name (e.g., "M2", "#4-40", or "1/4-20")
//  [1] free-fit clearance hole diameter
//  [2] close-fit clearance hole diameter
//  [3] tapping hole diameter
//  [4] thread pitch
//  [5] maximum head diameter
//  [6] head height
//  [7] flat head diameter
//  [8] flat head height
//  [9] maximum nut width (edge to edge, wrench size)
//  [10] maximum nut thickness (along the bolt axis)

// This default table provides parameters for common metric and inch machine
// screws, but you can substitute your own table if it conforms to the
// description above.
machine_screws = [
    // name     free-fit    close-fit   tapping     pitch       head_d      head_h      flat_d      flat_h      nut_w       nut_th
    ["#2-56",   thou( 96),  thou( 89),  thou( 70),  tpi(56),    thou(167),  thou( 63),  thou(162),  thou( 51),  inch(3/16), inch(1/16)],
    ["#4-40",   thou(120),  thou(116),  thou( 89),  tpi(40),    thou(219),  thou( 80),  thou(212),  thou( 67),  inch(1/4),  inch(3/32)],
    ["#6-32",   thou(149.5),thou(144),  thou(106.5),tpi(32),    thou(270),  thou( 97),  thou(262),  thou( 83),  inch(5/16), inch(7/64)],
    ["1/4-20",  thou(266),  thou(257),  thou(201),  tpi(20),    thou(492),  thou(175),  thou(477),  thou(153),  inch(7/16), inch(3/16)],
    ["M2",      2.4,        2.4,        1.6,        0.40,       4.0,        1.6,        3.8,        1.20,       4.0,        1.6       ],
    ["M2.5",    2.9,        2.8,        2.1,        0.45,       5.0,        2.0,        4.7,        1.50,       5.0,        2.0       ],
    ["M3",      3.4,        3.4,        2.5,        0.50,       6.0,        2.4,        5.6,        1.65,       5.5,        2.4       ],
    ["M4",      4.5,        4.3,        3.5,        0.70,       8.0,        3.1,        7.5,        2.20,       7.0,        3.2       ]
];

function find_bolt_params(size, table) = find_params(size, table=table);

module bolt_hole(size, l, threads="none", head="proud", table=machine_screws, nozzle_d=0.4) {
    bolt = find_bolt_params(size, table=table);
    if (is_undef(bolt)) {
        echo(str("bolt_hole: `size` \"", size, "\" not found in table"));
        assert(false, "bolt_hole: cannot continue without `size`");
    }

    // Name the bolt parameters.
    free_d  = bolt[1];
    close_d = bolt[2];
    tap_d   = bolt[3];
    pitch   = bolt[4];
    head_d  = bolt[5];
    head_h  = bolt[6];
    flat_d  = bolt[7];
    flat_h  = bolt[8];
    nut_w   = bolt[9];
    nut_th  = bolt[10];

    thread_types = [  //        shaft_d hexnut  pocket
        ["none",                free_d, false,  false],
        ["pocket hex nut",      free_d, true,   true],
        ["recessed hex nut",    free_d, true,   false],
        ["self-tapping",        tap_d,  false,  false]
    ];
    thread_synonyms = [
        ["",                "none"],
        ["pilot",           "self-tapping"],
        ["pocket nut",      "pocket hex nut"],
        ["recessed nut",    "recessed hex nut"],
        ["self tapping",    "self-tapping"],
        ["tapped",          "self-tapping"]
    ];

    thread_type = find_params(remap_key(threads, thread_synonyms), table=thread_types);
    if (is_undef(thread_type)) {
        echo(str("bolt_hole: `threads` type \"", threads, "\" not recognized"));
        echo(str("expected one of: ", [for (i=thread_types) i[0]]));
        assert(false);
    }

    shaft_d = thread_type[1];
    hexnut  = thread_type[2];
    pocket  = thread_type[3];

    head_types = [  //      drop    taper    
        ["counterbored",    head_h, false],
        ["countersunk",     0,      true ],
        ["proud",           0,      false]
    ];
    
    head_type = find_params(head, table=head_types);
    if (is_undef(head_type)) {
        echo(str("bolt_hole: `head` type \"", head, "\" not recognized"));
        echo(str("expected one of: ", [for (i=thread_types) i[0]]));
        assert(false);
    }

    drop    = head_type[1];
    taper   = head_type[2];
    bevel   = !taper && shaft_d == tap_d && l > 4*pitch;

    union() translate([0, 0, -drop]) {
        $fs = nozzle_d/2;

        // The head of the screw.
        cylinder(h=head_h + drop, d=head_d + nozzle_d);
        
        if (bevel) {
            // Add a tiny bevel to guide the tap (or self-tapping screw) toward
            // the center of the bore.
            translate([0, 0, -pitch])
                cylinder(h=pitch+0.1, d1=shaft_d, d2=free_d);
        }
        
        if (taper) {
            // This forms the countersink for a flathead screw.
            translate([0, 0, -head_h])
                cylinder(h=head_h + 0.1, d1=close_d, d2=head_d + nozzle_d);
        }

        // The shaft of the screw.
        translate([0, 0, -l - 0.1]) cylinder(h=l + 0.2, d=shaft_d + nozzle_d);
    
        if (hexnut) {
            // Recess or pocket for a hex nut.
            nut_d = round_up(nut_w / cos(30), nozzle_d) + nozzle_d;
            protrusion = 2*pitch;
            h = nut_th + protrusion + (pocket ? 0 : 0.1);
            depth = -l - (pocket ? 0 : 0.1);
            translate([0, 0, depth]) {
                rotate([0, 0, 90]) cylinder(h=h, d=nut_d, $fn=6);
                if (pocket) {
                    pocket_w = nut_w + nozzle_d;
                    translate([-pocket_w/2, 0, 0])
                        cube([pocket_w, 1.5*nut_d, nut_th+nozzle_d/2]);
                }
            }
        }
    }
}

// This test shows a cutaway view of several example bolt holes.
module test() {
    spacing = 9;
    i = [spacing, 0, 0];
    depth = 10;
    w = 6*spacing;
    h = 10;
    
    translate([0, $preview ? 0: depth, $preview ? 0 : h])
    rotate([$preview ? 0 : 180, 0, 0])
    difference() {
        cube([w, depth, h]);
        if ($preview) {
            // cutaway
            translate([-1, -depth/2-0.5, -1]) cube([w+2, spacing, h+2]);
        }
        translate([-spacing/2, depth/2, 10]) {
            translate(1*i) bolt_hole("M2", h/2, "self-tapping", "countersunk");
            translate(2*i) bolt_hole("M2.5", h/2, "pocket hex nut", "counterbored");
            translate(3*i) bolt_hole("M3", h, head="countersunk");
            translate(4*i) bolt_hole("#2-56", h, "recessed hex nut");
            translate(5*i) bolt_hole("#4-40", h, "self-tapping");
            translate(6*i) bolt_hole("#6-32", h, "recessed hex nut");
        }
    }
}

test();
