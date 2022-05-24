// My own implementations of gears for OpenSCAD.
// Adrian McCarthy 2022-05-21

// Useful information I found about involute gears:
// https://ciechanow.ski/gears/
// https://khkgears.net/new/gear_knowledge/abcs_of_gears-b/basic_gear_terminology_calculation.html
// and a few pages on Wikipedia (of course).

function radians(degrees) = PI * degrees / 180;
function degrees(radians) = 180 * radians / PI;

function circle_points(r=1, start_angle=0, stop_angle=360) =
    let (
        degrees = stop_angle - start_angle,
        step_a = ($fa > 0) ? ($fa/degrees) : 1,
        step_s = ($fs > 0) ? $fs / (2*PI*r*degrees/360) : 1,
        step   = ($fn > 0) ? 1/$fn : min(step_a, step_s)
    )
    [
        for (i = [0:step:1])
            let (theta = start_angle + i*degrees)
                [ r*cos(theta), r*sin(theta) ]
    ];

function involute_point(base_r=1, angle=0) =
    let (s=sin(angle), c=cos(angle), theta=radians(angle))
        [base_r*(c + theta*s), base_r*(s - theta*c)];

function involute_points(base_r=1, start_angle=0, stop_angle=360) =
    let(range = stop_angle - start_angle,
        facets = $fn > 0 ? $fn : 10,
        step = range / facets)
    [
        for (angle = [start_angle:step:stop_angle])
            involute_point(base_r, angle)
    ];

// We need the parametric angle at which an involute for a circle
// of `base_r` intersects a concentric circle of radius `r`.  This
// can be derived by plugging the Involute equations for x and y
// into sqrt(x^2 + y^2) == r and solving for theta.
// Remember that the angle returned is the one for generating the
// involute.  It does not indicate where it intersects the circle.
function intersect_involute_circle(base_r, r) =
    let (d = r/base_r, theta = sqrt(d*d - 1)) degrees(theta);

function rotated_point(pt, angle) =
    let (s=sin(angle), c=cos(angle))
        [ pt.x*c - pt.y*s, pt.x*s + pt.y*c ];

function rotated_points(points, angle) = [
    for (pt = points) rotated_point(pt, angle)
];

function flipped_point(pt) = [ pt.x, -pt.y ];
function flipped_points(points) = [
    for (i = [len(points):-1:1])
        let (pt = points[i-1])
            flipped_point(pt)
];

module mark_point(pt) {
    translate([pt.x, pt.y]) circle(r=0.5);
}

module mark_points(points) {
    for (pt = points) mark_point(pt);
}

module mark_circle(r, start_angle=0, stop_angle=360) {
    mark_points(circle_points(r, start_angle, stop_angle));
}

module mark_involute(base_r, start_angle=0, stop_angle=360) {
    mark_points(involute_points(base_r, start_angle, stop_angle));
}

module mark_radial(angle=0, start_r=0, end_r=1) {
    s = sin(angle);
    c = cos(angle);
    range = end_r - start_r;
    for (i = [0:5])
        let (h = start_r + (range*i/5))
            mark_point([h*c, h*s]);
}

function test(foo=1) =
    assert(foo > 0, "foo much be greater than 0")
    [ for (i = [foo:3*foo]) i ];

function spur_gear(
    number_of_teeth=15,
    // ISO defines compatible tooth sizes using a ratio called
    // the module.  Since `module` is a keyword in OpenSCAD, we'll
    // call it `module_size`.  Note that this is considered unitless
    // because `pitch_r` is assumed to be in millimeters.
    module_size=2,
    // The pressure angle is the direction of the force vector
    // between teeth of meshed gears.  Common pressure angles are
    // usually in the range of 15-20 degrees, but 3D printed gears
    // benefit from somewhat larger pressure angles.
    pressure_angle = 28,
    // Backlash shaves a little off of each tooth, leaving the gaps
    // slightly wider than the teeth themselves.
    backlash=0,
    // Clearance increases the dedendum (lowering of the root circle).
    clearance=0.25,  // ISO value
    // Name lets you name individual gears to distinguish them in
    // OpenSCAD's console output.
    name="spur gear"
) =
    assert(number_of_teeth > 0,
           "spur_gear: number of teeth must be positive")
    assert(number_of_teeth == floor(number_of_teeth),
           "spur_gear: number of teeth must be an integer")
    assert(module_size > 0,
           "spur_gear: module size must be positive")
    assert(0 < pressure_angle && pressure_angle < 90,
           "spur_gear: pressure angle must be 0-90 degrees")
    assert(clearance >= 0,
           "spur_gear: clearance cannot be negative")

    let (
        // The pitch circle, sometimes called the reference circle, is
        // the size of the equivalent toothless disc if we were using
        // discs instead of gears.
        pitch_r = module_size * number_of_teeth / 2,

        // In the U.S., the tooth size is often given in diametral
        // pitch, which is just the reciprocal of the `module_size` with
        // a millimeter-to-inch conversion.  This is just for
        // documentation at this point.
        diametral_pitch = 25.4 / module_size,

        // The addendum is how far beyond the pitch circle the tips of
        // the teeth extend.
        addendum = 1.00 * module_size,  // ISO definition
        addendum_r = pitch_r + addendum,

        // The dedendum is the radial distance from the pitch circle to
        // the bottoms of the teeth.  This "gum line" is called the
        // root circle.
        dedendum = (1 + clearance) * module_size,
        root_r = pitch_r - dedendum,

        // The base circle is the point where the involute part of the
        // the tooth profile begins.
        base_r = pitch_r * cos(pressure_angle),

        // The width of a tooth is measured at the pitch circle.
        tooth_width = PI * module_size / 2 - backlash,
        
        // Tooth width can also be expressed as the angle subtended.
        nominal_tooth_angle = degrees(tooth_width / pitch_r),

        // Because the involute is drawn from the base circle, we
        // need to adjust the `nominal_tooth_angle` to compensate for
        // the difference between the involute's offsets at `base_r`
        // and `root_r`.
        involute_angle_at_pitch_r =
            intersect_involute_circle(base_r, pitch_r),
        pitch_hit = involute_point(base_r, involute_angle_at_pitch_r),
        tooth_angle_correction = 2*atan2(pitch_hit.y, pitch_hit.x),

        tooth_angle = nominal_tooth_angle + tooth_angle_correction,

        // In extreme cases, the root circle may be wider than the base
        // circle.  That's not an error, but it means we need a bit
        // less of the involute.
        start_r = max(root_r, base_r),

        // Points on the involute are generated by a parametric angle.
        // In order to generate the section of the involute we need,
        // we'll need to know the parametric angles at the base circle
        // (where the involute part of the tooth shape begins) and the
        // addendum circle (where the teeth tips lie).
        start_angle = intersect_involute_circle(base_r, start_r),
        stop_angle = intersect_involute_circle(base_r, addendum_r),

        // So here's the piece of the involute we need.
        inv_path = involute_points(base_r, start_angle, stop_angle),
        
        // Connect the root circle to the involute (in the normal case).
        path =
            (root_r < start_r) ?
                [[root_r, 0], each inv_path] : inv_path,

        flipped = flipped_points(path)
    )
    
    assert(root_r > 0)
    echo(str("\n--- ", name, " ---\n",
             "teeth:  \t\t", number_of_teeth, "\n",
             "module:\t\t", module_size, " mm/tooth\n",
             "pressure angle:\t", pressure_angle, " degrees\n",
             "diametral pitch:\t", diametral_pitch, " teeth/inch\n",
             "pitch radius:\t", pitch_r, " mm\n",
             "outer radius:\t", addendum_r, " mm\n"))

    [ for (i = [1:number_of_teeth])
        let (
            theta = i * 360/number_of_teeth,
            theta1 = theta - tooth_angle/2,
            theta2 = theta1 + tooth_angle,
            tooth_path =
                [each rotated_points(path,    theta1),
                 each rotated_points(flipped, theta2)]
        )
            each tooth_path
    ];

module bore(h=1, d=1, nozzle_d=0.4) {
    difference() {
        union() { children(); }
        translate([0, 0, -0.01])
            cylinder(h=h+0.02, d=d+nozzle_d, $fs=nozzle_d/2);
    }
}

color("white")
    bore(d=4, h=4)
        linear_extrude(3, convexity=10)
            polygon(
                spur_gear(number_of_teeth=11,
                          module_size=2,
                          name="pinion"));
color("yellow") translate([35, 0, 0])
    bore(d=4, h=4)
        linear_extrude(3, convexity=10)
            polygon(
                spur_gear(number_of_teeth=23,
                          module_size=2,
                          name="G1"));

color("green") translate([-40, 0, 0]) {
    linear_extrude(2) circle(r=25.4);
    linear_extrude(7) {
        translate([-34/2, 0, 0]) circle(d=4, $fs=0.2);
        translate([ 34/2, 0, 0]) circle(d=4, $fs=0.2);
    }
}
