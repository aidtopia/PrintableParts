// Storage Tray for Viltrox L166T LED video key light
// Adrian McCarthy 2023-04-10

module viltrox_l166t_storage_tray(l=193, w=130, h=30, r=5, frame_th=10, th=4, nozzle_d=0.4) {
    corner_size = 2*frame_th;

    module footprint() {
        hull() {
            dx = l/2 - r;
            dy = w/2 - r;
            translate([-dx, -dy]) circle(r=r);
            translate([-dx,  dy]) circle(r=r);
            translate([ dx, -dy]) circle(r=r);
            translate([ dx,  dy]) circle(r=r);
        }
    }

    module bottom() {
        linear_extrude(th, convexity=10) {
            difference($fs=nozzle_d/2) {
                offset(r=th) footprint();
                offset(r=-frame_th) footprint();
            }
        }
    }

    module walls() {
        linear_extrude(h+0.1, convexity=10) {
            difference($fs=nozzle_d/2) {
                offset(r=th) footprint();
                offset(r=nozzle_d/2) footprint();
            }
        }
    }
    
    module lip() {
        for (i = [1:9]) {
            translate([0, 0, i*th/10]) {
                linear_extrude(th/10, convexity=10) {
                    difference($fs=nozzle_d/2) {
                        offset(r=th+i*th/10) footprint();
                        offset(r=nozzle_d/2) footprint();
                    }
                }
            }
        }
        translate([0, 0, th]) {
            linear_extrude(th+0.1, convexity=10) {
                difference($fs=nozzle_d/2) {
                    offset(r=2*th) footprint();
                    offset(r=th+nozzle_d/2) footprint();
                }
            }
        }
    }
    
    module cutaway() {
        rotate([90, 0, 0])
        linear_extrude(w+4*th + 1, convexity=10, center=true) {
            dx = (l-2*corner_size)/2;
            hull($fs=nozzle_d/2) {
                translate([0, h]) square([2*dx, 0.2], center=true);
                translate([-(dx-r), r]) circle(r=r);
                translate([ (dx-r), r]) circle(r=r);
            }
            scale([1.2, 0.8]) circle(r=frame_th);
        }

        rotate([90, 0, 90])
        linear_extrude(l+4*th + 1, convexity=10, center=true) {
            dx = (w-2*corner_size)/2;
            hull($fs=nozzle_d/2) {
                translate([0, h]) square([2*dx, 0.2], center=true);
                translate([-(dx-r), r]) circle(r=r);
                translate([ (dx-r), r]) circle(r=r);
            }
        }

    }
    
    bottom();
    translate([0, 0, th-0.1]) {
        difference() {
            union() {
                walls();
                translate([0, 0, h-th]) lip();
            }
            translate([0, 0, frame_th]) cutaway();
        }
    }
}

viltrox_l166t_storage_tray();
