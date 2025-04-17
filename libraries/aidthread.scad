// Metric screw threads (polyhedron version)
// Adrian McCarthy 2023-11-05

// Generates a capped cylinder with "an inclined plane wrapped helically
// around [its] axis"[1] per the ISO standard for metric screws as
// summarized on Wikipedia.org.[2]
//
// Specify the desired height, the nominal diameter (e.g., 8mm for an
// M8 screw), and the thread pitch (in millimeters per one rotation).
//
// When tap is false, this produces a threaded cylinder oriented along
// the positive Z axis.  The actual outer diameter will be slightly
// less then the nominal diameter (by 1/8 of the thread height).
//
// When you want to make a threaded hole (as in a nut), set tap to true,
// and use a difference to subtract the threads from your object.  When
// tap is true, the nominal diameter is increased by a nozzle diameter
// (to create clearance appropriate for 3D printing) and the thread
// shape is altered to cut slightly deeper.  This seems to make a good
// fit for both printed threads and actual manufactured parts.
//
// I've had excellent results printing in PLA and PETG with a 0.4 mm
// nozzle at a 0.2 mm layer height.  The threads overhang at a
// 30 degree angle, which doesn't seem to be a problem for printing at
// with a pitch of up to 2 mm.  Drooping overhangs with pitches higher
// than 2 mm can make the thread profile asymmetric.  As a result, a
// nut might screw onto a bolt in one orientation but not the other.
//
// I usually render with $fn=60 for printing.  For preview, you might
// want to drop $fn to 15 to keep the view response from lagging too
// much.
//
// [1]: https://www.imdb.com/title/tt1632242/
// [2]: https://en.wikipedia.org/wiki/ISO_metric_screw_thread)
module AT_threads(h, d, pitch, tap=true, nozzle_d=0.4) {
    thread_h = pitch / (2*tan(30));
    adjusted_d = d + (tap ? nozzle_d : 0);
    d_major = adjusted_d - 2 * ((1/8) * thread_h);
    d_minor = d_major    - 2 * ((5/8) * thread_h);
    d_max = d_major + 2*thread_h/8;
    d_min = d_minor - 2*thread_h/4;
    
    echo(str(tap ? "Tapping " : "", "M", d, "x", pitch, ": ",
             "thread_h=", thread_h, "; ",
             "d_major=", d_major, "; ",
             "d_minor=", d_minor));

    x_major = 0;
    x_deep  = x_major + thread_h/8;
    x_minor = x_major - 5/8*thread_h;
    y_major = pitch/16;
    y_minor = 3/8 * pitch;
    
    r = d_major / 2;

    slices_per_turn =
        ($fn > 0) ? max(3, $fn)
                  : max(5, ceil(min(360/$fa, 2*PI*r / $fs)));
    dtheta = 360 / slices_per_turn;

    extended_h = h + pitch;
    
    slice_count = ceil(slices_per_turn * extended_h / pitch);

    function circle_points(z) = [
        for (i=[0:slices_per_turn-1])
            let (
                theta = i*dtheta,
                c = cos(theta),
                s = sin(theta)
            ) [c*(r + x_minor), s*(r + x_minor), z]
    ];

    function tooth_points(angle) = 
        let (c = cos(angle), s = sin(angle), z = pitch*angle/360)
        [
            [c*(r + x_minor), s*(r + x_minor), z + y_minor],
            [c*(r + x_major), s*(r + x_major), z + y_major],
            [c*(r + x_deep),  s*(r + x_deep),  z          ],
            [c*(r + x_major), s*(r + x_major), z - y_major],
            [c*(r + x_minor), s*(r + x_minor), z - y_minor]
        ];
    points_per_slice = len(tooth_points(0));

    function bottom(slice) =
        assert(slice <= slices_per_turn)
        slice % slices_per_turn;
    function top(slice)    =
        slice % slices_per_turn + slices_per_turn;
    function index(slice) =
        assert(slice <= slice_count)
        2*slices_per_turn + slice * points_per_slice;

    function panel(a0) = [
        let (
            s0 = a0 <= slice_count ? index(a0) : undef,
            l0 = a0 >= slices_per_turn ?
                index(a0 - slices_per_turn) : undef,
            skirt0b = l0 ? l0+0 : bottom(a0),
            skirt0t = a0 < slice_count ? s0+4 : top(a0),
            skirt0ex = a0 == slice_count ? [s0+4, s0+0] : [],
            u0 = a0 + slices_per_turn <= slice_count ?
                index(a0 + slices_per_turn) : undef,
            collar0ex = u0 ? [u0+4, u0+0] : [],

            a1 = a0 + 1,
            s1 = a1 <= slice_count ? index(a1) : undef,
            l1 = a1 >= slices_per_turn ?
                index(a1 - slices_per_turn) : undef,
            skirt1b = a1 > slices_per_turn ? l1+0 : bottom(a1),
            skirt1t = s1 ? s1+4 : top(a1),
            skirt1ex = l1 && (a1 == slices_per_turn) ?
                [l1+0, l1+4] : [],
            u1 = a1 + slices_per_turn <= slice_count ?
                index(a1 + slices_per_turn) : undef
        )
        each [
            each [if (s0 && s1)
                each [if (tap)
                    each [[s0+4, s0+2, s1+2, s1+4],
                          [s0+2, s0+0, s1+0, s1+2]]
                      else
                    each [[s0+4, s0+3, s1+3, s1+4],
                          [s0+3, s0+1, s1+1, s1+3],
                          [s0+1, s0+0, s1+0, s1+1]]
                ]
            ],
            [skirt0b, each skirt0ex, skirt0t, skirt1t, each skirt1ex, skirt1b],
            each [if (a0 == 0)
                each [if (tap) [s0+4, s0+0, s0+2]
                      else     [s0+4, s0+0, s0+1, s0+3]
                ]
            ],
            each [if (a1 == slice_count)
                each [if (tap) [s1+4, s1+2, s1+0]
                      else     [s1+4, s1+3, s1+1, s1+0]
                ],
            ],
            each [if (s0 && s1 && !u1) [s0+0, each collar0ex, top(a0), top(a1), s1+0]]
        ]
    ];

    all_points =
        [each circle_points(0-pitch/2),
         each circle_points(extended_h+pitch/2),
         for (slice=[0:slice_count]) each tooth_points(slice*dtheta)];

    panel_count = max(slice_count, slices_per_turn);
    all_faces = [
        each [for (a0=[0:panel_count-1]) each panel(a0)],
        [for (a0=[0:slices_per_turn-1]) bottom(a0)],
        [for (a0=[slices_per_turn-1:-1:0]) top(a0)]
    ];

    intersection() {
        translate([0, 0, -pitch/2])
            polyhedron(all_points, all_faces, convexity=6);
        // Intersect with a cube to trim it to final height
        extend = tap ? 0.1 : 0;
        translate([0, 0, -extend])
            linear_extrude(h+2*extend)
                square(d_max, center=true);
    }
}

module AT_demo_threads() {
    $fn = $preview ? 30 : 60;

    module pair(d, pitch) {
        head_d = 26;
        head_w = head_d*cos(30);
        head_th = 6;
        shaft_l = 4*pitch;
        label_size = 4;
        label_offset = head_w/2 - 0.2*label_size;
        label1 = str("M", d);
        label2 = str(pitch);

        module hex_head(th, r=2) {
            linear_extrude(th) {
                offset(r=r) offset(r=-r) circle(d=head_d, $fn=6);
            }
        }

        difference() {
            union() {
                hex_head(head_th);
                translate([0, 0, head_th])
                    AT_threads(h=shaft_l, d=d, pitch=pitch, tap=false, nozzle_d=0.4);
            }
            translate([0, 0, -0.1]) linear_extrude(0.5) mirror([1, 0, 0]) {
                translate([0, 0.7*label_size])
                    text(label1, size=label_size,
                         halign="center", valign="center");
                translate([0, -0.7*label_size])
                    text(label2, size=label_size,
                         halign="center", valign="center");
            }
        }

        rotate([0, 0, 30]) translate([head_d, 0, 0]) rotate([0, 0, 30]) {
            difference() {
                hex_head(shaft_l);
                AT_threads(h=shaft_l, d=d, pitch=pitch, tap=true, nozzle_d=0.4);
                translate([0, 0, -0.1]) linear_extrude(0.5) mirror([1, 0, 0]) {
                    translate([0, label_offset])
                        text(label1, size=label_size,
                             halign="center", valign="top");
                    translate([0, -label_offset])
                        text(label2, size=label_size,
                             halign="center", valign="bottom");
                }
            }
        }
    }
    translate([-50, -50, 0]) pair(12, 1.0);
//    translate([  0, -50, 0]) pair(12, 1.25);
    translate([ 50, -50, 0]) pair(12, 1.5);
//    translate([-50,   0, 0]) pair(12, 1.75);
    translate([  0,   0, 0]) pair(12, 2.0);
//    translate([ 50,   0, 0]) pair(12, 2.25);
    translate([-50,  50, 0]) pair(12, 2.5);
//    translate([  0,  50, 0]) pair(12, 2.75);
    translate([ 50,  50, 0]) pair(12, 3.0);
}

AT_demo_threads();
