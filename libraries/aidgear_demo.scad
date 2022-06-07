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
        AG_animate(pinion, gear, th=th, herringbone=herringbone) {
            circle(d=bore_d, $fs=0.2);
        }
    }

    pinion =
        AG_define_gear(tooth_count=11, helix_angle=helix_angle,
                       name="pinion");
    G1 =
        AG_define_gear(tooth_count=22, iso_module=2,
                       helix_angle=-helix_angle, name="G1");
    rack =
        AG_define_rack(2*AG_tooth_count(pinion), iso_module=2,
                       helix_angle=-helix_angle, name="rack");
    ring =
        AG_define_ring_gear(24, pressure_angle=20, iso_module=3,
                            helix_angle=helix_angle);
    inner =
        AG_define_gear(16, pressure_angle=20, iso_module=3,
                       helix_angle=helix_angle);

    translate([0, 100, 0]) animate(pinion, rack);
    translate([-80, 0, 0]) animate(pinion, G1);
    translate([ 40, 0, 0]) animate(G1, pinion);
    translate([ 10, -100, 0]) animate(inner, ring);

    if ($preview && $t == 0) {
        AG_echo(pinion);
        AG_echo(G1);
        AG_echo(rack);
        AG_echo(ring);
    }
}

demo(helix_angle=Helix_Angle, herringbone=Herringbone,
     bore_d=Bore_Diameter, th=Thickness);
