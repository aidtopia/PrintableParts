// 3/4" PVC hangers
// Good for hanging a Stupidly Simply Spider Dropper.

module PVC_hanger(pipe_od = 27, nozzle_d=0.4) {
    min_th = 3*nozzle_d;
    wall_th = 3;

    $fs = nozzle_d/2;
    $fa = 4;

    linear_extrude(6, convexity=6) {
        difference() {
            union() {
                offset(wall_th) circle(d=pipe_od);
                hull() {
                    rotate([0, 0, 225]) translate([(pipe_od+wall_th)/2, 0]) {
                        circle(d=wall_th);
                    }
                    rotate([0, 0, 180]) translate([(pipe_od+wall_th)/2, 0]) {
                        circle(d=wall_th);
                    }
                    translate([- 8, -(pipe_od/2+14)]) circle(d=wall_th);
                    translate([- 6, -(pipe_od/2+14)]) circle(d=wall_th);
                }
                translate([0, -pipe_od/2]) {
                    hull() {
                        translate([-8, -14]) circle(d=wall_th);
                        translate([ 8, -14]) circle(d=wall_th);
                    }
                    hull() {
                        translate([ 8, -14]) circle(d=wall_th);
                        translate([12,  -6]) offset(-min_th) circle(d=wall_th);
                    }
                }
            }
            offset(-wall_th) offset(wall_th) circle(d=pipe_od+nozzle_d);
        }
    }
}

for (row=[0:1]) {
    for (col=[0:1]) {
        translate([35*col, 50*row]) PVC_hanger();
    }
}

