// My own implementations of gears for OpenSCAD.
// Adrian McCarthy 2022-05-21

// Useful information I found about involute gears:
// https://ciechanow.ski/gears/
// https://khkgears.net/new/gear_knowledge/abcs_of_gears-b/basic_gear_terminology_calculation.html
// and a few pages on Wikipedia (of course).

function radians_from_degrees(degrees) = PI * degrees / 180;
function degrees_from_radians(radians) = 180 * radians / PI;

// Internally, we compute gear parameters in terms of its ISO module,
// but users might want to specify the gear size in terms of pitch.

// The metric module is a base unit in millimeters.
function m(iso_module) = iso_module;

// The circular pitch is the distance from the center of one tooth to
// the center of an adjacent tooth, measured along the pitch circle.
function CP(circular_pitch) = circular_pitch / PI;

// The diametral pitch, commonly used in the U.S. and U.K., is the
// reciprocal of the module, and is specified in inches.
function DP(diametral_pitch) = 25.4 / diametral_pitch;

function circle_points(r=1, start_angle=0, stop_angle=360) =
    let (
        range = stop_angle - start_angle,
        step_a = ($fa > 0) ? ($fa/range) : 1,
        step_s = ($fs > 0) ? $fs / (2*PI*r*range/360) : 1,
        step   = ($fn > 0) ? 1/$fn : min(step_a, step_s)
    )
    [
        for (i = [0:step:1])
            let (theta = start_angle + i*range)
                [ r*cos(theta), r*sin(theta) ]
    ];

// TODO:  Rename the angle parameter to something like `rolling_angle`.
function involute_point(base_r=1, angle=0) =
    let (
        s=sin(angle), c=cos(angle),
        theta=radians_from_degrees(angle)
    )
    [ base_r*(c + theta*s), base_r*(s - theta*c) ];

function involute_points(base_r=1, start_angle=0, stop_angle=360) =
    let(range = stop_angle - start_angle,
        facets = $fn > 0 ? $fn : 7,
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
    let (d = r/base_r, theta = sqrt(d*d - 1))
        degrees_from_radians(theta);

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

function mirrored_point(pt) = [ -pt.x, pt.y ];
function mirrored_points(points) = [
    for (pt = points) mirrored_point(pt)
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

function spur_gear_profile(
    number_of_teeth=15,
    // ISO defines compatible tooth sizes using a ratio called
    // the module.  Since `module` is a keyword in OpenSCAD, we'll
    // call it `iso_module`.  Note that this is considered unitless
    // because `pitch_r` is assumed to be in millimeters.
    iso_module=2,
    // The pressure angle is the direction of the force vector
    // between teeth of meshed gears.  Common pressure angles are
    // usually in the range of 15-20 degrees, but 3D printed gears
    // benefit from somewhat larger pressure angles.
    pressure_angle=28,
    // Clearance increases the dedendum (lowering of the root circle).
    clearance=0.25,  // ISO value
    // Backlash shaves a little off of each tooth, leaving the gaps
    // slightly wider than the teeth themselves.
    backlash_angle=0,
    // Name lets you name individual gears to distinguish them in
    // OpenSCAD's console output.
    name="spur gear"
) =
    assert(number_of_teeth > 0,
           "spur_gear: number of teeth must be positive")
    assert(number_of_teeth == floor(number_of_teeth),
           "spur_gear: number of teeth must be an integer")
    assert(iso_module > 0,
           "spur_gear: module size must be positive")
    assert(0 < pressure_angle && pressure_angle < 45,
           "spur_gear: pressure angle must be 0-45 degrees")

    let (minimum_teeth = floor(2 / pow(sin(pressure_angle), 2)))
    assert(number_of_teeth >= minimum_teeth,
           str("spur_gear: ", minimum_teeth, " is the minimum number ",
               "of teeth to avoid undercuts given a pressure angle of ",
               pressure_angle, "°"))

    assert(clearance >= 0,
           "spur_gear: clearance cannot be negative")

    let (
        // In the U.S., the tooth size is often given in diametral
        // pitch, which is just the reciprocal of the `iso_module` with
        // a millimeter-to-inch conversion.
        diametral_pitch = 25.4 / iso_module,
        
        // Circular pitch (also called the reference pitch) is the arc
        // distance (in mm) between corresponding points on adjacent teeth.
        circular_pitch = iso_module * PI,

        // The pitch circle, sometimes called the reference circle, is
        // the size of the equivalent toothless disc if we were using
        // toothless discs instead of gears.
        pitch_d = iso_module * number_of_teeth,
        pitch_r = pitch_d / 2,

        // The addendum is how far beyond the pitch circle the tips of
        // the teeth extend.
        addendum = 1.00 * iso_module,  // ISO definition
        addendum_r = pitch_r + addendum,

        // The dedendum is the radial distance from the pitch circle to
        // the bottoms of the teeth.  This "gum line" is called the
        // root circle.
        dedendum = (1 + clearance) * iso_module,
        root_r = pitch_r - dedendum,

        // The base circle is the point where the involute part of the
        // the tooth profile begins.
        base_r = pitch_r * cos(pressure_angle),

        // The nominal width of a tooth is half of the circular pitch
        // (because the other half is the gap between adjacent teeth).
        nominal_tooth_width = circular_pitch / 2,
        
        // But we want the tooth width in terms of an angle.  Note that
        // the backlash angle is typically very small (or 0).
        nominal_tooth_angle = (360 / number_of_teeth - backlash_angle) / 2,

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
        
        // TODO fillet at root circle
        // TODO tip relief
        // TODO crowning of tooth surface
    )
    
    assert(root_r > 0)

    echo(str("\n--- ", name, " ---\n",
             "tooth count:\t", number_of_teeth, "\n",
             "gear size:\n",
             "  module:\t", iso_module, " mm\n",
             "  circular pitch:\t", circular_pitch, " mm tooth-to-tooth\n",
             "  diametral pitch:\t", diametral_pitch," teeth/inch\n",
             "pressure angle:\t", pressure_angle, " degrees\n",
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

function rack_profile(
    number_of_teeth=15,
    // ISO defines compatible tooth sizes using a ratio called
    // the module.
    iso_module=2,
    // The pressure angle is the direction of the force vector
    // between teeth of meshed gears.  Common pressure angles are
    // usually in the range of 15-20 degrees, but 3D printed gears
    // benefit from somewhat larger pressure angles.
    pressure_angle=28,
    // Clearance increases the dedendum (depth of the teeth).
    clearance=0.25,  // ISO value
    // Backlash shaves a little off of each tooth, leaving the gaps
    // slightly wider than the teeth themselves.
    backlash_angle=0,
    // Names individual gears to distinguish them in OpenSCAD's
    // console output.
    name="rack"
) =
    let (
        CP = PI * iso_module,
        ref_y = 0,
        addendum = 1.00 * iso_module,
        tip_y = ref_y + addendum,
        dedendum = (1.00 + clearance) * iso_module,
        root_y = ref_y - dedendum,
        alpha = pressure_angle - backlash_angle,
        run_at_ref = dedendum*tan(alpha),
        rise = addendum + dedendum,
        run = rise*tan(alpha),
        flat = (CP - 2*run)/2,
        w = CP * number_of_teeth
    )
    
    [
        [0, root_y - dedendum], [0, root_y],
        each [
            for (i=[1:number_of_teeth])
                let (
                    center = (i - 0.5) * CP,
                    ltip = center - flat/2,
                    rtip = center + flat/2,
                    lroot = ltip - run,
                    rroot = rtip + run
                )
                each [
                    [lroot, root_y], [ltip, tip_y],
                    [rtip, tip_y], [rroot, root_y]
                ]
        ],
        [w, root_y], [w, root_y - dedendum]
    ];


module bore(h=1, d=1, nozzle_d=0.4) {
    difference() {
        union() { children(); }
        translate([0, 0, -0.01])
            cylinder(h=h+0.02, d=d+nozzle_d, $fs=nozzle_d/2);
    }
}

module spur_gear(
    number_of_teeth=15,
    // ISO defines compatible tooth sizes using a ratio called
    // the module.  Since `module` is a keyword in OpenSCAD, we'll
    // call it `iso_module`.
    iso_module=2,
    // The pressure angle is the direction of the force vector
    // between teeth of meshed gears.  Common pressure angles are
    // usually in the range of 15-20 degrees, but 3D printed gears
    // benefit from somewhat larger pressure angles.
    pressure_angle=28,
    // Backlash shaves a little off of each tooth, leaving the gaps
    // slightly wider than the teeth themselves.
    backlash_angle=0,
    // Clearance increases the dedendum (lowering of the root circle).
    clearance=0.25,  // ISO value
    // Name your gears to distinguish them in OpenSCAD's console output.
    name="spur gear"
) {
    profile =
        spur_gear_profile(number_of_teeth, iso_module, pressure_angle,
                          backlash_angle, clearance, name);
    pitch_r = iso_module * number_of_teeth / 2;
    base_r = pitch_r * cos(pressure_angle);
    dedendum = (1 + clearance) * iso_module;
    root_r = pitch_r - dedendum;

    difference() {
        linear_extrude(4, convexity=10) polygon(profile);
        translate([0, 0, 2.5]) linear_extrude(4, convexity=10) {
            rotate([0, 0, -90]) {
                translate([0, root_r/2]) scale(pitch_r/50) union() {
                    translate([0, 7])
                    text(name, size=10, font="Liberation Sans:style=Bold",
                         halign="center", valign="center", spacing=1.1);
                    translate([0, -5])
                    text(str("m", iso_module, "   α", pressure_angle, "°"),
                         size=10, font="Liberation Sans:style=Bold", halign="center", valign="center");
                }
                translate([0, -root_r/2]) scale(pitch_r/50) union() {
                    translate([0, -7])
                    text(str("r", pitch_r, "mm"),
                         size=10, font="Liberation Sans:style=Bold", halign="center", valign="center");
                    translate([0, 5])
                    text(str("n", number_of_teeth),
                         size=10, font="Liberation Sans:style=Bold", halign="center", valign="center");
                }

                if (iso_module >= 5) {
                    for (i = [1:number_of_teeth]) {
                        angle = -(i-1) * 360 / number_of_teeth;
                        rotate([0, 0, angle]) translate([0, root_r])
                        text(str(i), size=iso_module,
                             halign="center", valign="bottom");
                    }
                } else {
                    translate([0, root_r + iso_module/2])
                        square(iso_module, center=true);
                }
            }
        }
    }
}

bore_d = 3.175;
pinion = spur_gear_profile(number_of_teeth=11, iso_module=2, name="pinion");
G1 = spur_gear_profile(number_of_teeth=23, iso_module=2, name="G1");
G2 = rack_profile(23, iso_module=2, name="G2");

translate([0, -35, 0]) {
    color("white") bore(d=bore_d, h=4) linear_extrude(4, convexity=10)
        polygon(pinion);

    translate([35, 0, 0]) {
        color("yellow") bore(d=bore_d, h=4) linear_extrude(4, convexity=10)
            polygon(G1);
    }

    color("green") translate([-40, 0, 0]) {
        linear_extrude(2) circle(r=25.4);
        linear_extrude(7) {
            translate([-34/2, 0, 0]) circle(d=bore_d, $fs=0.2);
            translate([ 34/2, 0, 0]) circle(d=bore_d, $fs=0.2);
        }
    }
}

translate([-23*2*PI/2, 0, 0])
color("orange")
    linear_extrude(5, convexity=10) polygon(G2);
