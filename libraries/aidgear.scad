// My own implementations of gears for OpenSCAD.
// Adrian McCarthy 2022-05-21

// Useful references I found about gear nomenclature, calculations, and
// involute tooth shapes:
// * https://ciechanow.ski/gears/
// * https://khkgears.net/new/gear_knowledge/gear_technical_reference/
// * https://drivetrainhub.com/notebooks/gears/geometry/Chapter%203%20-%20Helical%20Gears.html
// and a few pages on Wikipedia (of course).

// For bevel gears with straight teeth:
// * https://ijme.us/cd_11/PDF/Paper%20163%20ENG%20107.pdf

// GEAR DEFINITIONS

// OpenSCAD doesn't have user-defined types, but we're going to use a
// vector as an aggregate data type to hold the parameters that define
// the tooth pattern of a gear.  These accessor functions show the
// mapping from index to field.  Always use the accessor functions for
// compatibility with future versions. 

function AG_type(g)             = assert(len(g) > 0) g[0];
function AG_name(g)             = assert(len(g) > 1) g[1];
function AG_tooth_count(g)      = assert(len(g) > 2) g[2];
function AG_module(g)           = assert(len(g) > 3) g[3];
function AG_pressure_angle(g)   = assert(len(g) > 4) g[4];
function AG_backlash_angle(g)   = assert(len(g) > 5) g[5];
function AG_clearance(g)        = assert(len(g) > 6) g[6];
function AG_thickness(g)        = assert(len(g) > 7) g[7];
function AG_helix_angle(g)      = (len(g) > 8) ? g[8] : 0;
function AG_herringbone(g)      = (len(g) > 9) ? g[9] : false;
function AG_backing(g)          = (len(g) > 10) ? g[10] : 0;

// Higher indexes are reserved for future use
//
// Here's a default gear.  We don't use AG_define_universal because
// the default gear serves as the default template for the gear
// definition APIs.
AG_default_gear =
    ["AG gear", "default gear", 15, 2, 28, 0, 0.25, 1, 0, false, 0];


// Instead of creating additional gear definitions by hand, we provide
// `AG_define_...` functions to define the desired gear.

// For most external cylindrical gears, like spur gears and helical gears.
// Any parameter left unspecified will be set to be compatible with
// the mate.
function AG_define_gear(
    tooth_count=undef,
    iso_module=undef, circular_pitch=undef, diametral_pitch=undef,
    pressure_angle=undef,
    backlash_angle=undef,
    clearance=undef,
    thickness=undef,
    helix_angle=undef,
    herringbone=undef,
    name="spur gear",
    mate=AG_default_gear
) =
    let (
        m = AG_as_module(iso_module, circular_pitch, diametral_pitch,
                         AG_module(mate)),
        backing = 0
    )
    AG_define_universal("AG gear", name, tooth_count, m,
                        pressure_angle, backlash_angle, clearance,
                        thickness, helix_angle, herringbone,
                        backing, mate);

// For internal gears.
function AG_define_ring_gear(
    tooth_count=undef,
    iso_module=undef, circular_pitch=undef, diametral_pitch=undef,
    pressure_angle=undef,
    backlash_angle=undef,
    clearance=undef,
    thickness=undef,
    helix_angle=undef,
    herringbone=undef,
    pitch_to_rim=undef,
    name="ring gear",
    mate=AG_default_gear
) =
    let (
        m = AG_as_module(iso_module, circular_pitch, diametral_pitch,
                         AG_module(mate)),
        backing =
            is_undef(pitch_to_rim) ?
                AG_backing(mate) == 0 ?
                    2*m :
                    AG_backing(mate) :
                pitch_to_rim,
        addendum = m
    )
    assert(backing == 0 || backing >= addendum,
           str("AG: pitch to rim should be 0 or at least as large ",
               "as the addendum of ", addendum, " mm."))
    AG_define_universal("AG ring", name, tooth_count, m,
                        pressure_angle, backlash_angle, clearance,
                        thickness, helix_angle, herringbone,
                        backing, mate);

// For linear gear rack.
function AG_define_rack(
    tooth_count=undef,
    iso_module=undef, circular_pitch=undef, diametral_pitch=undef,
    pressure_angle=undef,
    backlash_angle=undef,
    clearance=undef,
    thickness=undef,
    helix_angle=undef,
    herringbone=undef,
    height_to_pitch=undef,
    name="rack",
    mate=AG_default_gear
) =
    let (
        m = AG_as_module(iso_module, circular_pitch, diametral_pitch,
                         AG_module(mate)),
        c = is_undef(clearance) ? AG_clearance(mate) : clearance,
        backing =
            is_undef(height_to_pitch) ?
                AG_backing(mate) == 0 ?
                    (2 + c)*m :
                    AG_backing(mate) :
                height_to_pitch,
        dedendum = (1 + c)*m
    )
    assert(backing == 0 || backing >= dedendum,
           str("AG: height to pitch should be 0 or at least as large ",
               "as the dedendum of ", dedendum, " mm."))
    AG_define_universal("AG rack", name, tooth_count, m,
                        pressure_angle, backlash_angle, c,
                        thickness, helix_angle, herringbone,
                        backing, mate);

// For internal use.
function AG_define_universal(
    type,
    name,
    tooth_count,
    iso_module,
    pressure_angle,
    backlash_angle,
    clearance,
    thickness,
    helix_angle,
    herringbone,
    backing,
    mate
) =
    let (m = iso_module,
         z = is_undef(tooth_count) ? AG_tooth_count(mate) : tooth_count,
         alpha =
            is_undef(pressure_angle) ? AG_pressure_angle(mate) :
                                       pressure_angle,
         backlash =
            is_undef(backlash_angle) ? AG_backlash_angle(mate) :
                                       backlash_angle,
         c = is_undef(clearance) ? AG_clearance(mate) : clearance,
         th = is_undef(thickness) ? AG_thickness(mate) : thickness,
         beta =
            is_undef(helix_angle) ?
                let (flip = (type == "AG ring") == (AG_type(mate) == "AG ring") ? -1 : 1)
                flip * AG_helix_angle(mate) : helix_angle,
         dblhelix =
            is_undef(herringbone) ? AG_herringbone(mate) :
                                    herringbone
    )

    assert(z > 0,
           "AG: tooth count must be positive")
    assert(z == floor(z),
           "AG: tooth_count must be an integer")
    assert(m > 0,
           "AG: module size must be positive")
    assert(0 < alpha && alpha < 45,
           "AG: pressure angle must be 0-45°")
    assert(0 <= backlash && backlash < 360/z,
           "AG: backlash angle should be small and positive")
    assert(c >= 0,
           "AG: clearance cannot be negative")
    assert(th >= 0, "AG: thickness cannot be negative")
    assert(-90 < beta && beta < 90,
           "AG: absolute value of the helix angle shold be less than 90°")
    assert(!dblhelix || beta != 0,
           "AG: herringbone gears require a non-zero helix angle")
    assert(0 <= backing,
           "AG: the backing cannot be negative")

//    let (minimum_teeth = floor(2 / pow(sin(pressure_angle), 2)))
//    assert(tooth_count >= minimum_teeth,
//           str("AG: ", minimum_teeth, " is the minimum number of ",
//               "teeth to avoid undercuts given a pressure angle of ",
//               pressure_angle, "°"))

    [ type, name, z, m, alpha, backlash, c, th, beta, dblhelix,
      backing ];

// Internally, we use ISO module.  This function converts various ways of
// representing the tooth size to ISO module.
function AG_as_module(
    iso_module=undef,
    circular_pitch=undef,
    diametral_pitch=undef,
    default=undef
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
             "tooth size:\n",
             "  module:\t", AG_module(g), " mm\n",
             "  circular pitch:\t", AG_circular_pitch(g),
                " mm tooth-to-tooth\n",
             "  diametral pitch:\t", AG_diametral_pitch(g)," teeth/inch\n",
             "pressure angle:\t", AG_pressure_angle(g), " degrees\n",
             "backlash angle:\t", AG_backlash_angle(g), " degrees\n",
             "clearance:\t", AG_clearance(g), "\n",
             "thickness:\t", AG_thickness(g), " mm\n",
             "helix angle:\t", AG_helix_angle(g), " degrees",
                 AG_herringbone(g) ? " (herringbone)\n" : "\n",
             "backing:\t\t", AG_backing(g), " mm\n",
             "pitch diameter:\t", AG_pitch_diameter(g), " mm\n"));
}

function AG_circular_pitch(g)   = PI * AG_module(g);

function AG_diametral_pitch(g)  = 25.4 / AG_module(g);

function AG_pitch_diameter(g)   =
    (AG_type(g) == "AG rack") ? 0 : AG_module(g) * AG_tooth_count(g);

function AG_base_diameter(g)    = AG_pitch_diameter(g) * cos(AG_pressure_angle(g));

function AG_tips_diameter(g)    =
    let (s = AG_type(g) == "AG ring" ? -2 : 2)
        AG_pitch_diameter(g) + s*AG_addendum(g);

function AG_root_diameter(g)    =
    let (s = AG_type(g) == "AG ring" ? 2 : -2)
        AG_pitch_diameter(g) + s*AG_dedendum(g);

function AG_addendum(g)         = 1.00 * AG_module(g);

function AG_dedendum(g)         = (1.00 + AG_clearance(g)) * AG_module(g);

function AG_outer_diameter(g)   =
    let (t = AG_type(g))
    t == "AG gear" ? AG_tips_diameter(g) :
    t == "AG ring" ? AG_pitch_diameter(g) + 2*AG_backing(g) :
    undef;

// Returns true if the two gears can mesh.
function AG_compatible(g1, g2) =
    let (
        t1 = AG_type(g1), t2 = AG_type(g2),
        beta1 = AG_helix_angle(g1), beta2 = AG_helix_angle(g2),
        helix1 = t1 == "AG ring" ? -beta1 : beta1,
        helix2 = t2 == "AG ring" ? -beta2 : beta2
    )
    AG_module(g1) == AG_module(g2) &&
    AG_pressure_angle(g1) == AG_pressure_angle(g2) &&
    helix1 == -helix2 &&
    (helix1 == 0 || AG_herringbone(g1) == AG_herringbone(g2));

// The center distance is the spacing required between the centers of two
// gears to have them mesh properly.
function AG_center_distance(g1, g2) =
    assert(AG_compatible(g1, g2),
           "AG: cannot compute the center distance for incompatible gears")
    let (
        d1 = (AG_type(g1) == "AG ring" ? -1 : 1) * AG_pitch_diameter(g1),
        d2 = (AG_type(g2) == "AG ring" ? -1 : 1) * AG_pitch_diameter(g2)
    )
    abs(d1 + d2) / 2;

// Returns a list of points forming a 2D-polygon of the gear teeth.
function AG_tooth_profile(g, first_tooth=undef, last_tooth=undef) =
    let (type = AG_type(g))
    type == "AG gear" ? AG_spur_tooth_profile(g, first_tooth=first_tooth, last_tooth=last_tooth) :
    type == "AG rack" ? AG_rack_tooth_profile(g) :
    type == "AG ring" ? AG_spur_tooth_profile(g, first_tooth=first_tooth, last_tooth=last_tooth) :
    assert(false, str("AG: '", type, "' is not a recognized gear type"))
    [];

function AG_spur_tooth_profile(g, first_tooth=undef, last_tooth=undef) =
    assert(AG_type(g) == "AG gear" || AG_type(g) == "AG ring")
    let (
        // The pitch circle, sometimes called the reference circle, is
        // the size of the equivalent toothless disc if we were using
        // toothless discs instead of gears.  It's the circle at which
        // the pitch is measured.
        pitch_r = AG_pitch_diameter(g)/2,

        // The base circle is the point where the involute part of the
        // the tooth profile begins.
        base_r = AG_base_diameter(g)/2,

        // The addendum is how far beyond the pitch circle the tips of
        // the teeth extend.
        tips_r = AG_tips_diameter(g)/2,

        // The dedendum is the radial distance from the pitch circle to
        // the bottoms of the teeth.  This "gum line" is called the
        // root circle.
        root_r = AG_root_diameter(g)/2,
        
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
        start_r = max(min(tips_r, root_r), base_r),
        stop_r  = max(root_r, tips_r),

        // Points on the involute are generated by a parametric angle.
        // In order to generate the section of the involute we need,
        // we'll need to know the rolling angles for the involute at the
        // base circle (where the involute part of the tooth shape begins)
        // and the addendum circle (where the teeth tips lie).
        rolling0 = intersect_involute_circle(base_r, start_r),
        rolling1 = intersect_involute_circle(base_r, stop_r),

        // So here's the piece of the involute we need.
        inv_path = involute_points(base_r, rolling0, rolling1),
        
        // Connect the root circle to the involute (in the normal case).
        edge1 =
            (root_r < start_r) ?
                [[root_r, 0], each inv_path] : inv_path,

        edge2 = flipped_points(edge1),
        
        dtheta = 360 / tooth_count,
        
        first = is_undef(first_tooth) ? 1 : first_tooth,
        last  = is_undef(last_tooth)  ? tooth_count : last_tooth,
        
        teeth = [ for (i = [1:tooth_count])
            let (
                theta = (i-1) * dtheta,
                theta1 = theta - tooth_angle/2,
                theta2 = theta + tooth_angle/2,
                tooth_path = (first <= i && i <= last) ?
                    [
                        each rotated_points(edge1, theta1),
                        each rotated_points(edge2, theta2)
                    ] :
                    [
                        [ root_r*cos(theta), root_r*sin(theta) ]
                    ]
            )
            each tooth_path
        ],

        backing = AG_backing(g),
        rim = backing == 0 ? [] :
            [ teeth[0],
              each [
                let (
                    rim_r = pitch_r + backing,
                    step_a = ($fa > 0) ? ($fa/360) : 1,
                    step_s = ($fs > 0) ? $fs / (2*PI*rim_r) : 1,
                    step = ($fn > 0) ? 1/$fn : min(step_a, step_s),
                    bias = atan2(teeth[0].y, teeth[0].x)
                )
                for (i = [0:step:360])
                   [ rim_r * cos(i+bias), rim_r * sin(i+bias) ]
              ]
            ]

        // TODO fillet at root circle
        // TODO tip relief
        // TODO crowning of tooth surface?
    )

    assert(root_r > 0)

    [ each rim, each teeth ];

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
        w = CP * tooth_count,
        height_to_pitch = AG_backing(g),
        foundation = -height_to_pitch
    )
    
    [
        [0, foundation],
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
        [w, root_y],
        [w, foundation]
    ];

function AG_rack_width(rack) =
     assert(AG_type(rack) == "AG rack")
     AG_circular_pitch(rack) * AG_tooth_count(rack);

// This is the shear required for a helical rack.
function AG_helix_shear(g) = tan(AG_helix_angle(g));

// This is the amount of twist (in degrees) to apply for a helical gear
// at the given thickness.
function AG_helix_twist(g, th=1) =
    let (circumference = PI * AG_pitch_diameter(g))
        th * 360 * AG_helix_shear(g) / circumference;

module AG_gear(gear, convexity=10, center=false, first_tooth=undef, last_tooth=undef) {
    if (AG_type(gear) == "AG rack") {
        AG_rack(gear, convexity=convexity, center=center);
    } else {
        AG_cylindrical_gear(gear, convexity=convexity,
                            center=center,
                            first_tooth=first_tooth,
                            last_tooth=last_tooth) {
            children();
        }
    }
}

// Creates geometry for cylindrical spur, helical, and ring (internal) gears.
module AG_cylindrical_gear(gear, convexity=10, center=false, first_tooth=undef, last_tooth=undef) {
    assert(AG_type(gear) != "AG rack",
           str("AG: to create geometry for the rack \"", AG_name(gear),
               "\", use `AG_rack` instead of `AG_gear`."));
    th = AG_thickness(gear);
    herringbone = AG_herringbone(gear);
    w = herringbone ? th/2 : th;
    twist = AG_helix_twist(gear, w);
    profile =
        AG_tooth_profile(gear, first_tooth=first_tooth,
                         last_tooth=last_tooth);
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

        // Mark tooth one
        m = AG_module(gear);
        nudge = AG_type(gear) == "AG ring" ? m : 0;
        x = AG_root_diameter(gear)/2 + nudge;
        translate([x, 0, 0])
            linear_extrude(min(1, w), center=true, convexity=convexity)
                square(m, center=true);
        rotate([0, 0, herringbone ? 0 : -twist])
            translate([x, 0, th])
                linear_extrude(min(1, w), center=true, convexity=convexity)
                    square(m, center=true);

        translate([0, 0, -1])
            linear_extrude(th+2, convexity=convexity)
                children();
    }
}

module AG_rack(rack, convexity=10, center=false) {
    assert(AG_type(rack) == "AG rack");
    th = AG_thickness(rack);
    herringbone = AG_herringbone(rack);
    w = herringbone ? th/2 : th;
    shear = AG_helix_shear(rack);
    profile = AG_rack_tooth_profile(rack);
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

module AG_compound_gear(g1, g2, colors=["gold", "cornflowerblue"],
                        convexity=10, center=false) {
    th1 = AG_thickness(g1);
    th2 = AG_thickness(g2);
    total_th = th1 + th2;
    drop = center ? total_th/2 : 0;

    translate([0, 0, -drop]) difference() {
        union() {
            color(colors[0])
                AG_gear(g1, convexity=convexity);
            color(colors[1]) translate([0, 0, th1])
                AG_gear(g2, convexity=convexity);
        }

        translate([0, 0, -1])
        linear_extrude(total_th+2, convexity=convexity) {
            children();
        }
    }
}

// Instantiates two gears and animates them as though the pinion
// is driving the gear.
module AG_animate(pinion, gear, colors=["gold", "cornflowerblue"]) {
    assert(AG_type(pinion) != "AG rack",
           "AG: the pinion in an animation must be a cylindrical gear");

    pinion_teeth = AG_tooth_count(pinion);
    gear_teeth   = AG_tooth_count(gear);
    tooth_ratio  = pinion_teeth / gear_teeth;
    laps = min(3, lcm(pinion_teeth, gear_teeth) / pinion_teeth);

    cd = AG_center_distance(pinion, gear);
    is_rack = AG_type(gear) == "AG rack";
    is_ring = AG_type(gear) == "AG ring";
    mesh_vec =
        is_rack ? [0, -cd, 0] :
        is_ring ? [-cd, 0, 0] :
                  [cd, 0, 0];
    mesh_rot =
        is_rack ? -90 :
        is_ring ? gear_teeth % 2 == 1 ? 180/pinion_teeth : 0 :
                  gear_teeth % 2 == 0 ? 180/pinion_teeth : 0;

    pinion_rot = $t <= 0.5 ? -360*laps*2*$t : -360*laps*(1 - 2*($t-0.5));
    gear_rot =
        is_rack ? 0 :
        is_ring ? pinion_rot * tooth_ratio :
                 -pinion_rot * tooth_ratio;
    gear_vec =
        is_rack ? [pinion_rot/360 * PI * AG_pitch_diameter(pinion), 0, 0] :
                  [0, 0, 0];
                      
    color(colors[0]) rotate([0, 0, mesh_rot]) rotate([0, 0, pinion_rot])
        AG_gear(pinion) { children(); }
    color(colors[1]) translate(mesh_vec) translate(gear_vec)
        rotate([0, 0, gear_rot])
            AG_gear(gear) { children(); }
}


function radians_from_degrees(degrees) = PI * degrees / 180;
function degrees_from_radians(radians) = 180 * radians / PI;

function gcd(a, b) =
  b > a ? gcd(b, a) : b == 0 ? a : gcd(b, a%b);

function lcm(x, y) = x*y / gcd(x, y);

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
// Remember that this returns the rolling angle.  the rolling angle does
// does _not_ indicate where the involute intersects the circle.
function intersect_involute_circle(base_r, r) =
    let (d = r/base_r, rolling_angle = sqrt(d*d - 1))
        degrees_from_radians(rolling_angle);

// MANIPULATING VECTORS OF POINTS
function rotated_point(pt, angle) =
    let (s=sin(angle), c=cos(angle))
        [ pt.x*c - pt.y*s, pt.x*s + pt.y*c ];

function rotated_points(points, angle) =
    [ for (pt = points) rotated_point(pt, angle) ];

function flipped_point(pt) = [ pt.x, -pt.y ];
function flipped_points(points) =
    [ for (i = [len(points):-1:1]) flipped_point(points[i-1]) ];

echo("\n***\nLoad aidgear_demo.scad to see what aidgear.scad can do.\n***\n");
