// Demonstrations of the capabilities of aidgear.scad
// Adrian McCarthy 2022-06-05

use <aidgear.scad>

helix_angle = 0;
pinion = AG_define_gear(tooth_count=11, helix_angle=-helix_angle, name="pinion");
G1 = AG_define_gear(tooth_count=22, iso_module=2, helix_angle=helix_angle, name="G1");
rack = AG_define_rack(2*AG_tooth_count(pinion), iso_module=2, helix_angle=helix_angle, name="rack");
ring = AG_define_ring_gear(24, pressure_angle=20, iso_module=3, helix_angle=helix_angle);
inner = AG_define_gear(16, pressure_angle=20, iso_module=3, helix_angle=helix_angle);

bore_d = 6;
thickness = 8;

if (true) {
    translate([0, 100, 0]) AG_animate(pinion, rack);
    translate([-80, 0, 0]) AG_animate(pinion, G1);
    translate([ 40, 0, 0]) AG_animate(G1, pinion);
    translate([ 10, -100, 0]) AG_animate(inner, ring);
} else {

if ($preview) {
    AG_echo(pinion);
    AG_echo(G1);
    AG_echo(rack);
    AG_echo(ring);
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

translate([125, 0, 0]) {
    color("gold") AG_gear(ring, thickness, herringbone=false);
    
    if ($preview) {
        // For the animation to loop properly, we need to figure out how
        // many trips around the ring gear the inner gear must make until
        // it returns to its original rotation.
        z1 = AG_tooth_count(ring);
        z2 = AG_tooth_count(inner);
        laps = lcm(z1, z2) / z1;

        rotate([0, 0, $t*360*laps])
        color("blue") translate([AG_center_distance(ring, inner), 0, 0])
            rotate([0, 0, -$t*360*laps*z1/z2])
                AG_gear(inner, thickness, herringbone=false) {
                    circle(d=bore_d, $fs=0.2);
                }
    } else {
        AG_gear(inner, thickness, herringbone=true);
    }
}

}
