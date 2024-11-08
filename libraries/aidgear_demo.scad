// Demonstrations of the capabilities of aidgear.scad
// Adrian McCarthy 2022-06-05

// For spur gears, set to 0. A non-zero angle makes the pinion a helical gear. Positive for right handed, negative for left. (degrees)
Helix_Angle=0; // [-90:90]

// When checked, this makes helical gears into double-helix ones.
Herringbone=false;

// The thickness of the gears. (mm)
Thickness=8; // [1:40]

// Diameter of hole to be drilled through the center of the gears. (mm)
Bore_Diameter=6; // [0:12]

module __End_of_Customizer() {}

use <aidgear.scad>

module demo(helix_angle=0, herringbone=false, th=8, bore_d=6) {

    module animate(pinion, gear) {
        AG_animate(pinion, gear) circle(d=bore_d, $fs=0.2);
    }

    pinion =
        AG_define_gear(tooth_count=11,
                       thickness=th,
                       helix_angle=helix_angle,
                       herringbone=herringbone,
                       name="pinion");
    G1 =
        AG_define_gear(tooth_count=22,
                       helix_angle=-helix_angle,
                       mate=pinion,
                       name="G1");

    rack =
        AG_define_rack(2*AG_tooth_count(pinion),
                       helix_angle=-helix_angle,
                       mate=pinion,
                       name="rack");
    ring =
        AG_define_ring_gear(24, iso_module=3,
                            pressure_angle=20,
                            backlash_angle=1,
                            thickness=th,
                            helix_angle=helix_angle,
                            herringbone=herringbone,
                            name="internal gear",
                            depop=[2:8:24]);
    inner =
        AG_define_gear(16, depop=[2:8:16],
                       mate=ring, name="inner gear");

    translate([0, 100, 0]) animate(pinion, rack);
    translate([-80, 0, 0]) animate(pinion, G1);
    translate([ 40, 0, 0]) animate(G1, pinion);
    translate([ 10, -100, 0]) animate(inner, ring);

    translate([100, -100, 0])
        AG_compound_gear(G1, pinion) {
            circle(d=bore_d, $fs=0.2);
        }

    if ($preview && $t == 0) {
        AG_echo(pinion);
        AG_echo(G1);
        AG_echo(rack);
        AG_echo(inner);
        AG_echo(ring);
    }
}

function define_gear_train(pinion, tooth_counts=[], pos=0, rot=0) =
    assert(AG_type(pinion) == "AG gear")
    let (
        z = len(tooth_counts) == 0 ? 0 : tooth_counts[0],
        next = z == 0 ? [] : AG_define_gear(z, mate=pinion),
        rest = len(tooth_counts) <= 1 ? [] :
            [ for (i=[1:len(tooth_counts)-1]) tooth_counts[i] ],
        move = next == [] ? 0 : AG_center_distance(pinion, next),
        turn = (z%2 == 1) ? 0 : (pos > 0) ? -1 : 1
    )
    next == [] ?
           [ [ pinion, pos, rot ] ] :
           [ [ pinion, pos, rot ],
             each define_gear_train(next, rest, pos+move, rot+turn) ];

module draw_gear_train(train, bore_d=6, baseplate=false, nozzle_d=0.4) {
    module footprint(x0, x1, max_d) {
        hull() {
            translate([x0, 0, 0]) circle(d=max_d);
            translate([x1, 0, 0]) circle(d=max_d);
        }
    }

    first = train[0];
    last = train[len(train)-1];
    pad = $preview ? 0 : 2*AG_addendum(first[0]);

    translate([0, 0, baseplate && $preview ? 1.2 : 0])
        for (i = [0:len(train)-1]) {
            let (g = train[i], z = AG_tooth_count(g[0]))
            translate([g[1] + i*pad, 0, 0]) rotate([0, 0, g[2]*180/z])
                AG_cylindrical_gear(g[0]) { circle(d=bore_d, $fs=0.2); }
        }

    if (baseplate) {
        max_d  = max([ for (t=train) let(g=t[0]) AG_outer_diameter(g) ]);
        max_th = max([ for (t=train) let(g=t[0]) AG_thickness(g) ]);
        x0 = first[1] + (max_d - AG_outer_diameter(first[0]))/2;
        x1 = last[1]  - (AG_outer_diameter(last[0] ) - max_d)/2;
        band_w = max(6, bore_d);
        color("coral") translate([0, $preview ? 0 : max_d + band_w, 0]) {
            linear_extrude(1.2, convexity=10) {
                difference() {
                    offset(delta= band_w/2) { footprint(x0, x1, max_d); }
                    offset(delta=-band_w/2) { footprint(x0, x1, max_d); }
                }
                translate([first[1] - AG_outer_diameter(first[0])/2, -band_w, 0])
                    square([x1 - x0 + max_d, 2*band_w]);
            }
            linear_extrude(1.2 + max_th + 1.2) {
                for (t = train)
                    translate([t[1], 0, 0]) circle(d=bore_d-nozzle_d/2, $fs=nozzle_d/2);
            }
        }
    }
}

if (false) {
    pinion =
        AG_define_gear(11, helix_angle=Helix_Angle,
                       herringbone=Herringbone, thickness=Thickness,
                       name="pinion");
    train = define_gear_train(pinion, [22, 33, 44]);
    draw_gear_train(train, bore_d=Bore_Diameter, baseplate=true);
} else {
    demo(helix_angle=Helix_Angle, herringbone=Herringbone,
         th=Thickness, bore_d=Bore_Diameter);
}
