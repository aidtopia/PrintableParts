// All kinds of bolt and machine screw holes                                   |
// Adrian McCarthy 2021

use <aidutil.scad>;

function thou(x) = x*0.0254;
function inch(x) = x*25.4;
function tpi(x)  = inch(1/x);

// The bolt table provides parameters about the bolts (screws).  The rows
// must be sorted by the first entry.
//
// Each row of a bolt table row consists of:
//  [0] name (e.g., "M2", "#4-40", or "1/4-20")
//  [1] free-fit clearance hole diameter
//  [2] close-fit clearance hole diameter
//  [3] tapping hole diameter
//  [4] thread pitch
//  [5] maximum nut width (edge to edge, wrench size)
//  [6] maximum nut thickness

// This default table provides parameters for common metric and SAE machine
// screws, but you can substitute your own table if it conforms to the
// description above.
machine_screws = [
    // name     free-fit    close-fit   tapping     pitch       nut_w       nut_th
    ["#2-56",   thou( 96),  thou( 89),  thou( 70),  tpi(56),    inch(3/16), inch(1/16)],
    ["#4-40",   thou(120),  thou(116),  thou( 89),  tpi(40),    inch(1/4),  inch(3/32)],
    ["#6-32",   thou(149.5),thou(144),  thou(106.5),tpi(32),    inch(5/16), inch(7/64)],
    ["1/4-20",  thou(266),  thou(257),  thou(201),  tpi(20),    inch(7/16), inch(3/16)],
    ["M2",      2.4,        2.4,        1.6,        0.40,       4.00,       1.60      ],
    ["M2.5",    2.9,        2.8,        2.1,        0.45,       5.00,       2.00      ],
    ["M3",      3.4,        3.4,        2.5,        0.50,       5.50,       2.40      ],
    ["M4",      4.5,        4.3,        3.5,        0.70,       7.00,       3.20      ]
];

function find_row(key, table, low, high) =
  low > high ? undef :
  let(i = round_up(mid(low, high)))
    table[i][0] == key ? table[i] :
    table[i][0] <  key ? find_row(key, table, i+1, high) :
                         find_row(key, table, low, i-1);

function bolt_params(key, table) =
    let(row = find_row(key, table, 0, len(table) - 1))
    assert(!is_undef(row), "Bolt size not found in table.") row;

module bolt_hole(size, l, threads="none", table=machine_screws, nozzle_d=0.4) {
    $fs = nozzle_d/2;
    bolt = bolt_params(size, table=table);
    free_d = bolt[1];
    close_d = bolt[2];
    tap_d = bolt[3];
    pitch = bolt[4];
    shaft_d = (threads == "tapped" || threads == "heat-set insert") ?
        tap_d : free_d;
    union() {
        translate([0, 0, -l - 0.2]) cylinder(h=l + 0.3, d=shaft_d + nozzle_d);
    
        if (threads == "recessed hex nut") {
            nut_w = bolt[5];
            nut_d = round_up(nut_w / cos(30), nozzle_d);
            echo(nut_d);
            nut_th = bolt[6];
            protrusion = 2*pitch;
            translate([0, 0, -l - 0.1])
                cylinder(h=nut_th + protrusion + 0.1, d=nut_d + nozzle_d, $fn=6);
        }
    }
}

// This test shows a cutaway view of several example bolt holes.
module test() {
    spacing = 8;
    i = [spacing, 0, 0];
    w = 4*spacing;
    h = 10;
    rotate([$preview ? 0 : 180, 0, 0])
    difference() {
        cube([w, spacing, h]);
        if ($preview) {
            // cutaway
            translate([-1, -spacing/2, -1]) cube([w+2, spacing, h+2]);
        }
        translate([-spacing/2, spacing/2, 10]) {
            translate(1*i) bolt_hole("M3", 5, "tapped");
            translate(2*i) bolt_hole("M3", 10);
            translate(3*i) bolt_hole("M3", 10, "recessed hex nut");
            translate(4*i) bolt_hole("#4-40", 10, "recessed hex nut");
        }
    }
}

test();
