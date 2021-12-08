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
//  [5] head table
//  [6] nut table

// This default table provides parameters for common inch and metric machine
// screws, but you can substitute your own table if it conforms to the
// description above.
machine_screws = [
    // name     free-fit    close-fit   tapping     pitch
    ["#2-56",   thou( 96),  thou( 89),  thou( 70),  tpi(56),
        [ // head shape         head_d      head_h      sink
            ["flat",            thou(162),  thou( 51),  true    ],
            ["pan",             thou(167),  thou( 63),  false   ]],
        [ // nut                nut_w       nut_h           sides
            ["hex",             inch(3/16), inch(1/16),     6       ]]],
    ["#4-40",   thou(120),  thou(116),  thou( 89),  tpi(40),
        [ // head shape         head_d      head_h      sink
            ["flat",            thou(212),  thou( 67),  true    ],
            ["pan",             thou(219),  thou( 80),  false   ]],
        [ // nut                nut_w       nut_h           sides
            ["hex",             inch(1/4),  inch(3/32),     6       ]]],
    ["#6-32",   thou(149.5),thou(144),  thou(106.5),tpi(32),
        [ // head shape         head_d      head_h      sink
            ["flat",            thou(262),  thou( 83),  true    ],
            ["pan",             thou(270),  thou( 97),  false   ]],
        [ // nut                nut_w       nut_h           sides
            ["hex",             inch(5/16), inch(7/64),     6       ]]],
    ["1/4-20",  thou(266),  thou(257),  thou(201),  tpi(20),
        [ // head shape         head_d      head_h      sink
            ["flat",            thou(477),  thou(153),  true    ],
            ["pan",             thou(492),  thou(175),  false   ]],
        [ // nut                nut_w       nut_h           sides
            ["hex",             inch(7/16), inch(3/16),     6       ]]],
    ["M2",      2.4,        2.4,        1.6,        0.40,
        [ // head shape         head_d      head_h      sink
            ["flat",            3.8,        1.20,       true    ],
            ["pan",             4.0,        1.6,        false   ]],
        [ // nut                nut_w       nut_h           sides
            ["hex",             4.0,        1.6,            6       ]]],
    ["M2.5",    2.9,        2.8,        2.1,        0.45,
        [ // head shape         head_d      head_h      sink
            ["flat",            4.7,        1.50,       true],
            ["pan",             5.0,        2.0,        false   ]],
        [ // nut                nut_w       nut_h           sides
            ["hex",             5.0,        2.0,            6       ]]],
    ["M3",      3.4,        3.4,        2.5,        0.50,
        [ // head shape         head_d      head_h      sink
            ["flat",            5.6,        1.65,       true],
            ["pan",             6.0,        2.4,        false   ]],
        [ // nut                nut_w       nut_h           sides
            ["hex",             5.5,        2.4,            6       ]]],
    ["M4",      4.5,        4.3,        3.5,        0.70,
        [ // head shape         head_d      head_h      sink
            ["flat",            7.5,        2.20,       true    ],
            ["pan",             8.0,        3.1,        false   ]],
        [ // nut                nut_w       nut_h           sides
            ["hex",             7.0,        3.2,            6       ]]]
];

function find_bolt_params(size, table) =
    let (candidate=find_params(size, table=table))
    assert(!is_undef(candidate),
           str("bolt size \"", size, "\" not found in table"))
    candidate;

module bolt_hole(size, l, threads="none", head="proud", table=machine_screws, nozzle_d=0.4) {
    bolt = find_bolt_params(size, table=table);

    // Name the bolt parameters.
    free_d  = bolt[1];
    close_d = bolt[2];
    tap_d   = bolt[3];
    pitch   = bolt[4];
    head_table = bolt[5];
    nut_table = bolt[6];

    // Parse the threads option.
    threads_tokens = split(threads, " ");
    assert(len(threads_tokens) > 0);

    thread_types = [  //    shaft_d neednut pocket  recessed
        ["none",            free_d, false,  false,  false],
        ["pocket",          free_d, true,   true,   false],
        ["recessed",        free_d, true,   false,  true],
        ["self-tapping",    tap_d,  false,  false,  false]
    ];

    thread_synonyms = [
        ["",                "none"],
        ["pilot",           "self-tapping"],
        ["self tapping",    "self-tapping"],
        ["tapped",          "self-tapping"]
    ];

    thread_key = remap_key(front(threads_tokens), thread_synonyms);
    thread_params = find_params(thread_key, table=thread_types);
    assert(!is_undef(thread_params),
           str("`threads` type \"", join(threads_tokens), "\" not recognized"));
    
    shaft_d = thread_params[1];
    neednut = thread_params[2];
    pocket  = thread_params[3];
    recess  = thread_params[4];

    nut_tokens =
        let(tail = drop_front(threads_tokens))
            len(tail) > 1 && back(tail) == "nut" ? drop_back(tail) : tail;
    nut_string = join(nut_tokens, " ");
    nut_params =
        neednut ?
            let (key = nut_string == "nut" ? "hex" : nut_string,
                 candidate=find_params(key, table=nut_table))
                assert(!is_undef(candidate),
                       str("nut type \"", nut_string, "\" not found for \"",
                           size ,"\"; expected one of: ",
                           join([ for (i=nut_table) i[0] ], ", ")))
                candidate :
            assert(len(nut_string) == 0,
                   str("unexpected words in threads string \"", threads, "\""))
                ["no nut", 0, 0, 0];

    nut_w = nut_params[1];
    nut_h = nut_params[2];
    nut_sides = nut_params[3];

    panhead = find_params("pan", head_table);
    head_d  = panhead[1];
    head_h  = panhead[2];
    flathead = find_params("flat", head_table);
    flat_d  = flathead[1];
    flat_h  = flathead[2];

    head_types = [  //      drop    taper    
        ["counterbored",    head_h, false],
        ["countersunk",     0,      true ],
        ["proud",           0,      false]
    ];
    
    head_type = find_params(head, table=head_types);
    if (is_undef(head_type)) {
        echo(str("bolt_hole: `head` type \"", head, "\" not recognized"));
        echo(str("expected one of: ", join([for (i=head_types) i[0]], ", ")));
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
            // This forms the countersink for a flat head screw.
            translate([0, 0, -head_h])
                cylinder(h=head_h + 0.1, d1=close_d, d2=head_d + nozzle_d);
        }

        // The shaft of the screw.
        translate([0, 0, -l - 0.1]) cylinder(h=l + 0.2, d=shaft_d + nozzle_d);
    
        if (recess || pocket) {
            // Recess or pocket for a nut.
            nut_d = round_up(nut_w / cos(30), nozzle_d) + nozzle_d;
            protrusion = 2*pitch;
            h = nut_h + protrusion + (pocket ? 0 : 0.1);
            depth = -l - (pocket ? 0 : 0.1);
            translate([0, 0, depth]) {
                rotate([0, 0, 90]) cylinder(h=h, d=nut_d, $fn=nut_sides);
                if (pocket) {
                    pocket_w = nut_w + nozzle_d;
                    translate([-pocket_w/2, 0, 0])
                        cube([pocket_w, 1.5*nut_d, nut_h+nozzle_d/2]);
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
        translate([-spacing/2, depth/2, 10]) {
            translate(1*i) bolt_hole("M2", h/2, "self-tapping", "countersunk");
            translate(2*i) bolt_hole("M2.5", h/2, "pocket hex nut", "counterbored");
            translate(3*i) bolt_hole("M3", h, head="countersunk");
            translate(4*i) bolt_hole("#2-56", h, "recessed hex nut");
            translate(5*i) bolt_hole("#4-40", h, "self-tapping");
            translate(6*i) bolt_hole("#6-32", h, "recessed hex nut");
        }
        if ($preview) {
            // cutaway
            translate([-1, -depth/2, -1]) cube([w+2, depth, h+2]);
        }
    }
}

test();
