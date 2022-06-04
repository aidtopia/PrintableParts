// My own implementations of gears for OpenSCAD.
// Adrian McCarthy 2022-05-21

// Useful references I found about gear nomenclature, calculations, and
// involute tooth shapes:
// * https://ciechanow.ski/gears/
// * https://khkgears.net/new/gear_knowledge/gear_technical_reference/
// * https://drivetrainhub.com/notebooks/gears/geometry/Chapter%203%20-%20Helical%20Gears.html
// and a few pages on Wikipedia (of course).

// GEAR DEFINITIONS

// OpenSCAD doesn't have user-defined types, but we're going to use a
// vector as an aggregate data type to hold the parameters that define
// the tooth pattern of a gear.  These accessor functions shows the
// mapping from index to field.  Always use the accessor functions for
// compatibility with future versions. 

function AG_type(g)             = assert(len(g) > 0) g[0];
function AG_name(g)             = assert(len(g) > 1) g[1];
function AG_tooth_count(g)      = assert(len(g) > 2) g[2];
function AG_module(g)           = assert(len(g) > 3) g[3];
function AG_pressure_angle(g)   = assert(len(g) > 4) g[4];
function AG_backlash_angle(g)   = assert(len(g) > 5) g[5];
function AG_clearance(g)        = assert(len(g) > 6) g[6];
function AG_helix_angle(g)      = (len(g) > 7) ? g[7] : 0;

// Higher indexes are reserved for future use
//
// Instead of creating these vectors by hand, there are AG_define_...
// functions to define the desired gear.

function AG_define_gear(
    tooth_count=15,
    iso_module=undef, circular_pitch=undef, diametral_pitch=undef,
    pressure_angle=28,
    backlash_angle=0,
    clearance=0.25,  // ISO value
    helix_angle=0,
    name="spur gear"
) =
    AG_define_universal("AG spur", name, tooth_count,
                        iso_module, circular_pitch, diametral_pitch,
                        pressure_angle, backlash_angle, clearance,
                        helix_angle);

function AG_define_rack(
    tooth_count=15,
    iso_module=undef, circular_pitch=undef, diametral_pitch=undef,
    pressure_angle=28,
    backlash_angle=0,
    clearance=0.25,  // ISO value
    helix_angle=0,
    name="rack"
) =
    AG_define_universal("AG rack", name, tooth_count,
                        iso_module, circular_pitch, diametral_pitch,
                        pressure_angle, backlash_angle, clearance,
                        helix_angle);

function AG_define_universal(
    type,
    name,
    tooth_count,
    iso_module, circular_pitch, diametral_pitch,
    pressure_angle,
    backlash_angle,
    clearance,
    helix_angle
) =
    let (iso_module =
            AG_as_module(iso_module, circular_pitch, diametral_pitch, 2))

    assert(tooth_count > 0,
           "AG: tooth count must be positive")
    assert(tooth_count == floor(tooth_count),
           "AG: tooth_count must be an integer")
    assert(iso_module > 0,
           "AG: module size must be positive")
    assert(0 < pressure_angle && pressure_angle < 45,
           "AG: pressure angle must be 0-45°")
    assert(0 <= backlash_angle && backlash_angle < 360/tooth_count,
           "AG: backlash angle should be small and positive")
    assert(clearance >= 0,
           "AG: clearance cannot be negative")
    assert(-90 < helix_angle && helix_angle < 90,
           "AG: absolute value of the helix angle shold be less than 90°")

//    let (minimum_teeth = floor(2 / pow(sin(pressure_angle), 2)))
//    assert(tooth_count >= minimum_teeth,
//           str("AG: ", minimum_teeth, " is the minimum number of ",
//               "teeth to avoid undercuts given a pressure angle of ",
//               pressure_angle, "°"))

    [
        type, name, tooth_count, iso_module,
        pressure_angle, backlash_angle, clearance,
        helix_angle
    ];

// Internally, we use ISO module.  This function converts various ways of
// representing the tooth size to ISO module.
function AG_as_module(
    iso_module=undef,
    circular_pitch=undef,
    diametral_pitch=undef,
    default=2
) =
    !is_undef(iso_module) ? iso_module :
    !is_undef(circular_pitch) ? circular_pitch / PI :
    !is_undef(diametral_pitch) ? 25.4 / diametral_pitch :
    assert(!is_undef(default),
           "AG: tooth size must be specified with module, CP, or DP")
    default;


module AG_echo(g) {
    assert(len(g) > 0 && len(g[0]) > 2 && g[0][0] == "A" && g[0][1] == "G",
           "AG: not a gear definition")
    echo(str("\n--- ", AG_name(g), " (" , AG_type(g), ") ---\n",
             "tooth count:\t", AG_tooth_count(g), "\n",
             "gear size:\n",
             "  module:\t", AG_module(g), " mm\n",
             "  circular pitch:\t", AG_circular_pitch(g),
                " mm tooth-to-tooth\n",
             "  diametral pitch:\t", AG_diametral_pitch(g)," teeth/inch\n",
             "pressure angle:\t", AG_pressure_angle(g), " degrees\n",
             "backlash angle:\t", AG_backlash_angle(g), " degrees\n",
             "clearance:\t", AG_clearance(g), "\n",
             "pitch radius:\t", AG_pitch_diameter(g)/2, " mm\n",
             "helix angle:\t", AG_helix_angle(g), " degrees\n"));
}

function AG_circular_pitch(g)   = PI * AG_module(g);

function AG_diametral_pitch(g)  = 25.4 / AG_module(g);

function AG_pitch_diameter(g)   =
    let (type = AG_type(g))
    type == "AG spur" ? AG_module(g) * AG_tooth_count(g) :
    type == "AG rack" ? 0 :
    undef;

function AG_outer_diameter(g)   = AG_pitch_diameter(g) + 2*AG_addendum(g);

function AG_inner_diameter(g)   = AG_pitch_diameter(g) - 2*AG_dedendum(g);

function AG_addendum(g)         = 1.00 * AG_module(g);

function AG_dedendum(g)         = (1.00 + AG_clearance(g)) * AG_module(g);

// Returns true if the two gears can mesh.
function AG_compatible(g1, g2) =
    AG_module(g1) == AG_module(g2) &&
    AG_pressure_angle(g1) == AG_pressure_angle(g2) &&
    AG_helix_angle(g1) == -AG_helix_angle(g2);

// The center distance is the spacing required between the centers of two
// gears to have them mesh properly.
function AG_center_distance(g1, g2) =
    assert(AG_compatible(g1, g2),
           "AG: cannot compute the center distance for incompatible gears")
    (AG_pitch_diameter(g1) + AG_pitch_diameter(g2)) / 2;



// Returns a list of points forming a 2D-polygon of the gear teeth.
function AG_tooth_profile(g) =
    let (type = AG_type(g))
    type == "AG spur" ? AG_spur_tooth_profile(g) :
    type == "AG rack" ? AG_rack_tooth_profile(g) :
    assert(false, str("AG: '", type, "' is not a recognized gear type"))
    [];

function AG_spur_tooth_profile(g) =
    let (
        // The pitch circle, sometimes called the reference circle, is
        // the size of the equivalent toothless disc if we were using
        // toothless discs instead of gears.
        pitch_r = AG_pitch_diameter(g)/2,

        // The addendum is how far beyond the pitch circle the tips of
        // the teeth extend.
        addendum_r = pitch_r + AG_addendum(g),

        // The dedendum is the radial distance from the pitch circle to
        // the bottoms of the teeth.  This "gum line" is called the
        // root circle.
        root_r = pitch_r - AG_dedendum(g),
        
        // The base circle is the point where the involute part of the
        // the tooth profile begins.
        base_r = pitch_r * cos(AG_pressure_angle(g)),

        // We want the tooth width in terms of the angle it subtends.
        // Note that the backlash angle is typically very small (or 0).
        tooth_count = AG_tooth_count(g),
        nominal_tooth_angle = (360/tooth_count - AG_backlash_angle(g)) / 2,

        // Because the involute is drawn from the base circle, we
        // need to adjust the `nominal_tooth_angle` to compensate for
        // the difference between the involute's offsets at `base_r`
        // and `pitch_r`.
        rolling_angle_at_pitch =
            intersect_involute_circle(base_r, pitch_r),
        pitch_hit = involute_point(base_r, rolling_angle_at_pitch),
        tooth_angle_correction = 2*atan2(pitch_hit.y, pitch_hit.x),
        tooth_angle = nominal_tooth_angle + tooth_angle_correction,

        // In extreme cases, the root circle may be wider than the base
        // circle.  That's not an error, but it means we need a bit
        // less of the involute.
        start_r = max(root_r, base_r),

        // Points on the involute are generated by a parametric angle.
        // In order to generate the section of the involute we need,
        // we'll need to know the rolling angles for the involute at the
        // base circle (where the involute part of the tooth shape begins)
        // and the addendum circle (where the teeth tips lie).
        rolling0 = intersect_involute_circle(base_r, start_r),
        rolling1 = intersect_involute_circle(base_r, addendum_r),

        // So here's the piece of the involute we need.
        inv_path = involute_points(base_r, rolling0, rolling1),
        
        // Connect the root circle to the involute (in the normal case).
        path =
            (root_r < start_r) ?
                [[root_r, 0], each inv_path] : inv_path,

        flipped = flipped_points(path)
        
        // TODO fillet at root circle
        // TODO tip relief
        // TODO crowning of tooth surface?
    )
    
    assert(root_r > 0)

    [ for (i = [1:tooth_count])
        let (
            theta = i * 360/tooth_count,
            theta1 = theta - tooth_angle/2,
            theta2 = theta1 + tooth_angle,
            tooth_path =
                [each rotated_points(path,    theta1),
                 each rotated_points(flipped, theta2)]
        )
            each tooth_path
    ];

function AG_rack_tooth_profile(g) =
    let (
        CP = AG_circular_pitch(g),
        ref_y = 0,
        ha = AG_addendum(g),
        tip_y = ref_y + ha,
        hd = AG_dedendum(g),
        root_y = ref_y - hd,
        alpha = AG_pressure_angle(g) - AG_backlash_angle(g),
        run_at_ref = hd*tan(alpha),
        rise = ha + hd,
        run = rise*tan(alpha),
        flat = (CP - 2*run)/2,
        tooth_count = AG_tooth_count(g),
        w = CP * tooth_count
    )
    
    [
        [0, root_y],
        each [
            for (i=[1:tooth_count])
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
        [w, root_y]
    ];

function AG_rack_width(rack) =
     assert(AG_type(rack) == "AG rack")
     AG_circular_pitch(rack) * AG_tooth_count(rack);

function AG_rack_profile(rack, height_to_pitch=undef) =
    assert(AG_type(rack) == "AG rack")
    let (
        h = is_undef(height_to_pitch) ? 10*(AG_module(rack) + 0.5) :
                                        height_to_pitch,
        foundation = -h,
        w = AG_rack_width(rack)
    )
    [ [0, foundation], each AG_tooth_profile(rack), [w, foundation] ];

function AG_rack_shear(rack, th=1) =
    tan(AG_helix_angle(rack));



module AG_gear(gear, th=3, convexity=10, center=false, herringbone=false) {
    assert(AG_type(gear) == "AG spur");
    assert(herringbone == false || AG_helix_angle(gear) != 0,
           "AG: cannot create \"herringbone\" gear when helix angle is 0");
    w = herringbone ? th/2 : th;
    circumference = PI * AG_pitch_diameter(gear);
    twist = w*360*tan(AG_helix_angle(gear))/circumference;
    profile = AG_tooth_profile(gear);
    drop = center ? th/2 : 0;

    translate([0, 0, -drop])
    difference() {
        union() {
            linear_extrude(w, convexity=convexity, twist=twist)
                polygon(profile);
            if (herringbone) {
                translate([0, 0, w]) rotate([0, 0, -twist])
                linear_extrude(w, convexity=convexity, twist=-twist)
                    polygon(profile);
            }
        }

        translate([0, 0, -1])
            linear_extrude(th+2, convexity=convexity, center=center)
                children();
    }
}

module AG_rack(rack, th=3, height_to_pitch=undef, convexity=10, center=false, herringbone=false) {
    assert(AG_type(rack) == "AG rack");
    assert(herringbone == false || AG_helix_angle(rack) != 0,
           "AG: cannot create \"herringbone\" rack when helix angle is 0");
    w = herringbone ? th/2 : th;
    shear = AG_rack_shear(rack, w);
    profile = AG_rack_profile(rack, height_to_pitch);
    drop = center ? th/2 : 0;

    union() {
        translate([0, 0, -drop])
        multmatrix([
            [1, 0, shear, 0],
            [0, 1,     0, 0],
            [0, 0,     1, 0]
        ]) {
            linear_extrude(w, convexity=convexity) polygon(profile);
        }

        if (herringbone) {
            translate([shear*w, 0, w-drop])
            multmatrix([
                [1, 0, -shear, 0],
                [0, 1,     0, 0],
                [0, 0,     1, 0]
            ]) {
                linear_extrude(w, convexity=convexity) polygon(profile);
            }
        }
    }
}

function radians_from_degrees(degrees) = PI * degrees / 180;
function degrees_from_radians(radians) = 180 * radians / PI;


// INVOLUTE OF A CIRCLE
function involute_point(base_r=1, rolling_angle=0) =
    let (
        s=sin(rolling_angle), c=cos(rolling_angle),
        theta=radians_from_degrees(rolling_angle)
    )
    [ base_r*(c + theta*s), base_r*(s - theta*c) ];

function involute_points(base_r=1, rolling_angle0=0, rolling_angle1=360) =
    let(range = rolling_angle1 - rolling_angle0,
        facets = $fn > 0 ? $fn : 7,
        step = range / facets)
    [
        for (rolling_angle = [rolling_angle0:step:rolling_angle1])
            involute_point(base_r, rolling_angle)
    ];

// We need the parametric rolling angle at which an involute for a circle
// of `base_r` intersects a concentric circle of radius `r`.  This
// can be derived by plugging the involute equations for x and y
// into sqrt(x^2 + y^2) == r and solving for the rolling angle.
// Remember that this returns the rolling angle.  It does not indicate
// where it intersects the circle.
function intersect_involute_circle(base_r, r) =
    let (d = r/base_r, rolling_angle = sqrt(d*d - 1))
        degrees_from_radians(rolling_angle);

// MANIPULATING VECTORS OF POINTS
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

// TESTING IT OUT

helix_angle = 20;
pinion = AG_define_gear(tooth_count=11, helix_angle=-helix_angle, name="pinion");
G1 = AG_define_gear(tooth_count=23, iso_module=2, helix_angle=helix_angle, name="G1");
rack = AG_define_rack(2*AG_tooth_count(pinion), iso_module=2, helix_angle=helix_angle, name="rack");

bore_d = 6;
thickness = 8;

if ($preview) {
    AG_echo(pinion);
    AG_echo(G1);
    AG_echo(rack);
}

translate([0, -35, 0]) {
    color("white") AG_gear(pinion, thickness) {
        circle(d=bore_d, $fs=0.2);
    }

    translate([AG_center_distance(pinion, G1) + 4, 0, 0])
    color("yellow") AG_gear(G1, thickness) {
        circle(d=bore_d, $fs=0.2);
    }

    color("green") translate([-40, 0, 0]) {
        linear_extrude(2) circle(r=25.4);
        linear_extrude(4+thickness) {
            translate([-34/2, 0, 0]) circle(d=bore_d - 0.4, $fs=0.2);
            translate([ 34/2, 0, 0]) circle(d=bore_d - 0.4, $fs=0.2);
        }
    }
}

translate([-AG_tooth_count(rack)*2*PI/2, 0, 0]) {
    height_to_pitch = 2*AG_dedendum(rack);
    color("cyan") AG_rack(rack, thickness, height_to_pitch);

    if ($preview) {
        factor=2;
        distance = $t * factor*AG_circular_pitch(pinion)*AG_tooth_count(pinion);
        turn = $t * factor*-360;
        
        translate([distance, AG_center_distance(pinion, rack), 0])
        color("orange") rotate([0, 0, turn-90])
            AG_gear(pinion, thickness) { circle(r=1, $fs=0.2); }
    }
}
