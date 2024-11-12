// PVC pipe connectors for Tinker Toy-like construction.

use <aidslant.scad>

function inch(inches) = 25.4 * inches;

// 3/4-inch (trade size) schedule 40 PVC pipe
pvc_od = 26.7;

module clip_negative_z() {
    difference() {
        children();
        translate([0, 0, -1000]) {
            linear_extrude(1000, convexity=8) {
                square(1000, center=true);
            }
        }
    }
}

module PVC_corner(od, l=inch(2), wall_th=3, nozzle_d=0.4) {
    module sleeve(l) {
        translate([0, 0, -(pvc_od+2*(wall_th+nozzle_d))/2])
        linear_extrude(l+od, convexity=6) {
            difference() {
                $fa=3;
                offset(wall_th+nozzle_d) square(pvc_od, center=true);
                offset(nozzle_d) circle(d=pvc_od);
            }
        }
    }
    
    clip_negative_z()
    slant3d()
    translate([0, 0, (pvc_od+2*wall_th+nozzle_d)/2]) {
        sleeve(l);
        rotate([0, 90, 0]) sleeve(l);
        rotate([-90, 0, 0]) sleeve(l);
        //cube(pvc_od+2*wall_th+nozzle_d, center=true);
    }
}

PVC_corner(pvc_od);

