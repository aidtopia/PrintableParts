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

// Each entry in a head table consists of:
//  [0] name (e.g., "flat", "pan", "oval", etc.)
//  [1] head diameter at the widest point
//  [2] head height
//  [3] sink height
// For most head types, the [2] head height column is the total head height.
// To recess a head, a cylindrical counterbore of the head height is necessary.
// For heads that have a tapered underside (like a flat or oval head), the
// [3] sink height determines the height of the cone shape necessary for the
// countersink.  Most head types have either a head height or a sink height
// but not both (i.e., the other height will be zero).  Oval heads, however,
// have both.  The head height is excluded from the length of the bolt, but
// the sink height is included.
//
// Each entry in the nut table consists of:
//  [0] name (e.g., "hex", "square", etc.)
//  [1] nut width (distance between flat opposing sides)
//  [2] nut height
//  [3] number of sides, most commonly 6
// When the number of sides is odd, the nut width is the diameter of a circle
// that circumscribes the nut.  For round nuts, like a tee nut, sides should
// be 1.

// This default table provides parameters for common inch and metric machine
// screws, but you can substitute your own table if it conforms to the
// description above.
machine_screws = [
    // name     free-fit    close-fit   tapping     pitch
    ["#2-56",   thou( 96),  thou( 89),  thou( 70),  tpi(56),
        [ // head shape         head_d      head_h      sink_h
            ["flat",            thou(162),  thou(  0),  thou( 51)   ],
            ["oval",            thou(162),  thou( 29),  thou( 80)   ],
            ["pan",             thou(167),  thou( 63),  thou(  0)   ],
            ["undercut oval",   thou(162),  thou( 29),  thou( 65)   ]],
        [ // nut                nut_w       nut_h           sides
            ["hex",             inch(3/16), inch(1/16),     6       ]]],
    ["#4-40",   thou(120),  thou(116),  thou( 89),  tpi(40),
        [ // head shape         head_d      head_h      sink_h
            ["flat",            thou(212),  thou(  0),  thou( 67)   ],
            ["oval",            thou(212),  thou(104),  thou( 37)   ],
            ["pan",             thou(219),  thou( 80),  thou(  0)   ],
            ["undercut oval",   thou(212),  thou( 84),  thou( 37)   ]],
        [ // nut                nut_w       nut_h           sides
            ["hex",             inch(1/4),  inch(3/32),     6       ]]],
    ["#6-32",   thou(149.5),thou(144),  thou(106.5),tpi(32),
        [ // head shape         head_d      head_h      sink_h
            ["flat",            thou(262),  thou(  0),  thou( 83)   ],
            ["oval",            thou(262),  thou( 45),  thou(128)   ],
            ["pan",             thou(270),  thou( 97),  thou(  0)   ],
            ["undercut",        thou(262),  thou( 45),  thou(104)   ]],
        [ // nut                nut_w       nut_h           sides
            ["hex",             inch(5/16), inch(7/64),     6       ]]],
    ["1/4-20",  thou(266),  thou(257),  thou(201),  tpi(20),
        [ // head shape         head_d      head_h      sink_h
            ["flat",            thou(477),  thou(  0),  thou(153)   ],
            ["pan",             thou(492),  thou(175),  thou(  0)   ]],
        [ // nut                nut_w       nut_h           sides
            ["hex",             inch(7/16), inch(3/16),     6       ]]],
    ["M2",      2.4,        2.4,        1.6,        0.40,
        [ // head shape         head_d      head_h      sink_h
            ["flat",            3.8,        0.0,        1.2         ],
            ["pan",             4.0,        1.6,        0.0         ]],
        [ // nut                nut_w       nut_h           sides
            ["hex",             4.0,        1.6,            6       ]]],
    ["M2.5",    2.9,        2.8,        2.1,        0.45,
        [ // head shape         head_d      head_h      sink_h
            ["flat",            4.7,        0.0,        1.50        ],
            ["pan",             5.0,        2.0,        0.0         ]],
        [ // nut                nut_w       nut_h           sides
            ["hex",             5.0,        2.0,            6       ]]],
    ["M3",      3.4,        3.4,        2.5,        0.50,
        [ // head shape         head_d      head_h      sink_h
            ["flat",            5.6,        0.0,        1.65        ],
            ["pan",             6.0,        2.4,        0.0         ]],
        [ // nut                nut_w       nut_h           sides
            ["hex",             5.5,        2.4,            6       ]]],
    ["M4",      4.5,        4.3,        3.5,        0.70,
        [ // head shape         head_d      head_h      sink_h
            ["flat",            7.5,        0.0,        2.20        ],
            ["pan",             8.0,        3.1,        0.0         ]],
        [ // nut                nut_w       nut_h           sides
            ["hex",             7.0,        3.2,            6       ]]]
];

function find_bolt_params(size, table) =
    let (candidate=find_params(size, table=table))
    assert(!is_undef(candidate),
           str("bolt size \"", size, "\" not found in table"))
    candidate;

function nut_diameter(nut_w, nut_sides=6, nozzle_d=0.4) =
    nozzle_d +
    ((nut_sides % 2) == 0 ?
        round_up(nut_w / cos(180/nut_sides), nozzle_d) :
        nut_w);


module bolt_hole(size, l, threads="none", head="pan", table=machine_screws, nozzle_d=0.4) {
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
                   str("unexpected words in `threads` string \"", threads, "\""))
                ["no nut", 0, 0, 0];

    nut_w = nut_params[1];
    nut_h = nut_params[2];
    nut_sides = nut_params[3];

    counterbore_synonyms = [
        ["counterbored",    "counterbore"],
        ["countersink",     "counterbore"],
        ["countersunk",     "counterbore"],
        ["flush",           "counterbore"],
        ["recessed",        "counterbore"]
    ];

    head_tokens = split(head);
    counterbore =
        remap_key(front(head_tokens), counterbore_synonyms) == "counterbore";
    head_shape_tokens = counterbore ? drop_front(head_tokens) : head_tokens;
    head_shape_tokens2 =
        back(head_shape_tokens) == "head" ?
            drop_back(head_shape_tokens) : head_shape_tokens;
    head_shape_tokens3 =
        len(head_shape_tokens2) > 0 ? head_shape_tokens2 : "pan";
    head_shape = join(head_shape_tokens3, " ");
    head_params = find_params(head_shape, table=head_table);
    assert(!is_undef(head_params),
           str("head shape \"", head_shape, "\" not recognized; ",
               "expected one of: ", join([for (i=head_table) i[0]], ", ")));

    head_d  = head_params[1];
    head_h  = head_params[2];
    sink_h  = head_params[3];

    drop    = counterbore ? head_h : 0;
    bevel   = sink_h == 0 && shaft_d == tap_d && l > 4*pitch;
    cone_h  = sink_h > 0 ? sink_h : bevel ? pitch : 0;
    cone_d1 = bevel ? shaft_d : close_d;
    cone_d2 = bevel ? free_d  : head_d;

    union() translate([0, 0, -drop]) {
        $fs = nozzle_d/2;

        // The head of the screw.
        cylinder(h=head_h + drop, d=head_d + nozzle_d);
        
        // The cone used as a countersink or as a small bevel to guide the
        // tap or self-tapping screw toward the center of the bore.
        if (cone_h > 0) {
            translate([0, 0, -cone_h])
                cylinder(h=cone_h + 0.1, d1=cone_d1, d2=cone_d2 + nozzle_d);
        }
        
        // The shaft of the screw.
        translate([0, 0, -l - 0.1]) cylinder(h=l + 0.2, d=shaft_d + nozzle_d);
    
        if (recess || pocket) {
            // Recess or pocket for a nut.
            nut_d = nut_diameter(nut_w, nut_sides, nozzle_d);
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

function boss_diameters(size, table=machine_screws, nozzle_d=0.4) =
  is_num(size) ? [size, size] :
    let(bolt = find_bolt_params(size, table=table),
        tap_d = bolt[3],
        head_table = bolt[5],
        head_params = find_params("pan", table=head_table),
        head_d = head_params[1],
        top_d = max(head_d, tap_d + 3*nozzle_d),
        nut_table = bolt[6],
        nut_params = find_params("hex", table=nut_table),
        nut_w = nut_params[1],
        nut_sides = nut_params[3],
        nut_d = nut_diameter(nut_w, nut_sides, nozzle_d),
        bottom_d = max(top_d, nut_d + 3*nozzle_d))
       [ bottom_d, top_d ];

module boss(size, h, table=machine_screws, nozzle_d=0.4) {
    boss_dias = boss_diameters(size, table, nozzle_d);
    translate([0, 0, -0.1])
        cylinder(h=h+0.1, d1=boss_dias[0], d2=boss_dias[1], $fs=nozzle_d/2);
}

module standoff(size, h, threads="self-tapping", table=machine_screws, nozzle_d=0.4) {
    bolt = find_bolt_params(size, table=table);

    // Name the bolt parameters.
    free_d  = bolt[1];
    close_d = bolt[2];
    tap_d   = bolt[3];
    pitch   = bolt[4];
    head_table = bolt[5];
    nut_table = bolt[6];
    
    head_params = find_params("pan", table=head_table);
    head_d  = head_params[1];
    
    boss_d = max(head_d, tap_d + 3*nozzle_d);

    difference() {
        translate([0, 0, -0.1]) cylinder(h=h+0.1, d=boss_d, $fs=nozzle_d/2);
        translate([0, 0, h]) bolt_hole(size, h, threads);
    }
}

function length_to_inch(length, denominator=32) =
    let(numerator = round_up(length*denominator/25.4),
        whole = floor(numerator / denominator),
        remainder = numerator - whole*denominator,
        f = gcd(remainder, denominator),
        num = remainder/f,
        den = denominator/f)
    str(den == 1 ? str(whole) : whole != 0 ? str(whole, "-") : "",
        str(num, "/", den), "\"");

function length_to_string(length, metric=true) =
    metric ? str(length, " mm") : length_to_inch(length, 8);

function screw_to_string(size, length) =
    let(metric = size[0] == "M")
    str(size, " by ", length_to_string(length, metric));

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
        union() {
            cube([w, depth, h]);
            translate([w + spacing/2, depth/2, 0]) boss("M3", h);
        }
        translate([-spacing/2, depth/2, 10]) {
            translate(1*i) bolt_hole("M2", h/2, "self-tapping", "flat");
            translate(2*i) bolt_hole("M2.5", h/2, "pocket hex nut", "counterbored pan head");
            translate(3*i) bolt_hole("M3", h, head="flat head");
            translate(4*i) bolt_hole("#2-56", h, "recessed hex nut", head=" oval");
            translate(5*i) bolt_hole("#4-40", h, "self-tapping", "recessed pan");
            translate(6*i) bolt_hole("#6-32", h, "recessed hex nut");
            translate(7*i) bolt_hole("M3", h+0.1, "recessed hex nut");
        }
        if ($preview) {
            // cutaway
            translate([-1, -depth/2, -1]) cube([2*w, depth, h+2]);
        }
    }
}

test();
