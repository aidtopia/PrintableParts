// Metric screw threads (polyhedron version)
// Adrian McCarthy 2023-11-05

// https://en.wikipedia.org/wiki/ISO_metric_screw_thread
// * internal thread: tap=true and subtract the resulting shape
// * external thread: tap=false

module AT_threads(h, d, pitch, tap=true, nozzle_d=0.4) {
    thread_h = pitch / (2*tan(30));
    // An M3 screw has a major diameter of 3 mm.  For a tap, we nudge it
    // up with the nozzle diameter to compensate for the problem of
    // printing accurate holes and to generally provide some clearance.
    d_major = d + (tap ? nozzle_d : -nozzle_d);
    d_minor = d_major - 2 * (5/8) * thread_h;
    d_max = d_major + 2*thread_h/8;
    d_min = d_minor - 2*thread_h/4;
    
    echo(str("M", d, "x", pitch, ": thread_h=", thread_h, "; d_major=", d_major, "; d_minor=", d_minor));

    x_major = 0;
    x_deep  = x_major + thread_h/8;
    x_minor = x_major - 5/8*thread_h;
    x_clear = x_minor - thread_h/4;
    y_major = pitch/16;
    y_minor = 3/8 * pitch;
    
    r = d_major / 2;

    slices_per_turn =
        ($fn > 0) ? max(3, $fn)
                  : max(5, ceil(min(360/$fa, 2*PI*r / $fs)));
    dtheta = 360 / slices_per_turn;
    echo(str("$fn=", $fn, ", $fa=", $fa, ", $fs=", $fs));
    echo(str("dtheta for threads = ", dtheta));
    echo(str("slices per turn = ", slices_per_turn));

    extended_h = h + pitch;
    
    slice_count = ceil(slices_per_turn * extended_h / pitch);
    full_turns = ceil(slice_count / slices_per_turn);

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
            [c*(r + x_deep),  s*(r + x_deep),  z          ],
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
            skirt0t = a0 < slice_count ? s0+2 : top(a0),
            skirt0ex = a0 == slice_count ? [s0+2, s0+0] : [],
            u0 = a0 + slices_per_turn <= slice_count ?
                index(a0 + slices_per_turn) : undef,
            collar0ex = u0 ? [u0+2, u0+0] : [],

            a1 = a0 + 1,
            s1 = a1 <= slice_count ? index(a1) : undef,
            l1 = a1 >= slices_per_turn ?
                index(a1 - slices_per_turn) : undef,
            skirt1b = a1 > slices_per_turn ? l1+0 : bottom(a1),
            skirt1t = s1 ? s1+2 : top(a1),
            skirt1ex = l1 && (a1 == slices_per_turn) ?
                [l1+0, l1+2] : [],
            u1 = a1 + slices_per_turn <= slice_count ?
                index(a1 + slices_per_turn) : undef
        )
        each [
            each [if (s0 && s1)
                each [[s0+2, s0+1, s1+1, s1+2],
                      [s0+1, s0+0, s1+0, s1+1]]
            ],
            [skirt0b, each skirt0ex, skirt0t, skirt1t, each skirt1ex, skirt1b],
            each [if (a0 == 0) [s0+2, s0+0, s0+1]],
            each [if (a1 == slice_count) [s1+2, s1+1, s1+0]],
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
    $fn=60;
    pitch=1.5;
    union() {
        cylinder(h=4, d=25, $fn=6);
        translate([0, 0, 4])
            AT_threads(h=4*pitch, d=18, pitch=pitch, tap=false, nozzle_d=0.4);
    }

    translate([30, 0, 0]) difference() {
        cylinder(h=4*pitch, d=25, $fn=6);
        AT_threads(h=4*pitch, d=18, pitch=pitch, tap=true, nozzle_d=0.4);
    }
}

AT_demo_threads();
