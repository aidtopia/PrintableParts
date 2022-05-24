// Cap for whip cream dispenser
// Adrian McCarthy 2022-05-19

use <aidutil.scad>

// This module was used to make features at various sizes to help
// design the cap to fit well.  It's not used to create the actual
// cap.
module measure(nozzle_d=0.4) {
    linear_extrude(1)
        difference() {
            square([120, 60]);
            for (i = [0:6])
                let (d=16 + nozzle_d, r=d/2)
                    translate([r + 16.8*i + 1, 20/2])
                        polygon(rounded_polygon(
                            [for (theta = [72:72:360])
                                [r*cos(theta), r*sin(theta), 1.2+i*0.2]
                            ], $fs=0.2));

            translate([0, 20])
                for (i = [0:6])
                    let (d=15.5 + i*0.1 + nozzle_d)
                        translate([d/2 + 16.8*i + 1, 20/2])
                            circle(d=d, $fs=0.2);
        }
    translate([0, 40])
        for (i = [0:6])
            let (d=9.6 + i*0.2)
                translate([d/2 + 16.8*i + 1, 20/2])
                    cylinder(h=12, d=d, $fs=0.2);
}

// The dispenser nozzle has five "teeth" around the opening,
// with "slots" between them.

function slot_profile(w1=4.3, w2=3.4, h=7, clearance=0) = [
    [-(w1+clearance)/2, 0],
    [-(w2+clearance)/2, h-clearance],
    [(w2+clearance)/2, h-clearance],
    [(w1+clearance)/2, 0]
];

module slot_filler(w1=4.3, w2=3.4, h=7, th=2, clearance=0) {
    rotate([90, 0, 90])
        linear_extrude(th)
            polygon(slot_profile(w1, w2, h, clearance));
}

module tip_plug(nozzle_d=0.4) {
    // These inner bits conform to the opening of the
    // dispenser nozzle.
    cylinder(h=8, d=9.8, $fs=nozzle_d/2);
    for (theta = [36:72:360]) {
        rotate([0, 0, theta]) translate([4, 0, 0])
            slot_filler(th=3, clearance=-nozzle_d);
    }
}

module full_coverage_cap(nozzle_d=0.4) {
    cylinder(h=4, d=25, $fn=5);
    translate([0, 0, 4-nozzle_d/2]) {
        difference () {
            // Outer shape
            hull () {
                cylinder(h=1, d=20, $fn=5);
                translate([0, 0, 36])
                    cylinder(h=1, d=20, $fs=nozzle_d/2);
            }
            // Inner opening
            hull () {
                cylinder(h=1, d=14.8+nozzle_d, $fn=5);
                translate([0, 0, 37])
                    cylinder(h=1, d=16.0+nozzle_d, $fs=nozzle_d/2);
            }
            // Spy holes to see when cap is fully seated
            for (theta = [72:72:360])
                rotate([0, 0, theta])
                    translate([8, 0, 4])
                        rotate([0, 90, 0])
                            cylinder(h=4, d=3.5, center=true, $fs=nozzle_d/2);
        }
        tip_plug(nozzle_d);
    }
}

module minimal_cap(nozzle_d=0.4) {
    cylinder(h=4, d=24, $fn=5);
    translate([0, 0, 4-nozzle_d/2]) tip_plug(nozzle_d);
}

//measure();
full_coverage_cap();
translate([25, 0, 0]) minimal_cap();
