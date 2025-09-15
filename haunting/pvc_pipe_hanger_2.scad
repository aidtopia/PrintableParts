// 3/4" PVC hangers

nozzle_d = 0.4;
min_th = 3*nozzle_d;
wall_th = 3;

pipe_od = 27;

$fs = nozzle_d/2;
$fa = 4;

linear_extrude(8, convexity=6) {
    difference() {
        union() {
            offset(wall_th) circle(d=pipe_od);
            hull() {
                rotate([0, 0, 225]) translate([(pipe_od+wall_th)/2, 0]) circle(d=wall_th);
                rotate([0, 0, 180]) translate([(pipe_od+wall_th)/2, 0]) circle(d=wall_th);
                translate([-10, -(pipe_od/2+10)]) circle(d=wall_th);
                translate([- 8, -(pipe_od/2+10)]) circle(d=wall_th);
            }
            translate([0, -pipe_od/2]) {
                hull() {
                    translate([-10, -10]) circle(d=wall_th);
                    translate([ 10, -10]) circle(d=wall_th);
                }
                hull() {
                    translate([ 10, -10]) circle(d=wall_th);
                    translate([ 13, -7]) offset(-min_th) circle(d=wall_th);
                }
            }
        }
        offset(-wall_th) offset(wall_th) circle(d=pipe_od);
    }

}

