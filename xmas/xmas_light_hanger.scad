// A tool for hanging Christmas lights.
// Attach this to the end of a 1/2" PVC pipe.

function inch(x) = 25.4 * x;

pipe_id = inch(0.602);
pipe_od = inch(0.840);

nozzle_d = 0.4;

$fs = nozzle_d/2;
$fa = 4;

wall_th = 1.8;
plug_h = 12 + wall_th;
plug_od = pipe_od + 2*wall_th;
base_h = 5;
fork_offset = 15;

translate([0, 0, -plug_h]) {
    linear_extrude(plug_h) {
        difference() {
            circle(d=plug_od);
            circle(d=pipe_od + nozzle_d/2);
        }
        circle(d = pipe_id);
    }
}
translate([0, 0, -wall_th]) {
    linear_extrude(wall_th) {
        circle(d=plug_od);
    }
}

intersection() {
    translate([0, 0, -wall_th]) linear_extrude(100) circle(d=plug_od);
    translate([0, pipe_id/2, fork_offset]) {
        rotate([80, 0, 0]) {
            difference() {
                rotate([0, -90, 0]) {
                    linear_extrude(25, center=true, convexity=8) {
                        hull() {
                            translate([-1, 10]) circle(d=3);
                            circle(d=5);
                            translate([1, -15]) circle(d=7);
                        }
                        hull() {
                            circle(d=5);
                            translate([7, 6]) circle(d=3);
                        }
                    }
                }
                rotate([-30, 0, 0]) {
                    linear_extrude(30, center=true, convexity=8) {
                        hull() {
                            translate([0, -5]) circle(d=5);
                            translate([0, 12]) circle(d=10);
                        }
                    }
                }
            }
        }
    }
}
